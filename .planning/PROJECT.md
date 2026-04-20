# Kid Manager

## What This Is

Kid Manager is a Flutter family safety app for parents, guardians, and children. It combines live location tracking, safe routes, SOS alerts, family notifications, schedules, chat, and child-management tools on top of a Firebase backend and Android-native background services. This brownfield codebase already ships broad product surface area; the immediate need is to make the current product more reliable, more testable, and easier to evolve.

## Core Value

Families can trust the app to show the right child state, route safety events correctly, and surface urgent alerts without losing context.

## Requirements

### Validated

- ✓ Families can authenticate with role-aware parent/guardian/child behavior — existing
- ✓ Parents can view location/map-oriented child context and manage family data — existing
- ✓ Safety capabilities such as zones, safe routes, and SOS already exist in the codebase — existing
- ✓ Notifications, family chat, schedules, birthdays, and memory-day flows are already implemented — existing

### Active

- [ ] Stabilize runtime ownership around session bootstrap, tracking, and notification routing
- [ ] Improve trust in core family-safety flows by tightening access control, background behavior, and alert handling
- [ ] Increase delivery confidence with better planning artifacts, targeted automation, and clearer architecture boundaries

### Out of Scope

- Net-new white-label / multi-tenant productization — not required to stabilize the current app
- Hardware or wearable integrations — outside the current mobile/Firebase scope
- Major backend provider migration away from Firebase/Mapbox — too disruptive for the current hardening milestone

## Context

This repository is a brownfield Flutter app with a large existing product surface. The app uses Provider/ChangeNotifier for state, Firebase for auth/data/messaging/functions, Mapbox for map services, and Android-native background services for tracking and supervision. The codebase mixes older layer-based organization with newer feature slices such as `lib/features/safe_route/`, and current risks cluster around session bootstrap, background tracking ownership, notification cold starts, and stale automation scripts.

The repo already contains useful signals for current product intent:
- `lib/features/sessionguard/`, `lib/viewmodels/location/`, and `lib/services/notifications/` show the operational core of the app
- `functions/src/services/` and `functions/src/triggers/` hold enforcement and fan-out logic
- `README.md` and `audit_code/` contain prior audit notes that reinforce the same runtime hotspots

## Constraints

- **Tech stack**: Flutter + Firebase + Mapbox remain the current platform foundation — replacing them would expand scope dramatically
- **Compatibility**: Android is the most customized production path — background tracking changes must preserve Android-native service behavior
- **Security**: Parent/guardian/child role boundaries must stay aligned across client gating, backend access services, and Firebase rules
- **Performance**: Tracking and notification flows must avoid duplicate publishers, duplicate taps, and unnecessary Firebase churn
- **Planning approach**: This initialization assumes a brownfield hardening milestone first — the roadmap prioritizes stability before new feature expansion

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Initialize as a brownfield project, not a greenfield rewrite | The repo already contains substantial working product surface and backend logic | — Pending |
| Treat runtime reliability as the first milestone | Current technical risk is concentrated in bootstrap, tracking, and notifications | — Pending |
| Keep Firebase and Mapbox as fixed platform constraints for now | Stabilization is higher leverage than provider churn | — Pending |
| Use standard granularity with parallel plan execution enabled | The product surface is broad enough to benefit from phase decomposition without over-fragmenting it | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-20 after initialization*
