---
--- THE FOLLOWING SHOULD WORK AS IS
---

-- lets get a count of transitions
drop table #transitions
SELECT
	  COUNT(DISTINCT [cwts_org_no]) as inst_count,
	  cluster_id as [cluster_id]
  INTO #transitions
  FROM userdb_murrayds.dbo.mobility_all_pubs_2008_2017
  GROUP BY cluster_id

 -- now lets merge these into the master table
drop table #MASTER_TABLE3
SELECT
	a.*, b.inst_count
into #MASTER_TABLE3
from userdb_murrayds.dbo.mobility_all_pubs_2008_2017 as a
left join #transitions as b on a.cluster_id=b.cluster_id

-- Add org info
drop table [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
SELECT
	a.*, b.wos_name, b.full_name as full_inst_name, b.city, b.country_iso_num_code, c.org_type_code
into [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
FROM #MASTER_TABLE3 as a
left join [wosaddr1913].[dbo].[org] as b on a.cwts_org_no=b.cwts_org_no
left join [wosaddr1913].[dbo].[org_org_type] as c on c.cwts_org_no=b.cwts_org_no
-- 36409373 [01:06]

--- THIS IS THE MAIN THING THAT I NEED TO RUN
--- I just had to re-run the earlier queries to remove a filter
---
--- The goal here is to generate a table of transitions, which I use (locally)
--- to form the mobility trajectories. For now, I will include both mobile and
--- non-mobile trajectories, and sort out the details later
SELECT DISTINCT
	cluster_id, pub_year, cwts_org_no, LR_main_field_no, ut
FROM [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
order by cluster_id, pub_year
