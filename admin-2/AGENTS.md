---
metadata:
  version: "2.0.0"
---

# Agents

This project uses [Agent Skills](https://agentskills.io). Skills are installed under `.agents/skills/`.

## Start here

Read `.agents/skills/vantage-ui-builder/SKILL.md` first. It explains the project layout
(`datasource/`, `table/`, `page/`, `menu/`, `action/`, `view/`), the YAML conventions, and the
**MCP feedback loop**: Vantage runs an HTTP MCP server at `http://127.0.0.1:14488/mcp` with tools
to read logs (`list_logs`), inspect data (`list_models`, `run_data_script`), and see what rendered
(`ui_tree`) — so you verify every change yourself instead of asking the user.

For backend-specific guidance, read the matching `vantage-persistence-<kind>/SKILL.md`. For
project-wide settings (theme, app variables), read `vantage-application-settings/SKILL.md`. When a
dashboard or summary page needs grouped, computed, or filtered rows, read
`vantage-aggregate-views/SKILL.md`. When a page is slow to open, re-fetches, or you want to
confirm one is efficient before shipping it, read `vantage-table-debugging/SKILL.md` — it measures
requests, re-fetches, and blocking work with `--page=` plus the `perf_stats` MCP tool.

## Working principles

- **Assume a non-technical user** unless they speak in technical terms. Ask a few basic
  questions, then build a working prototype and iterate on what they say after seeing it.
- **No planning ceremony.** A Vantage app is a handful of small YAML files that hot-reload on
  save. No specs, no plan documents, no task lists, no sub-agents — edit, verify, keep going.
- **When the user is unsure, decide for them:** SQLite in the project folder, a structure you
  design, sample data auto-seeded for new tables. Ask before changing existing tables or data.
- **Show progress fast.** Datasource first, then one table at a time: backend table → table
  YAML → page → menu entry → verify. The menu entry lands with the page, every time.
- **Verify via MCP, never via the user.** `list_logs` after every save; `run_data_script` to
  check a query; `ui_tree` to see what rendered. Fix WARN/ERROR before moving on.
- **Decorate later.** Build all core pages first; refine column order, widths, and colours in a
  pass once the user is looking at real screens. Then a dashboard, then interactivity.
- **Summarise in 2–3 plain sentences** — what the user can now see and click, and what you
  suggest next. No YAML, no jargon.
