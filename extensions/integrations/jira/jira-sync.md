# Jira Sync Rules

These rules are active only when the user opted in to Jira integration.

All Jira references (Epic key, Story keys, sub-task keys) MUST be stored in
`aidlc-docs/integrations/jira-refs.md` immediately after creation so they can
be referenced in later stages.

---

## Rule JIRA-01: Epic Creation

**Trigger:** Requirements Analysis stage approved by user.

**Action:**
1. Create a Jira Epic in the configured project using the feature/project name
   from the requirements document as the Epic summary
2. Set the Epic description to a concise summary of the requirements
3. Store the Epic key in `aidlc-docs/integrations/jira-refs.md`:
   ```markdown
   # Jira References
   **Epic:** [PROJ-123](https://your-domain.atlassian.net/browse/PROJ-123)
   ```
4. Announce: "Created Jira Epic [PROJ-123]"

**Skip if:** User chose read-only mode (option C in opt-in).

---

## Rule JIRA-02: Story Creation

**Trigger:** User Stories stage approved by user.

**Action:**
1. For each user story in `aidlc-docs/inception/user-stories/stories.md`,
   create one Jira Story linked to the Epic
2. Use the story title as the Jira summary
3. Use the acceptance criteria as the Jira description
4. Store all Story keys in `aidlc-docs/integrations/jira-refs.md` under a
   `## Stories` section, mapping story title → Jira key
5. Announce: "Created [N] Jira Stories under Epic [PROJ-123]"

**Skip if:** User chose Epic-only mode (option B in opt-in) or read-only.

---

## Rule JIRA-03: Sub-task Creation

**Trigger:** Units Generation stage approved by user.

**Action:**
1. For each unit of work in `aidlc-docs/inception/application-design/unit-of-work.md`,
   create one Jira sub-task under the relevant Story (or directly under the Epic
   if no story mapping exists)
2. Use the unit name as the sub-task summary
3. Store sub-task keys in `aidlc-docs/integrations/jira-refs.md` under a
   `## Sub-tasks` section
4. Announce: "Created [N] Jira sub-tasks"

**Skip if:** User chose Epic + Stories only (option B) or read-only.

---

## Rule JIRA-04: In-Progress Transition

**Trigger:** Code Generation begins for a unit.

**Action:**
1. Look up the Jira key for this unit in `aidlc-docs/integrations/jira-refs.md`
2. Transition the ticket to "In Progress"
3. If no key exists for this unit, log a warning but do not block the workflow

---

## Rule JIRA-05: In-Review Transition

**Trigger:** Code Generation for a unit is approved by user.

**Action:**
1. Look up the Jira key for this unit
2. Transition the ticket to "In Review" (or "Code Review" — use whichever
   status exists in the project)

---

## Rule JIRA-06: Done Transition

**Trigger:** Build and Test stage approved by user.

**Action:**
1. For each unit that passed build and test, transition its Jira ticket to "Done"
2. Add a comment to the Epic: "All units complete. Build and test passed."

---

## Rule JIRA-07: Read Context at Workflow Start

**Trigger:** Workflow start (always, even in read-only mode).

**Action:**
1. If `aidlc-docs/integrations/jira-refs.md` exists, load it and use the
   referenced tickets as context during Requirements Analysis
2. If the user provided a Jira Epic or ticket number at workflow start, fetch
   its description and acceptance criteria and include them in requirements context
3. This allows continuing work on an existing Jira ticket rather than starting fresh
