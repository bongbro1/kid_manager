# Roadmap: Kid Manager

## Overview

This roadmap treats the current repository as a brownfield family-safety product that already has broad feature coverage but needs stronger runtime reliability and clearer execution boundaries. The first milestone focuses on stabilizing bootstrap, identity, tracking, and alert routing before polishing the secondary family-management surfaces that already exist.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions if a live issue forces mid-stream work

- [ ] **Phase 1: Runtime Foundation** - Stabilize bootstrap, lifecycle ownership, and the minimum regression harness
- [ ] **Phase 2: Identity and Family Access** - Harden auth, role boundaries, and family profile consistency
- [ ] **Phase 3: Tracking and Safety Flows** - Make tracking, zones, safe routes, and SOS trustworthy
- [ ] **Phase 4: Notifications and Family Operations** - Unify notification behavior and polish the broader family-management product surface

## Phase Details

### Phase 1: Runtime Foundation
**Goal**: Parent, guardian, and child sessions boot into the right shell, background tracking ownership is predictable, and critical runtime flows have repeatable regression coverage
**Depends on**: Nothing (first phase)
**Requirements**: [CORE-01, CORE-02, CORE-03]
**Success Criteria** (what must be TRUE):
  1. Parent, guardian, and child users enter the correct app shell after cold start and logout/login transitions
  2. Only one tracking publisher owns child location updates at a time across foreground/background transitions
  3. Developers can run targeted automated checks for session bootstrap, tracking policy, and notification-routing hotspots
**UI hint**: no
**Plans**: 3 plans

Plans:
- [ ] 01-01: Normalize app bootstrap, provider ownership, and session lifecycle boundaries
- [ ] 01-02: Stabilize background tracking runtime handoff across Flutter and Android services
- [ ] 01-03: Repair and extend the local regression harness for runtime-critical flows

### Phase 2: Identity and Family Access
**Goal**: Authentication, profile state, and family/guardian permissions behave consistently across client and backend boundaries
**Depends on**: Phase 1
**Requirements**: [AUTH-01, AUTH-02, FAM-01, FAM-02, FAM-03]
**Success Criteria** (what must be TRUE):
  1. Users can authenticate, restore sessions, and log out without leaving stale listeners or background work behind
  2. Parent and guardian permissions resolve consistently for assigned children and family ownership
  3. Profile locale/timezone/state stay aligned between Firebase auth, Firestore data, and device runtime
**UI hint**: yes
**Plans**: 3 plans

Plans:
- [ ] 02-01: Harden auth/session flows and cleanup behavior
- [ ] 02-02: Tighten family membership, guardian assignment, and backend access checks
- [ ] 02-03: Reconcile profile, locale, and timezone ownership across app/runtime layers

### Phase 3: Tracking and Safety Flows
**Goal**: Tracking, zones, safe routes, and SOS deliver trustworthy caregiver-facing safety context
**Depends on**: Phase 2
**Requirements**: [TRACK-01, TRACK-02, TRACK-03, SAFE-01, SAFE-02]
**Success Criteria** (what must be TRUE):
  1. Parents can see reliable live and historical child location with sane status and heartbeat behavior
  2. Zones and safe routes reflect the right child and caregiver permissions
  3. SOS alerts open the correct actionable context for caregivers without duplicate routing
**UI hint**: yes
**Plans**: 3 plans

Plans:
- [ ] 03-01: Harden tracking data publish/consume paths and map state synchronization
- [ ] 03-02: Verify and refine zones plus safe-route access and monitoring behavior
- [ ] 03-03: Consolidate SOS alert delivery, tap routing, and resolution behavior

### Phase 4: Notifications and Family Operations
**Goal**: Notification behavior is unified and the broader family-management surfaces feel coherent on top of the stabilized safety foundation
**Depends on**: Phase 3
**Requirements**: [NOTF-01, NOTF-02, OPS-01, OPS-02, OPS-03]
**Success Criteria** (what must be TRUE):
  1. Push and in-app notifications render localized copy and open the correct destinations
  2. Chat, birthdays, memory-day reminders, and schedule flows honor family role boundaries
  3. Parent operations for schedules, app restrictions, and related settings behave consistently from the main app shell
**UI hint**: yes
**Plans**: 3 plans

Plans:
- [ ] 04-01: Unify notification rendering, routing, and cleanup logic
- [ ] 04-02: Polish family communication and reminder flows
- [ ] 04-03: Stabilize parent operations for schedules and child-management surfaces

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Runtime Foundation | 0/3 | Not started | - |
| 2. Identity and Family Access | 0/3 | Not started | - |
| 3. Tracking and Safety Flows | 0/3 | Not started | - |
| 4. Notifications and Family Operations | 0/3 | Not started | - |
