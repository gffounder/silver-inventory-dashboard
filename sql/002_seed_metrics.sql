insert into source (source_name, source_url, cadence, notes)
values
  ('CME',   'https://www.cmegroup.com/clearing/operations-and-deliveries/warehouse-and-depository-data.html', 'daily', 'COMEX daily depository/stock files'),
  ('STOOQ', 'https://stooq.com/', 'daily', 'Free EOD futures-like data')
on conflict (source_name) do nothing;

-- Metrics
insert into metric (metric_key, metric_name, unit, frequency, category, source_id, is_derived, description)
select 'comex.silver.registered_oz', 'COMEX Silver Registered', 'oz', 'daily', 'inventory',
       (select source_id from source where source_name='CME'), false, 'Deliverable (warranted) silver'
where not exists (select 1 from metric where metric_key='comex.silver.registered_oz');

insert into metric (metric_key, metric_name, unit, frequency, category, source_id, is_derived, description)
select 'comex.silver.eligible_oz', 'COMEX Silver Eligible', 'oz', 'daily', 'inventory',
       (select source_id from source where source_name='CME'), false, 'Eligible (not warranted) silver'
where not exists (select 1 from metric where metric_key='comex.silver.eligible_oz');

insert into metric (metric_key, metric_name, unit, frequency, category, source_id, is_derived, description)
select 'price.silver.si_f.close', 'Silver (si.f) Close', 'USD', 'daily', 'price',
       (select source_id from source where source_name='STOOQ'), false, 'Stooq si.f close'
where not exists (select 1 from metric where metric_key='price.silver.si_f.close');

insert into metric (metric_key, metric_name, unit, frequency, category, source_id, is_derived, description)
select 'derived.comex.registered_share', 'COMEX Registered Share', 'ratio', 'daily', 'derived',
       null, true, 'registered / (registered+eligible)'
where not exists (select 1 from metric where metric_key='derived.comex.registered_share');

insert into metric (metric_key, metric_name, unit, frequency, category, source_id, is_derived, description)
select 'derived.inventory_stress', 'Inventory Stress Score', 'z', 'daily', 'derived',
       null, true, 'z-score blend of registered % change + price return + vol'
where not exists (select 1 from metric where metric_key='derived.inventory_stress');

-- Alert rules (defaults)
insert into alert_rule (rule_key, metric_key, window_days, threshold_type, threshold_val, direction, description)
select 'registered_drop_5d_pct', 'comex.silver.registered_oz', 5, 'pct_change', -5, 'lt',
       'Registered down more than 5% over 5 trading days'
where not exists (select 1 from alert_rule where rule_key='registered_drop_5d_pct');

insert into alert_rule (rule_key, metric_key, window_days, threshold_type, threshold_val, direction, description)
select 'stress_regime_tight', 'derived.inventory_stress', 1, 'abs', 1.0, 'gt',
       'Stress score above +1.0 (tight/buffering regime)'
where not exists (select 1 from alert_rule where rule_key='stress_regime_tight');
