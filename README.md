# Flights Agent (Snowflake Semantic View, Cortex Agent and Slack)

A Snowflake Cortex Agent wired up to a Slack channel.

It replies to users questions about flights based on the [Flights ETL Pipeline](https://github.com/timosarkka/flights-elt) data I built earlier. It can query data and even draw charts on-demand.

![People waiting for the flights in the terminal](/assets/img/agents_800.jpg)

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture](#2-architecture)
3. [Slack and app.py](#3-slack-and-apppy)
4. [agent.py](#4-agentpy)
5. [Cortex Agent](#5-cortex-agent)
6. [Semantic View](#6-semantic-view)
7. [Marts](#7-marts)
8. [Example Prompts](#8-example-prompts)
9. [Project Structure](#9-project-structure)

## 1. Introduction

This project lets you ask questions about flight data in plain English from
Slack, and get back an answer in the same thread. It also gives the SQL behind the answer, the resulting data and any
charts the agent was requested to plot.

The data itself is a dimensional model of flight observations on Snowflake: flights,
aircraft, airlines, airports and dates as described in my earlier
[project](https://github.com/timosarkka/flights-elt).

You can ask questions like this:

![Total flight volume per day](/assets/img/flight_chart6_800.png)

## 2. Architecture

The main pieces of the architecture are:

**Slack.** The user asks a question in plain English. It can be an @-mention in a
channel or a direct message.

**Python.** `app.py` is the Slack side: it catches the event, tracks the
thread, and later turns the reply into Slack blocks, tables and chart images.
`agent.py` is the Snowflake side: a thin HTTP client that posts the
conversation to the Cortex Agents Run API and gets one JSON payload back.

**Snowflake.** The **Cortex Agent** interprets the question and writes SQL. It
can do that because the **semantic view** tells it what the data means: which
tables exist, how they join, what each column is called in business terms. The
SQL then runs against the **marts**, the actual dimensional model.

Results flow back the same way: rows to the agent, JSON to `agent.py`, a
formatted answer with charts to `app.py`, and a Slack message to the user.

Below you can see a sketch of the architecture diagram of this agent setup:

![Main architecture of the project](/assets/img/architecture_1024.png)

## 3. Slack and app.py

`app.py` is a Slack app built with Slack Bolt. It runs in Socket Mode, so it
doesn't need a public URL.

**What it listens to.** The bot answers when it is @-mentioned in a channel, or
when someone sends it a direct message. Other channel messages, its own posts,
other bots, edits and deletions are ignored.

**Threads keep the context.** Each Slack thread has its own chat history, so you
can ask follow-up questions in the same thread. The history is kept in memory
only: max 200 threads and 12 messages per thread. The oldest ones are dropped
first. If the app restarts, all history is lost.

**Quick first reply.** The bot first posts _Working on it..._ right away. When
the agent answers, the same message is updated with the real answer. This way
Slack doesn't think the bot is stuck, even if the agent takes a while.

**Formatting.** Slack uses its own version of markdown, so `app.py` converts
links, headings and bold text to it. Long answers are split into smaller parts,
because Slack allows max 3000 characters per block. Result tables show max 10
rows, and the SQL is shown at the bottom of the message.

**Charts.** The agent doesn't send images. It sends a chart spec (Vega-Lite
JSON), and `app.py` turns it into a PNG with the `vl-convert` library. The PNG
is uploaded to Slack and shown inside the answer.

## 4. agent.py

`agent.py` is a very simple client for the Snowflake Cortex Agents REST API. It
has a URL, a set of headers and two main functions.

`ask(messages)` sends the whole conversation to the agent and returns the
response as one JSON object.

`extract(payload)` picks out the four things Slack can show from the response:

| Content type | Used as                                     |
| ------------ | ------------------------------------------- |
| `text`       | the answer                                  |
| `tool_use`   | the SQL the agent wrote                     |
| `table`      | the query results                           |
| `chart`      | a Vega-Lite chart spec (JSON, not an image) |

## 5. Cortex Agent

The Cortex Agent is created and configured in Snowflake. It gets the question
from `agent.py`, figures out what data is needed, writes the SQL and runs it.
It then writes the answer and, if asked, a chart spec.

It's pretty neat, since you can define instructions, tools, skills and even MCP
connections to the agent. You could also run evals and monitor observability.

I defined the daily_flight_report skill to make it easier to produce a coherent report
when asked for a daily overview.

Here's how part of the Cortex Agent config looks on Snowflake:

![Cortex Agent configs](/assets/gif/cortex_agent.gif)

## 6. Semantic View

The semantic view is defined in `dbt/models/semantic_views/sv_flights.sql` and
built with dbt's `semantic_view` materialization. It has five parts:

**Tables.** The tables used from the marts layer. One fact table and four
dimensions:

| Table          | One row is                                          |
| -------------- | --------------------------------------------------- |
| `FCT_FLIGHT`   | one observed flight                                 |
| `DIM_AIRCRAFT` | one aircraft (registration, model, operator, owner) |
| `DIM_AIRLINE`  | one airline (ICAO/IATA codes, country, active flag) |
| `DIM_AIRPORT`  | one airport (type, location, scheduled service)     |
| `DIM_DATE`     | one calendar date                                   |

**Relationships.** Six joins from the fact table to the dimensions. These tell
the agent how to join the tables.

**Facts and dimensions.** Each column is either a fact or a dimension. This
part also has column descriptions and synonyms, which help the agent find the
right columns based on the user's question.

**Custom instructions.** General instructions that don't fit anywhere else.

**Verified queries.** Example questions with the correct SQL for each. They show
the agent what a good query looks like for a certain type of question.

You can also view the semantic view settings directly in Snowflake:

![Semantic view in Snowflake](/assets/img/semantic_view_800.png)

## 7. Marts

The marts are the actual data. They are built in my separate
[Flights ELT Pipeline](https://github.com/timosarkka/flights-elt) project, so
this repo only reads from them. The `dbt/` folder here contains only the
semantic view.

## 8. Example Prompts

So let's ask the agent some questions!

First, maybe we want to know the daily flight volumes:

![Total flight volume per day](/assets/img/flight_chart4_800.png)

Next, we might want to know something about the airline distribution on a certain airport:

![Total flight volume per day](/assets/img/flight_chart5_800.png)

And last, let's get a comprehensive report of everything that has happened today:

![Total flight volume per day](/assets/gif/daily_flight_report.gif)

All in all, it's pretty exciting. We're actually talking to our data in Slack and getting some real insights and knowledge back!

## 9. Project Structure

```
flight-agent/
├── agent.py                Cortex Agents API client, also works as a test CLI
├── app.py                  Slack bot: events, formatting, charts
├── requirements.txt        slack-bolt, requests, python-dotenv, vl-convert-python
├── .env                    credentials (gitignored)
├── assets/img/             images for this README
└── dbt/
    └── models/
        └── semantic_views/
            └── sv_flights.sql    the SV_FLIGHTS semantic view
```
