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

- `tasks` keep snapshot fields such as `titleSnapshot` so template edits do not rewrite historical tasks.
- `task_templates` own repeat and reminder rules.
- `milestones` are separate from tasks and are excluded from overdue queries by design.

## Domain Services

- `TaskScheduler`
  - classifies today / upcoming / overdue
  - computes reminder start from `ReminderRule`
  - generates the next recurring task after `done / skipped`
- `TimelineCalculator`
  - computes display counters
  - classifies milestone today / upcoming
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

Schema version `6` drops legacy reminder tables and recreates the new schema.

Legacy concepts intentionally removed:

- `trackingMode`
- `triggerMode`
- mixed `Reminder/RecurringReminder`
- treating timeline-like entities as tasks
