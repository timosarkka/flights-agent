"""
Slack bot that relays messages to a Snowflake Cortex Agent.

Runs in Socket Mode, so it needs no public URL: it opens an outbound
WebSocket to Slack. Start it with `python app.py`.

Responds to @-mentions in channels and to direct messages. Replies land in
a thread; follow-up questions in that same thread keep their context.
Charts render inline in the answer message rather than as a follow-up post.
"""

import os
import re
import json
import time
import logging
from collections import OrderedDict

import vl_convert as vlc
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

import agent

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("cortex-slack")

app = App(token=os.environ["SLACK_BOT_TOKEN"])

# --- conversation state -----------------------------------------------------
# thread_ts -> list of API messages. In memory only: restarting the bot
# forgets every thread. Move to Snowflake threads (thread_id /
# parent_message_id) when you want this to survive a redeploy.

MAX_THREADS = 200          # evict the least recently used beyond this
MAX_TURNS = 12             # messages kept per thread before trimming
CONVERSATIONS = OrderedDict()

# Slack limits: 3000 chars per section text, 50 blocks per message.
SECTION_LIMIT = 2900
MAX_TABLE_ROWS = 10


def get_history(thread_ts):
    if thread_ts in CONVERSATIONS:
        CONVERSATIONS.move_to_end(thread_ts)
    else:
        CONVERSATIONS[thread_ts] = []
        while len(CONVERSATIONS) > MAX_THREADS:
            CONVERSATIONS.popitem(last=False)
    return CONVERSATIONS[thread_ts]


def trim_history(history):
    """Keep the tail of the conversation so requests don't grow without bound."""
    if len(history) > MAX_TURNS:
        del history[: len(history) - MAX_TURNS]


# --- formatting -------------------------------------------------------------

def to_mrkdwn(text):
    """Convert standard markdown to Slack's mrkdwn dialect."""
    # [label](url) -> <url|label>
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r"<\2|\1>", text)
    # ### Heading -> *Heading*
    text = re.sub(r"^#{1,6}\s*(.+)$", r"*\1*", text, flags=re.MULTILINE)
    # **bold** -> *bold*   (before the single-asterisk case)
    text = re.sub(r"\*\*(.+?)\*\*", r"*\1*", text, flags=re.DOTALL)
    return text


def chunk(text, size=SECTION_LIMIT):
    """Split long text on newlines so each piece fits in one section block."""
    pieces = []
    while text:
        if len(text) <= size:
            pieces.append(text)
            break
        cut = text.rfind("\n", 0, size)
        if cut < size // 2:
            cut = size
        pieces.append(text[:cut])
        text = text[cut:].lstrip("\n")
    return pieces


def render_table(result_set, max_rows=MAX_TABLE_ROWS):
    """Render a SQL result set as a fixed-width text table."""
    meta = result_set.get("resultSetMetaData", {})
    cols = [c.get("name", "?") for c in meta.get("rowType", [])]
    if not cols:
        return None

    all_rows = result_set.get("data", []) or []
    rows = [["" if v is None else str(v) for v in row] for row in all_rows[:max_rows]]

    widths = []
    for i, col in enumerate(cols):
        cell_widths = [len(row[i]) for row in rows if i < len(row)]
        widths.append(max([len(col)] + cell_widths))

    def line(values):
        return " | ".join(
            str(v).ljust(widths[i]) for i, v in enumerate(values) if i < len(widths)
        )

    out = [line(cols), "-+-".join("-" * w for w in widths)]
    out += [line(r) for r in rows]

    total = meta.get("numRows", len(all_rows))
    if total > len(rows):
        out.append(f"... {total - len(rows)} more rows")

    body = "\n".join(out)
    if len(body) > SECTION_LIMIT - 20:
        body = body[: SECTION_LIMIT - 30] + "\n... truncated"
    return f"```\n{body}\n```"


def build_blocks(answer, sql, table, chart_file_ids=()):
    blocks = []

    for piece in chunk(to_mrkdwn(answer) or "_No answer returned._"):
        blocks.append({"type": "section", "text": {"type": "mrkdwn", "text": piece}})

    # An image block backed by an unshared Slack file. Provide either `id`
    # or `url` in slack_file, never both -- Slack rejects the payload.
    for file_id in chart_file_ids:
        blocks.append({
            "type": "image",
            "slack_file": {"id": file_id},
            "alt_text": "Chart generated from the query results",
        })

    if table:
        rendered = render_table(table)
        if rendered:
            blocks.append(
                {"type": "section", "text": {"type": "mrkdwn", "text": rendered}}
            )

    if sql:
        snippet = sql if len(sql) < 2800 else sql[:2800] + "\n-- truncated"
        blocks.append({
            "type": "context",
            "elements": [{"type": "mrkdwn", "text": f"```sql\n{snippet}\n```"}],
        })

    return blocks[:50]


