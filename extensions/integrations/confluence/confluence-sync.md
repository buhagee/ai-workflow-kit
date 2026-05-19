# Confluence Sync Rules

These rules are active only when the user opted in to Confluence integration.

All Confluence page references (page IDs, URLs) MUST be stored in
`aidlc-docs/integrations/confluence-refs.md` immediately after creation.

---

## Rule CONF-01: Requirements Page

**Trigger:** Requirements Analysis stage approved by user.

**Action:**
1. Create a Confluence page in the configured space titled
   `[Project Name] — Requirements`
2. Content: publish `aidlc-docs/inception/requirements/requirements.md` as the
   page body, converting markdown to Confluence storage format
3. If a parent page was specified in opt-in, create under that parent
4. Store the page URL in `aidlc-docs/integrations/confluence-refs.md`:
   ```markdown
   # Confluence References
   **Requirements:** https://your-domain.atlassian.net/wiki/...
   ```
5. Announce: "Published requirements to Confluence"

**Skip if:** User chose design-only mode (option B in opt-in).

---

## Rule CONF-02: User Stories Page

**Trigger:** User Stories stage approved by user.

**Action:**
1. Create a Confluence page titled `[Project Name] — User Stories`
2. Content: publish `aidlc-docs/inception/user-stories/stories.md` and
   `aidlc-docs/inception/user-stories/personas.md` combined
3. Create as a child of the Requirements page if it exists
4. Store the page URL in `aidlc-docs/integrations/confluence-refs.md`

**Skip if:** User chose design-only mode (option B in opt-in).

---

## Rule CONF-03: Application Design Page

**Trigger:** Application Design stage approved by user.

**Action:**
1. Create a Confluence page titled `[Project Name] — Application Design`
2. Content: publish all artifacts from
   `aidlc-docs/inception/application-design/` — components, component-methods,
   services, component-dependency
3. Render any Mermaid diagrams as images if the Confluence instance supports it;
   otherwise include them as code blocks
4. Store the page URL in `aidlc-docs/integrations/confluence-refs.md`

---

## Rule CONF-04: Per-Unit Design Pages

**Trigger:** Each unit's design stages (Functional Design, NFR Design,
Infrastructure Design) approved by user.

**Action:**
1. Create a Confluence page titled `[Unit Name] — Technical Design`
2. Content: publish all design artifacts for the unit from
   `aidlc-docs/construction/[unit-name]/`
3. Create as a child of the Application Design page
4. Update `aidlc-docs/integrations/confluence-refs.md` with the page URL

---

## Rule CONF-05: Build and Test Summary Page

**Trigger:** Build and Test stage approved by user.

**Action:**
1. Create a Confluence page titled `[Project Name] — Build & Test Summary`
2. Content: publish `aidlc-docs/construction/build-and-test/build-and-test-summary.md`
3. Include test results, coverage, and any known issues
4. Store the page URL in `aidlc-docs/integrations/confluence-refs.md`
5. If Jira integration is also active, add a link to the Confluence page in
   the Jira Epic description

---

## Rule CONF-06: Page Updates vs. Creation

When a Confluence page for a given artifact already exists (URL stored in
`confluence-refs.md`), UPDATE the existing page rather than creating a new one.
This prevents duplicate pages when re-running or resuming a workflow.
