# Team Knowledge

Add reference material that AI-DLC agents should consult under this directory.
Use the v2 layout so the installer can copy it directly into the active space:

```text
extensions/knowledge/
├── aidlc-shared/                 # loaded by every agent
└── aidlc-architect-agent/        # loaded by one agent role
```

Use `extensions/org-standards/` for mandatory behavioral rules. Knowledge is
context and pattern guidance; it should not duplicate a non-negotiable rule.