# --- charts -----------------------------------------------------------------

def chart_png(spec):
    """Rasterize a Vega-Lite spec to PNG bytes.

    The agent sends chart specs, not images. vl-convert-python ships a
    self-contained binary, so this needs no Node or headless browser.
    In a container, install fonts (e.g. fonts-dejavu-core) or text renders blank.
    """
    return vlc.vegalite_to_png(vl_spec=spec, scale=2)


def upload_chart_files(client, specs):
    """Render specs and upload them unshared. Returns Slack file IDs.

    Passing no `channel` means the file is uploaded but not posted, so it
    creates no message of its own -- the image block does the displaying.
    """
    file_ids = []
    for i, spec in enumerate(specs):
        try:
            res = client.files_upload_v2(
                file=chart_png(spec),
                filename=f"chart_{i + 1}.png",
                title="Chart",
            )
            files = res.get("files") or [res.get("file")]
            if files and files[0]:
                file_ids.append(files[0]["id"])
        except Exception:
            # One bad spec shouldn't cost the user the answer they already got.
            logger.exception("chart %s failed to render or upload", i + 1)
            try:
                preview = json.dumps(json.loads(spec))[:300]
            except (ValueError, TypeError):
                preview = str(spec)[:300]
            logger.debug("offending spec: %s", preview)
    return file_ids


# --- core handler -----------------------------------------------------------

def respond(client, channel, thread_ts, question):
    if not question:
        client.chat_postMessage(
            channel=channel,
            thread_ts=thread_ts,
            text="Ask me a question about the data and I'll look it up.",
        )
        return

    placeholder = client.chat_postMessage(
        channel=channel, thread_ts=thread_ts, text="_Working on it..._"
    )

    history = get_history(thread_ts)
    history.append(agent.user_msg(question))

    answer, sql, table, file_ids = "", None, None, []
    try:
        payload = agent.ask(history)
        history.append({"role": "assistant", "content": payload.get("content", [])})
        trim_history(history)

        answer, sql, table, charts = agent.extract(payload)
        file_ids = upload_chart_files(client, charts) if charts else []
        blocks = build_blocks(answer, sql, table, file_ids)
        fallback = answer[:200] or "Answer from Snowflake"

    except Exception as exc:
        logger.exception("agent call failed")
        history.pop()  # don't poison the thread with a failed turn
        blocks, fallback, file_ids = None, f":warning: {exc}", []

    try:
        client.chat_update(
            channel=channel, ts=placeholder["ts"], text=fallback, blocks=blocks
        )
    except Exception as exc:
        # Slack can reject a freshly uploaded file with invalid_blocks if it
        # hasn't finished processing. Retry once, then drop the inline image
        # and post the text alone rather than losing the answer entirely.
        if file_ids and "invalid_blocks" in str(exc):
            logger.warning("inline charts rejected, retrying in 2s")
            time.sleep(2)
            try:
                client.chat_update(
                    channel=channel, ts=placeholder["ts"],
                    text=fallback, blocks=blocks,
                )
            except Exception:
                logger.exception("retry failed, posting text only")
                client.chat_update(
                    channel=channel, ts=placeholder["ts"], text=fallback,
                    blocks=build_blocks(answer, sql, table),
                )
        else:
            raise


# --- events -----------------------------------------------------------------
# Bolt acks the event before the listener finishes and runs listeners in a
# worker thread, so a slow agent call won't trigger Slack retries. The
# placeholder message exists purely so the user sees something immediately.

@app.event("app_mention")
def on_mention(event, client):
    question = re.sub(r"<@[A-Z0-9]+>", "", event.get("text", "")).strip()
    thread_ts = event.get("thread_ts") or event["ts"]
    respond(client, event["channel"], thread_ts, question)


@app.event("message")
def on_message(event, client):
    # Direct messages only. Channel messages arrive here too, but those are
    # handled by on_mention so the bot doesn't answer every passing comment.
    if event.get("channel_type") != "im":
        return
    # Ignore our own posts, other bots, edits and deletions.
    if event.get("bot_id") or event.get("subtype"):
        return

    thread_ts = event.get("thread_ts") or event["ts"]
    respond(client, event["channel"], thread_ts, event.get("text", "").strip())


if __name__ == "__main__":
    logger.info("connecting to Slack (socket mode)...")
    SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"]).start()