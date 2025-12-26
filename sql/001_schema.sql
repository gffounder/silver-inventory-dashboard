create table if not exists source (
  source_id      serial primary key,
  source_name    text not null unique,
  source_url     text,
  cadence        text,
  notes          text
);

create table if not exists metric (
  metric_id      serial primary key,
  metric_key     text not null unique,
  metric_name    text not null,
  unit           text not null,
  frequency      text not null,
  category       text not null,
  source_id      int references source(source_id),
  is_derived     boolean not null default false,
  description    text
);

create table if not exists raw_ingest (
  raw_id         bigserial primary key,
  source_id      int not null references source(source_id),
  fetched_at_utc timestamptz not null default now(),
  as_of_date     date,
  url            text,
  http_status    int,
  checksum_sha256 text,
  payload_bytes  bytea,
  parse_status   text not null default 'pending',
  error_message  text
);

create table if not exists observation (
  obs_id         bigserial primary key,
  metric_id      int not null references metric(metric_id),
  obs_date       date not null,
  value          numeric not null,
  value_text     text,
  source_id      int references source(source_id),
  raw_id         bigint references raw_ingest(raw_id),
  inserted_at_utc timestamptz not null default now(),
  unique(metric_id, obs_date)
);

create table if not exists observation_dim (
  obs_dim_id     bigserial primary key,
  metric_id      int not null references metric(metric_id),
  obs_date       date not null,
  dim_key        text not null,
  dim_val        text not null,
  value          numeric not null,
  source_id      int references source(source_id),
  raw_id         bigint references raw_ingest(raw_id),
  inserted_at_utc timestamptz not null default now(),
  unique(metric_id, obs_date, dim_key, dim_val)
);

create index if not exists idx_observation_metric_date on observation(metric_id, obs_date desc);
create index if not exists idx_observation_dim_metric_date on observation_dim(metric_id, obs_date desc);

create table if not exists alert_rule (
  rule_id        serial primary key,
  rule_key       text not null unique,
  metric_key     text not null,
  window_days    int not null,
  threshold_type text not null,
  threshold_val  numeric not null,
  direction      text not null,
  enabled        boolean not null default true,
  description    text
);

create table if not exists alert_event (
  event_id       bigserial primary key,
  rule_id        int not null references alert_rule(rule_id),
  triggered_at_utc timestamptz not null default now(),
  obs_date       date not null,
  metric_id      int references metric(metric_id),
  trigger_value  numeric not null,
  context_json   jsonb
);

create table if not exists email_run (
  run_id         bigserial primary key,
  run_at_utc     timestamptz not null default now(),
  subject        text,
  body_text      text,
  send_status    text not null,
  error_message  text
);
