-- get the size of institutions, regardless of mobility
drop table #instsize
SELECT
	  COUNT(DISTINCT [cluster_id]) as person_count,
	  cwts_org_no as [cwts_org_no],
	  pub_year as [pub_year]
  INTO #instsize
  FROM userdb_murrayds.dbo.mobility_all_pubs_2008_2017
  GROUP BY cwts_org_no, pub_year

select * from #instsize ORDER BY cwts_org_no, pub_year
