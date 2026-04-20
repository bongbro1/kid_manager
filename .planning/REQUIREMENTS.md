# Requirements: Kid Manager

**Defined:** 2026-04-20
**Core Value:** Families can trust the app to show the right child state, route safety events correctly, and surface urgent alerts without losing context.

## v1 Requirements

### Core Runtime

- [ ] **CORE-01**: Parent, guardian, and child users land in the correct app shell after cold start, session restore, and logout/login cycles
- [ ] **CORE-02**: Child tracking switches cleanly between foreground and background execution without duplicate publishers or stale status
- [ ] **CORE-03**: Core session, tracking, and notification paths are protected by automated checks that developers can run locally

### Authentication

- [ ] **AUTH-01**: User can sign up, log in, and reset password with email and password
- [ ] **AUTH-02**: Logging out clears session-scoped listeners, push bindings, and background work before returning to auth flow

### Family Access

- [ ] **FAM-01**: Parent can create and manage child or guardian accounts within one family
- [ ] **FAM-02**: Guardian can only view and manage children explicitly assigned to them
- [ ] **FAM-03**: Profile locale and timezone stay consistent between auth state, stored profile data, and device/runtime behavior

### Tracking

- [ ] **TRACK-01**: Parent can view a child's current location and recent history on map surfaces
- [ ] **TRACK-02**: Child device publishes current and historical location points with accuracy, throttling, and heartbeat rules
- [ ] **TRACK-03**: Parent can create, edit, and inspect zones and zone-status context for children

### Safety

- [ ] **SAFE-01**: Parent or assigned guardian can create and monitor safe routes for a child
- [ ] **SAFE-02**: Child can trigger SOS and caregivers receive actionable alerts that open the correct map or detail context

### Notifications

- [ ] **NOTF-01**: In-app and push notifications route to the correct screen with localized human-readable copy
- [ ] **NOTF-02**: Background alerts and cleanup jobs do not create duplicate or stale notification state

### Family Operations

- [ ] **OPS-01**: Parent can manage child schedules, imports/exports, and schedule history
- [ ] **OPS-02**: Family members can use chat, birthdays, and memory-day reminders without role leakage
- [ ] **OPS-03**: Parent can manage child app restrictions and related settings from the app shell

## v2 Requirements

### Platform Expansion

- **PLAT-01**: Desktop and web clients reach parity with the Android-focused mobile experience
- **PLAT-02**: Operational analytics and observability dashboards surface tracking/notification health

### Identity & Monetization

- **IDEN-01**: OAuth sign-in flows (Google/Facebook/Apple) are fully wired and production-ready
- **IDEN-02**: Subscription billing and entitlement self-service are automated end-to-end

## Out of Scope

| Feature | Reason |
|---------|--------|
| White-label / multi-tenant deployments | Not necessary for the current stabilization milestone |
| Wearables, car integrations, or external hardware tracking | Outside the current mobile/Firebase operational scope |
| Replacing Firebase or Mapbox | Too disruptive for the first planning milestone |
| School or enterprise administration portals | Current scope is family-first mobile supervision |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1 | Pending |
| CORE-02 | Phase 1 | Pending |
| CORE-03 | Phase 1 | Pending |
| AUTH-01 | Phase 2 | Pending |
| AUTH-02 | Phase 2 | Pending |
| FAM-01 | Phase 2 | Pending |
| FAM-02 | Phase 2 | Pending |
| FAM-03 | Phase 2 | Pending |
| TRACK-01 | Phase 3 | Pending |
| TRACK-02 | Phase 3 | Pending |
| TRACK-03 | Phase 3 | Pending |
| SAFE-01 | Phase 3 | Pending |
| SAFE-02 | Phase 3 | Pending |
| NOTF-01 | Phase 4 | Pending |
| NOTF-02 | Phase 4 | Pending |
| OPS-01 | Phase 4 | Pending |
| OPS-02 | Phase 4 | Pending |
| OPS-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-04-20*
*Last updated: 2026-04-20 after initial definition*
