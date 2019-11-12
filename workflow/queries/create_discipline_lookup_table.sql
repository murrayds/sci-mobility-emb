-- generat the discipline lookup table
SELECT DISTINCT LR_main_field_no, LR_main_field
FROM [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
ORDER BY LR_main_field_no
