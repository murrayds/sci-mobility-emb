-- This query is a modified version of that used by Rodrigo Costas to
-- extract collaboration leadership. The current version was created by
-- Dakota Murray.


-- Step 1. Data collection
-- gets all of the clusters and their affiliation country codes
drop table #step1a
select distinct
a.cluster_id, a.ut, a.au_count, o.cwts_org_no
into #step1a
from [wosauthors1913].[dbo].[clusters_pubs] as a
join [wosaddr1913].[dbo].[pub_author_affiliation] as b on a.ut=b.ut and a.au_count=b.au_count
--join [wosaddr1913].[dbo].[pub_affiliation] as c on b.ut=c.ut and b.aff_count=c.aff_count
join [wosaddr1913].[dbo].[pub_affiliation_org] as o on b.ut=o.ut and b.aff_count=o.aff_count
--111286146 [18:43]
-- There is an unexpected problem: apparently some papers have only some authors with affiliations, but not all (e.g. ut='000207597000006').
-- I suggest to remove those. Essentially those that have less authors than the count of au_count


-- This set limits to only those records in which the authors have an affiliation
drop table #uts_good
select a.ut, b.n_authors, count(distinct a.au_count) as dist_au_count
into #uts_good
from #step1a as a
join woskb.dbo.cwts_ut as b on a.ut=b.ut
group by a.ut, b.n_authors
having  count(distinct a.au_count)=b.n_authors
--12698656 [01:16]


-- Select only those rows in #step1a which have a good ut
drop table #step1
select a.*
into #step1
from #step1a as a
join #uts_good as b on a.ut=b.ut
--77458988 [00:31]


-- include only papers which have author-affiliation linages, the rest can't be used
drop table #step2
select distinct
a.cluster_id, a.ut, a.au_count, y.cwts_org_no
into #step2
 from wosauthors1913.dbo.clusters_pubs as a
 join wosdb..rp as b on a.ut = b.ut
 join wosdb..ra as c on b.ra_no = c.ra_no
 join wosdb..au as d on c.ra = d.au
 join wosdb..au_glue as e on a.ut = e.ut
	and d.au_no = e.au_no
	and a.au_count = e.au_count
join [wosaddr1813].[dbo].[pub_reprint] as x on a.ut=x.ut and b.RP_COUNT=x.rp_count and b.NU_NO=x.nu_no
join #step1 as y on a.ut=y.ut and a.cluster_id=y.cluster_id -- We force that papers and authors have affiliation data
--13848677 [11:04]  We  focus only on those papers for which we have author-affiliation linkages


-- Merge the tables
drop table #clusters_pubs_addresses_linked_to_author
select *
into #clusters_pubs_addresses_linked_to_author
from (
	select *
	from #step1
	union
	select *
	from #step2
	) as tt
--77462592 [01:07]


-- Get the disciplinary classifications
drop table #LR_Classif
SELECT distinct [cluster_id1]
      ,a.[LR_main_field_no]
      ,[primary_LR_main_field]
	  ,b.LR_main_field
into #LR_Classif
  FROM [wosclassification1913].[dbo].[cluster_LR_main_field1] as a
  join [wosclassification1913].[dbo].[LR_main_field] as b on a.LR_main_field_no=b.LR_main_field_no
  where primary_LR_main_field=1
--4535

-- Adding discipline classifications to the master table
drop table #MASTER_TABLE1
select distinct
a.*, c.LR_main_field, c.LR_main_field_no
into #MASTER_TABLE1
from #clusters_pubs_addresses_linked_to_author as a
join [wosclassification1913].[dbo].[clustering] as b on a.ut=b.ut
join #LR_Classif as c on c.cluster_id1=b.cluster_id1
-- join userdb_costascomesanar.dbo.cwts_ut_20190608 as d on a.ut=d.ut
-- left join [wosgender1913].[dbo].[cluster_gender_90] as x on a.cluster_id=x.cluster_id
--63193562 [01:49]
-- we don't need gender or country-level informaiton, exclude for now

select top 1000 * from #MASTER_TABLE1 order by cluster_id

-- we don't need funding information, skip it and construct the ginal table

-- drop table userdb_murrayds.dbo.mobility_MASTER_TABLE_mob_lead_2008_2017
drop table userdb_murrayds.dbo.mobility_all_pubs_2008_2017
select distinct
x.first_name, x.full_name, b.pub_year, a.*,
x.n_pubs as tot_n_pubs_wos
into userdb_murrayds.dbo.mobility_all_pubs_2008_2017
into #MASTER_TABLE2
from #MASTER_TABLE1 as a
join woskb.dbo.cwts_ut as b on a.ut=b.ut
join wosauthors1913.dbo.clusters as x on a.cluster_id=x.cluster_id
where
b.retraction=0
and b.pub_year between 2008 and 2019
and b.cwts_dt_no in (2,4)
-- 54738634 [02:39]


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
  where inst_count > 1
 --35886552 [01:09]


-- count the number of individuals represented
select COUNT(DISTINCT cluster_id) FROM #MASTER_TABLE3
-- 3,709,869


-- Add org info
drop table [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
SELECT
	a.*, b.wos_name, b.full_name as full_inst_name, b.city, b.country_iso_num_code, c.org_type_code
into [userdb_murrayds].[dbo].[MOBILITY_TRANSITIONS_2008_2019]
FROM #MASTER_TABLE3 as a
left join [wosaddr1913].[dbo].[org] as b on a.cwts_org_no=b.cwts_org_no
left join [wosaddr1913].[dbo].[org_org_type] as c on c.cwts_org_no=b.cwts_org_no
-- 36409373 [01:06]
