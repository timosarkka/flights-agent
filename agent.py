"""
Thin client for the Snowflake Cortex Agents Run API.

Calls POST /api/v2/databases/{db}/schemas/{schema}/agents/{name}:run with
stream=false, so the whole answer comes back as one JSON object instead of
a server-sent event stream.

Run it directly to test the endpoint without Slack in the way:

    python agent.py "how many flights were delayed last month?"
"""

import os
import sys
import json
import logging

import requests
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

ACCOUNT_URL = os.environ["SNOWFLAKE_ACCOUNT_URL"].rstrip("/")
AGENT_DATABASE = os.environ["AGENT_DATABASE"]
AGENT_SCHEMA = os.environ["AGENT_SCHEMA"]
AGENT_NAME = os.environ["AGENT_NAME"]
SNOWFLAKE_PAT = os.environ["SNOWFLAKE_PAT"]

# Path segments are case sensitive. If you created the objects without
# double quotes, Snowflake stored them uppercased -- match that here.
AGENT_URL = (
    f"{ACCOUNT_URL}/api/v2/databases/{AGENT_DATABASE}"
    f"/schemas/{AGENT_SCHEMA}"
    f"/agents/{AGENT_NAME}:run"
)

HEADERS = {
    "Authorization": f"Bearer {SNOWFLAKE_PAT}",
    "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
    "Content-Type": "application/json",
    "Accept": "application/json",
}

# Non-background runs time out server-side at 15 minutes; keep the client
# timeout under that so a hung socket doesn't wedge a worker thread forever.
REQUEST_TIMEOUT = 300


class AgentError(RuntimeError):
    """Raised when the agent returns an error payload or a non-2xx status."""


def user_msg(text):
    """Wrap a plain string in the message shape the API expects."""
    return {"role": "user", "content": [{"type": "text", "text": text}]}


def ask(messages):
    """Send the conversation and return the assistant response object.

    `messages` is the full history, oldest first: user and assistant turns
    interleaved. The agent is stateless per request, so whatever context you
    want it to have must be in this list.
    """
    body = {"messages": messages, "stream": False}

    response = requests.post(
        AGENT_URL, headers=HEADERS, json=body, timeout=REQUEST_TIMEOUT
    )

    if response.status_code >= 400:
        # The error body is far more useful than the status code alone --
        # it names the missing grant, the bad identifier, or the blocked IP.
        detail = response.text[:1000]
        try:
            parsed = response.json()
            detail = parsed.get("message") or detail
        except ValueError:
            pass
        raise AgentError(f"HTTP {response.status_code}: {detail}")

    payload = response.json()

    # A 200 can still carry a fatal error for the run itself.
    if payload.get("status") == "error" or "error" in payload:
        err = payload.get("error") or {}
        raise AgentError(err.get("message", "Agent run failed"))

    return payload


def extract(payload):
    """Split the heterogeneous content array into the parts Slack can show.

    Returns (answer_text, sql, table_result_set, chart_specs).

    Content items arrive mixed together: thinking, tool_use, tool_result,
    table, chart, text. Only some of them are worth surfacing.
    """
    answer_parts = []
    sql = None
    table = None
    charts = []

    for item in payload.get("content", []):
        kind = item.get("type")

        if kind == "text":
            text = item.get("text", "")
            if text:
                answer_parts.append(text)

        elif kind == "tool_use":
            # The generated SQL shows up as input to the execute-sql tool.
            candidate = item.get("tool_use", {}).get("input", {}).get("sql")
            if candidate and not sql:
                sql = candidate

        elif kind == "table":
            result_set = item.get("table", {}).get("result_set")
            if result_set:
                table = result_set

        elif kind == "chart":
            # A serialized Vega-Lite spec, not an image.
            spec = item.get("chart", {}).get("chart_spec")
            if spec:
                charts.append(spec)

    return "\n\n".join(answer_parts).strip(), sql, table, charts


def _main():
    question = " ".join(sys.argv[1:]) or "What data do you have access to?"
    print(f"Endpoint: {AGENT_URL}\n")
    print(f"Q: {question}\n")

    payload = ask([user_msg(question)])
    answer, sql, table, charts = extract(payload)

    print("=" * 60)
    print(answer or "(no text content returned)")
    print("=" * 60)

    if sql:
        print(f"\nSQL:\n{sql}")
    if table:
        rows = table.get("resultSetMetaData", {}).get("numRows")
        print(f"\nTable returned: {rows} rows")
    if charts:
        print(f"\nChart specs returned: {len(charts)}")
        print(json.dumps(json.loads(charts[0]), indent=2)[:400])


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    _main()