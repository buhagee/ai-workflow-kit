# Confluence Integration — Opt-In

This extension publishes AI-DLC workflow artifacts to Confluence. When enabled,
the agent will automatically create and update Confluence pages as the workflow
progresses.

**Requires:** `atlassian` MCP server configured (see `mcp-config.json` in this
directory).

---

## Question: Enable Confluence Integration?

Would you like to publish workflow artifacts to Confluence?

A) Yes — publish all artifacts: requirements, user stories, design docs,
   build/test summaries
B) Yes — publish design artifacts only (application design, functional design,
   infrastructure design)
C) Yes — publish requirements and user stories only
D) No — skip Confluence integration for this workflow

[Answer]:

---

**If you chose A, B, or C, also answer:**

## Question: Confluence Space Key

What is the Confluence space key to publish to? (e.g. `ENG`, `TEAM`, `PROJ`)

[Answer]:

## Question: Parent page

Should pages be created under a specific parent page?

A) Yes — create under a parent page (I will provide the page title or ID)
B) No — create at the space root level
C) Create a new parent page named after this project automatically

[Answer]:
