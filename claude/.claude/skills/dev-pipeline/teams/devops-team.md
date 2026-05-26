# DevOps Team

Handles documentation, deployment, and delivery.

## Team Members

| Role | Agent | Responsibility | Reports To |
|------|-------|----------------|------------|
| **API Doc Engineer** | API Docs | Maintains OpenAPI specs, syncs Postman | Backend Tech Lead |
| **Release Engineer** | Deployer | Builds, packages, verifies deployment readiness | User |

## Communication Flow

```
Backend Team (done)
       │
       ▼
 API Doc Engineer
       │
       ├─ syncs OpenAPI + Postman
       │
       ▼
 Release Engineer
       │
       ├─ builds, verifies, checks migrations
       │
       ▼
 READY TO DEPLOY → User
```

## Rules
- API Doc Engineer runs AFTER backend team completes (code must be stable)
- API Doc failures are warnings, not blockers
- Release Engineer verifies the FULL delivery (build + docker + migrations + config)
- Only the user can approve actual deployment to production
