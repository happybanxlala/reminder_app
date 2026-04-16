# Day 6 Core Model Implementation Plan

## Scope and source boundary

- Primary source: `docs/core/04_core_model_spec_v1.md`
- Single canonical source: `docs/core/04_core_model_spec_v1.md`
- `docs/core/03_timeline_milestone_rule.md` is not present in this repo; implementation will not use `docs/archive/03_timeline_milestone_rule.md` as a decision source.
- Decision rule for conflicts: `04_core_model_spec_v1` overrides legacy `Task`-centric semantics.

## Current -> target

| Current | Target | Action |
| --- | --- | --- |
| `TaskTemplate` + `Task` | `ResponsibilityPack` + `ResponsibilityItem` | Merge template/instance model into item-centric core model |
| `TaskKind` | `ResponsibilityItemType` | Replace with `fixedTime / stateBased / resourceBased` |
| `TaskStatus` (`pending / done / skipped / canceled`) | `ResponsibilityItemStatus` (`normal / warning / danger / unknown`) | Replace lifecycle status with computed responsibility status |
| `dueDate / deferredDueDate / repeatRule / reminderRule` | typed item config + `lastDoneAt` | Remove due-date driven task core |
| `Home Today / Upcoming / Overdue` | attention-by-status home model | Replace due-date buckets with responsibility-state buckets |
| `Timeline + Milestone Rule + Milestone Record` | same bounded timeline model | Keep as separate time-meaning model |
| `MilestoneStatus` | `TimelineMilestoneRecordStatus` | Rename to reflect persisted record semantics |

## Target entity list

- `ResponsibilityPack`
- `ResponsibilityItem`
- `ResponsibilityItemConfig`
- `Timeline`
- `TimelineMilestoneRule`
- `TimelineMilestoneOccurrence`
- `TimelineMilestoneRecord`

## Target enum list

- `ResponsibilityItemType`
- `ResponsibilityItemStatus`
- `FixedTimeScheduleType`
- `TimelineStatus`
- `TimelineDisplayUnit`
- `TimelineMilestoneRuleType`
- `TimelineMilestoneIntervalUnit`
- `TimelineMilestoneRuleStatus`
- `TimelineMilestoneRecordStatus`

## Table plan

- Drop legacy task tables from the active schema:
  - `task_templates`
  - `tasks`
- Add responsibility tables:
  - `responsibility_packs`
  - `responsibility_items`
- Keep and align timeline tables:
  - `timelines`
  - `timeline_milestone_rules`
  - `timeline_milestone_records`

## Column mapping plan

### Remove

- `tasks.template_id`
- `tasks.kind`
- `tasks.due_date`
- `tasks.deferred_due_date`
- `tasks.repeat_rule`
- `tasks.reminder_rule`
- `tasks.status`
- `tasks.resolved_at`
- `task_templates.kind`
- `task_templates.status`
- `task_templates.first_due_date`
- `task_templates.repeat_rule`
- `task_templates.reminder_rule`
- `categoryId` fields

### Add

- `responsibility_items.pack_id`
- `responsibility_items.type`
- typed config columns for:
  - fixed-time schedule
  - state-based thresholds
  - resource-based thresholds
- `responsibility_items.last_done_at`

### Keep

- shared content fields: `title`, `description/note`, `created_at`, `updated_at`
- timeline rule and record fields, with status naming cleanup

## Repository / query plan

- Replace `TaskRepository` with `ResponsibilityRepository`
- Replace `TaskBundle` with `ResponsibilityItemBundle`
- Home query contract will expose:
  - danger responsibility items
  - warning responsibility items
  - upcoming timeline milestones
- Timeline repository remains, but record status naming and bundle contracts will be aligned

## Breaking changes

- Legacy `TaskTemplate`, `Task`, `TaskKind`, `TaskStatus`, `TaskRepository`, and task-specific home/history queries will be removed.
- Existing task editor and management flows must be rewritten around responsibility items instead of template/instance scheduling.
- `MilestoneStatus` will be renamed in domain and mapper code.

## Migration notes

- Schema version will advance for the responsibility-model cutover.
- Timeline data should be preserved.
- Legacy task data cannot be losslessly mapped to the new responsibility model because `04_core_model_spec_v1` removes due-date-driven task instances as the core abstraction.
- Conservative migration choice:
  - preserve timeline tables and records
  - create empty responsibility tables
  - drop legacy task tables
- Compatibility note for product behavior:
  - current repo has no pack-management flow; responsibility item creation will use a repository-managed default pack for this round so domain invariants stay consistent without inventing new product scope.

## Main risks

- Home / history / management UI still assumes old task lifecycle semantics.
- Drift migration must preserve timeline data while cutting over task tables.
- Existing tests are heavily task-template oriented and need semantic replacement, not string-level patching.
- `04_core_model_spec_v1` gives limited fixed-time detail; implementation will prioritize `stateBased` correctness and keep fixed/resource config minimal but typed.
