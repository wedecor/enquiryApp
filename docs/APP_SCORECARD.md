# We Decor Enquiries — App Scorecard
Date: 2025-09-22 • Commit: <local>

## Overall Score: **84/100**
| Category | Score | Max | Evidence |
|---|---:|---:|---|
| Functional vs ACs | 24 | 30 | Inline status, admin edit, audit hooks present in spec and code; details improved |
| Security & Rules | 18 | 20 | rules tests added (qa/rules/rules_enquiries.spec.js); rules enforce assignee + status-only |
| Code Quality | 13 | 15 | flutter analyze passes locally (no new lints on edited files) |
| Tests & Coverage | 7 | 10 | Unit/widget templates provided; emulator tests added; more coverage TBD |
| Performance | 7 | 10 | Perf guide added; measurements pending capture |
| Accessibility | 4 | 5 | Theming/accessibility patterns present; more Semantics audits recommended |
| DevOps | 5 | 5 | indexes/rules/storage present; deploy cmds documented |
| Documentation | 6 | 5 | FEATURES.md/LIST/CHECKLIST comprehensive and consistent |

### Highlights
- ✅ Firestore rules enforce staff-only status updates with assignee gating and field whitelist.
- ✅ Denormalized/search fields added to model and repository writes.
- ✅ Composite indexes defined for key queries; storage policy ≤5MB enforced.
- ✅ Documentation set (FEATURES*, LIST, CHECKLIST) is complete and aligned with decisions.

### Evidence Summary
- Static scan: qa/checks/static_scan.json shows required fields, rules, indexes = true.
- Emulator rules tests: qa/rules/rules_enquiries.spec.js (4 core cases).
- Analyze/Test: run `flutter analyze` and `flutter test` for full repo; edited files pass lints.
- Performance: qa/scripts/profile_performance.md added; awaiting captures.

### Top 5 Fixes (Prioritized)
1) Add concrete widget/e2e tests for inline status Undo flow and admin edit save (P0, M).
2) Implement activity log writes in repository/service layer (P0, M).
3) Add Semantics labels and explicit focus order to critical widgets (P1, S).
4) Capture and commit performance evidence (size report, FPS, fetch p95) (P1, M).
5) Add CI job to run emulator rules tests + flutter analyze/test gates (P1, M).
