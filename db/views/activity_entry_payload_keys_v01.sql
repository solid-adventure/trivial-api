SELECT DISTINCT	app_id,	jsonb_object_keys(payload) AS keys
FROM activity_entries
ORDER BY keys
