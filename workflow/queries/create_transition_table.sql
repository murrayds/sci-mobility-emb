-- Generate the main transitions table, meant to be as small as possible
-- save this to a file
SELECT DISTINCT
cluster_id, pub_year, cwts_org_no, LR_main_field_no
FROM [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
order by cluster_id, pub_year
-- 22,436,637 [02:43]
