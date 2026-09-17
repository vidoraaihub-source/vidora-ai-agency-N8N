PRAGMA foreign_keys = ON;

CREATE TABLE agencies (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  timezone TEXT NOT NULL DEFAULT 'America/New_York',
  last_sweep_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  display_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  password_iterations INTEGER NOT NULL,
  disabled INTEGER NOT NULL DEFAULT 0 CHECK (disabled IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE memberships (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner','agent','staff','readonly')),
  can_approve INTEGER NOT NULL DEFAULT 0 CHECK (can_approve IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (agency_id,user_id)
);

CREATE TABLE sessions (
  id_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  csrf_hash TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  idle_expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  external_client_id TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  assigned_employee TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE,
  UNIQUE (agency_id,external_client_id)
);
CREATE INDEX clients_agency_name_idx ON clients(agency_id,last_name,first_name);

CREATE TABLE coverages (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  client_id TEXT NOT NULL,
  coverage_key TEXT NOT NULL,
  policy_number TEXT,
  coverage_type TEXT,
  carrier TEXT,
  annual_review_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  UNIQUE (agency_id,client_id,coverage_key)
);
CREATE INDEX coverages_review_idx ON coverages(agency_id,annual_review_date);

CREATE TABLE work_items (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  client_id TEXT,
  item_key TEXT,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  detail TEXT,
  due_date TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','done')),
  waiting INTEGER NOT NULL DEFAULT 0 CHECK (waiting IN (0,1)),
  requires_approval INTEGER NOT NULL DEFAULT 0 CHECK (requires_approval IN (0,1)),
  approval_result TEXT CHECK (approval_result IS NULL OR approval_result IN ('approved','rejected')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT,
  activated_at TEXT,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  UNIQUE (agency_id,item_key)
);
CREATE INDEX work_items_agency_status_idx ON work_items(agency_id,status,due_date);

CREATE TABLE activities (
  id TEXT PRIMARY KEY,
  agency_id TEXT NOT NULL,
  client_id TEXT,
  user_id TEXT,
  type TEXT NOT NULL,
  summary TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX activities_client_idx ON activities(agency_id,client_id,created_at);

CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  agency_id TEXT,
  user_id TEXT,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  success INTEGER NOT NULL CHECK (success IN (0,1)),
  details_json TEXT,
  ip_hash TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX audit_agency_time_idx ON audit_log(agency_id,created_at);

CREATE TRIGGER audit_log_no_update BEFORE UPDATE ON audit_log BEGIN
  SELECT RAISE(ABORT,'audit log is append-only');
END;
CREATE TRIGGER audit_log_no_delete BEFORE DELETE ON audit_log BEGIN
  SELECT RAISE(ABORT,'audit log is append-only');
END;

CREATE TABLE rate_limits (
  rate_key TEXT PRIMARY KEY,
  window_start TEXT NOT NULL,
  count INTEGER NOT NULL
);
