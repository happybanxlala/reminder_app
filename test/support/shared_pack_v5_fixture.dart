import 'dart:io';

import 'package:drift/native.dart';
import 'package:reminder_app/features/reminders/data/local/app_database.dart';

const _v5Schema = <String>[
  '''CREATE TABLE item_packs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NULL,
    icon_emoji TEXT NOT NULL DEFAULT '📌',
    order_index INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    is_system_default INTEGER NOT NULL DEFAULT 0 CHECK (is_system_default IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pack_id INTEGER NOT NULL REFERENCES item_packs(id),
    title TEXT NOT NULL,
    description TEXT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    type TEXT NOT NULL,
    attention_policy_source TEXT NOT NULL DEFAULT 'systemDefault',
    fixed_schedule_type TEXT NULL,
    fixed_schedule_interval INTEGER NULL,
    fixed_monthly_day INTEGER NULL,
    fixed_repeat_rule_v2 TEXT NULL,
    fixed_anchor_date INTEGER NULL,
    fixed_due_date INTEGER NULL,
    fixed_time_of_day TEXT NULL,
    fixed_overdue_policy TEXT NULL,
    fixed_expected_before_minutes INTEGER NULL,
    fixed_warning_before_minutes INTEGER NULL,
    fixed_danger_before_minutes INTEGER NULL,
    state_anchor_date INTEGER NULL,
    state_expected_after_minutes INTEGER NULL,
    state_warning_after_minutes INTEGER NULL,
    state_danger_after_minutes INTEGER NULL,
    last_done_at INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE item_action_records (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL REFERENCES items(id),
    action_type TEXT NOT NULL,
    action_date INTEGER NOT NULL,
    remark TEXT NULL,
    payload TEXT NULL,
    is_reverted INTEGER NOT NULL DEFAULT 0 CHECK (is_reverted IN (0, 1)),
    reverted_at INTEGER NULL,
    reverted_by_action_record_id INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE resources (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pack_id INTEGER NOT NULL REFERENCES item_packs(id),
    title TEXT NOT NULL,
    description TEXT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    type TEXT NOT NULL,
    time_anchor_date INTEGER NULL,
    time_duration_days INTEGER NULL,
    time_expected_before_days INTEGER NULL,
    time_warning_before_days INTEGER NULL,
    time_danger_before_days INTEGER NULL,
    quantity_current INTEGER NULL,
    quantity_unit_label TEXT NULL,
    quantity_expected_threshold INTEGER NULL,
    quantity_warning_threshold INTEGER NULL,
    quantity_danger_threshold INTEGER NULL,
    last_refilled_at INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE resource_consumption_rules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    resource_id INTEGER NOT NULL REFERENCES resources(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    trigger_action_type TEXT NOT NULL DEFAULT 'done',
    consume_amount INTEGER NOT NULL DEFAULT 1,
    is_enabled INTEGER NOT NULL DEFAULT 1 CHECK (is_enabled IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE resource_action_records (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    resource_id INTEGER NOT NULL REFERENCES resources(id),
    action_type TEXT NOT NULL,
    action_date INTEGER NOT NULL,
    amount INTEGER NULL,
    resulting_quantity INTEGER NULL,
    added_days INTEGER NULL,
    resulting_duration_days INTEGER NULL,
    source_item_action_record_id INTEGER NULL REFERENCES item_action_records(id),
    remark TEXT NULL,
    is_reverted INTEGER NOT NULL DEFAULT 0 CHECK (is_reverted IN (0, 1)),
    reverted_at INTEGER NULL,
    reverted_by_action_record_id INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE stage_trackers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pack_id INTEGER NOT NULL REFERENCES item_packs(id),
    title TEXT NOT NULL,
    subject_name TEXT NULL,
    tracking_start_date INTEGER NOT NULL,
    tracking_end_date INTEGER NULL,
    status TEXT NOT NULL DEFAULT 'active',
    is_system_default INTEGER NOT NULL DEFAULT 0 CHECK (is_system_default IN (0, 1)),
    system_key TEXT NULL,
    is_hidden INTEGER NOT NULL DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(system_key)
  )''',
  '''CREATE TABLE stage_rules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    stage_tracker_id INTEGER NOT NULL REFERENCES stage_trackers(id),
    type TEXT NOT NULL,
    interval_value INTEGER NOT NULL,
    interval_unit TEXT NOT NULL,
    label_template TEXT NULL,
    reminder_offset_days INTEGER NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE stage_records (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    stage_tracker_id INTEGER NOT NULL REFERENCES stage_trackers(id),
    stage_rule_id INTEGER NULL REFERENCES stage_rules(id),
    source_type TEXT NOT NULL,
    occurrence_index INTEGER NULL,
    occurrence_date INTEGER NOT NULL,
    relative_amount INTEGER NULL,
    relative_unit TEXT NULL,
    status TEXT NOT NULL DEFAULT 'normal',
    label TEXT NOT NULL,
    note TEXT NULL,
    reminder_offset_days INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(stage_tracker_id, stage_rule_id, occurrence_index)
  )''',
  '''CREATE TABLE stage_related_items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    stage_record_id INTEGER NOT NULL REFERENCES stage_records(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE app_settings (
    id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
    reminder_tone TEXT NOT NULL DEFAULT 'standard',
    notification_reminder_time TEXT NOT NULL DEFAULT '09:00',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE pack_templates (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    template_name TEXT NOT NULL,
    icon_emoji TEXT NOT NULL DEFAULT '🏷️',
    description TEXT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
  '''CREATE TABLE pack_template_items (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    template_id INTEGER NOT NULL REFERENCES pack_templates(id),
    order_index INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    attention_policy_source TEXT NOT NULL DEFAULT 'systemDefault',
    fixed_schedule_type TEXT NULL,
    fixed_schedule_interval INTEGER NULL,
    fixed_monthly_day INTEGER NULL,
    fixed_repeat_rule_v2 TEXT NULL,
    fixed_time_of_day TEXT NULL,
    fixed_overdue_policy TEXT NULL,
    fixed_expected_before_minutes INTEGER NULL,
    fixed_warning_before_minutes INTEGER NULL,
    fixed_danger_before_minutes INTEGER NULL,
    state_expected_after_minutes INTEGER NULL,
    state_warning_after_minutes INTEGER NULL,
    state_danger_after_minutes INTEGER NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )''',
];

const _v5Rows = <String>[
  "INSERT INTO item_packs VALUES (1, '一般', 'System default pack', '📌', 0, 'active', 1, 1000, 1000)",
  "INSERT INTO item_packs VALUES (2, 'Fixture Pack', 'v5 personal data', '🧪', 1, 'active', 0, 1100, 1200)",
  "INSERT INTO items (id, pack_id, title, description, status, type, attention_policy_source, state_anchor_date, state_expected_after_minutes, state_warning_after_minutes, state_danger_after_minutes, created_at, updated_at) VALUES (10, 2, 'Fixture Item', 'kept', 'active', 'stateBased', 'userCustomized', 2000, 60, 120, 180, 1100, 1200)",
  "INSERT INTO item_action_records (id, item_id, action_type, action_date, remark, payload, created_at, updated_at) VALUES (11, 10, 'done', 2100, 'fixture action', '{\"fixture\":true}', 2100, 2100)",
  "INSERT INTO resources (id, pack_id, title, description, status, type, quantity_current, quantity_unit_label, quantity_expected_threshold, quantity_warning_threshold, quantity_danger_threshold, created_at, updated_at) VALUES (20, 2, 'Fixture Resource', 'kept', 'active', 'quantityBased', 7, 'pcs', 4, 2, 1, 1100, 1200)",
  "INSERT INTO resource_consumption_rules VALUES (21, 20, 10, 'done', 2, 1, 1100, 1200)",
  "INSERT INTO resource_action_records (id, resource_id, action_type, action_date, amount, resulting_quantity, source_item_action_record_id, remark, created_at, updated_at) VALUES (22, 20, 'consumed', 2100, 2, 5, 11, 'fixture resource action', 2100, 2100)",
  "INSERT INTO stage_trackers (id, pack_id, title, subject_name, tracking_start_date, status, is_system_default, system_key, is_hidden, created_at, updated_at) VALUES (30, 2, 'Fixture Tracker', 'Subject', 1000, 'active', 0, NULL, 0, 1100, 1200)",
  "INSERT INTO stage_rules VALUES (31, 30, 'everyNDays', 7, 'days', 'Week {value}', 1, 'active', 1100, 1200)",
  "INSERT INTO stage_records (id, stage_tracker_id, stage_rule_id, source_type, occurrence_index, occurrence_date, relative_amount, relative_unit, status, label, note, reminder_offset_days, created_at, updated_at) VALUES (32, 30, 31, 'generated', 1, 3000, 7, 'days', 'acknowledged', 'Week 1', 'kept', 1, 1100, 1200)",
  'INSERT INTO stage_related_items VALUES (33, 32, 10, 1100, 1200)',
  "INSERT INTO app_settings VALUES (1, 'early', '20:30', 1000, 1200)",
  "INSERT INTO pack_templates VALUES (40, 'Fixture Template', '🧪', 'kept', 1100, 1200)",
  "INSERT INTO pack_template_items (id, template_id, order_index, title, type, attention_policy_source, state_expected_after_minutes, state_warning_after_minutes, state_danger_after_minutes, created_at, updated_at) VALUES (41, 40, 0, 'Template Item', 'stateBased', 'userCustomized', 60, 120, 180, 1100, 1200)",
];

Future<File> createPinnedV5Database(Directory directory) async {
  final file = File('${directory.path}/reminder_app_v5.sqlite');
  final executor = NativeDatabase(
    file,
    enableMigrations: false,
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
      for (final statement in _v5Schema) {
        database.execute(statement);
      }
      for (final statement in _v5Rows) {
        database.execute(statement);
      }
      database.userVersion = 5;
    },
  );
  final fixture = AppDatabase.forTesting(executor);
  await fixture.customSelect('SELECT COUNT(*) FROM items').getSingle();
  await fixture.close();
  return file;
}

NativeDatabase openFixtureFile(File file, {bool enableMigrations = true}) {
  return NativeDatabase(
    file,
    enableMigrations: enableMigrations,
    setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
  );
}
