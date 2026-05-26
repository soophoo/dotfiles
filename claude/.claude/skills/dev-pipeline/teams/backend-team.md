# Backend Team

The core engineering team for the NSIA Assurances Spring Boot backend.

## Team Members

| Role | Agent | Responsibility | Reports To |
|------|-------|----------------|------------|
| **Tech Lead** | Architect | Analyzes, designs, makes technical decisions | User |
| **Senior Dev** | Java Developer | Implements features following the blueprint | Architect |
| **Code Reviewer** | Reviewer | Reviews code quality, security, architecture | Tech Lead |
| **QA Engineer** | QA | Writes and runs tests, validates quality | Tech Lead |

## Communication Flow

```
User → Tech Lead (Architect)
              │
              ├─ designs blueprint
              │
              ▼
        Senior Dev (Developer)
              │
              ├─ implements code
              │
              ▼
        Code Reviewer ──── if CHANGES REQUESTED ──→ Senior Dev (retry)
              │
              ├─ approved
              │
              ▼
        QA Engineer ──── if FAILED ──→ Senior Dev (fix) → Reviewer (re-review)
              │
              ├─ passed
              │
              ▼
        Tech Lead (final sign-off)
```

## Rules
- Tech Lead has final say on architecture decisions
- Senior Dev follows the blueprint strictly — deviations require Tech Lead approval
- Code Reviewer checks implementation against blueprint AND coding standards
- QA tests all scenarios identified in the blueprint
- Maximum 2 retry cycles for review/QA failures before escalating to user
