# Reminder App Architecture

## Core Split

Reminder App now uses two independent domain tracks:

- `TaskTemplate + Task`
- `Timeline + Milestone`

This split is mandatory:

- Task has `dueDate`, can be `done / skipped / deferred / canceled`, and may become overdue.
- Timeline has `startDate`, is not a todo item, and never becomes overdue.
- Milestone belongs to Timeline and can be `noticed / skipped`, but does not generate the next milestone from user actions.

## Data Model

Drift tables:

- `task_templates`
- `tasks`
- `timelines`
- `milestones`

Key decisions:

- one-time task is stored directly in `tasks` and may have `templateId = null`.
- `tasks` keep snapshot fields such as `titleSnapshot`, `repeatRule`, and `reminderRule` so template edits do not rewrite historical tasks.
- `task_templates` own recurring template lifecycle, but task-side reminder/repeat snapshots are persisted onto each task row.
- `milestones` are separate from tasks and are excluded from overdue queries by design.
- `timelines` no longer use a `paused` status; active and archived are sufficient.

## Domain Services

- `TaskScheduler`
  - classifies today / upcoming / overdue
  - `Today`: `effectiveDueDate == today`
  - `Upcoming`: future tasks already inside reminder window
  - generates the next recurring task after `done / skipped`
- `TimelineCalculator`
  - computes display counters
  - `Today`: `targetDate == today`
  - `Upcoming`: future milestones already inside reminder window
  - computes milestone reminder dates
  - supports rule-based milestone windows within the next 1 year for MVP

## UI Shape

Home tabs:

- `Today`
- `Upcoming`
- `Overdue`
- `History`

Management is separate from Home:

- Task Template management
- Timeline management

## Migration Policy

Schema version `7` drops legacy reminder tables and recreates the new schema.

Legacy concepts intentionally removed:

- `trackingMode`
- `triggerMode`
- mixed `Reminder/RecurringReminder`
- treating timeline-like entities as tasks
- `TimelineStatus.paused`
