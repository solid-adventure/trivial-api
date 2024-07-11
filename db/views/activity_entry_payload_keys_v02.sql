WITH entry_data AS (
	SELECT
		app_id,
		jsonb_object_keys(payload) AS primary_key,
		payload
	FROM
		activity_entries
),
extracted_key_data AS (
	SELECT
		entry_data.app_id,
		entry_data.primary_key,
		secondary_key_data.secondary_key
	FROM entry_data
	LEFT JOIN LATERAL (
		SELECT
			jsonb_object_keys(entry_data.payload -> entry_data.primary_key) AS secondary_key
		WHERE
			jsonb_typeof(entry_data.payload -> entry_data.primary_key) = 'object'
	) secondary_key_data ON true
)
SELECT DISTINCT
	app_id,
	primary_key,
	secondary_key
FROM
	extracted_key_data
ORDER BY
	primary_key,
	secondary_key
