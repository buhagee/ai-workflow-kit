# Jira Integration — Opt-In

This extension syncs AI-DLC workflow stages with Jira. When enabled, the agent
will automatically create and transition Jira issues as the workflow progresses.

**Requires:** `atlassian` MCP server configured (see `mcp-config.json` in this
directory).

---

## Question: Enable Jira Integration?

Would you like to sync this workflow with Jira?

A) Yes — full sync: create Epic, Stories, and sub-tasks; auto-transition tickets
   at each stage completion
B) Yes — Epic and Stories only; I will manage sub-tasks and transitions manually
C) Yes — read only: pull existing Jira context into requirements (no writes)
D) No — skip Jira integration for this workflow

[Answer]:

---

**If you chose A or B, also answer:**

## Question: Jira Project Key

What is the Jira project key to use? (e.g. `PROJ`, `MYAPP`)

[Answer]:

## Question: Epic naming

How should the Epic be named?

A) Use the project/feature name from Requirements Analysis automatically
B) I will provide the Epic name manually when prompted
C) Use the AIDLC session ID as the Epic name

[Answer]:
