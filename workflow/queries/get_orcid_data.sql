-- simply run a select statement on the following db
[orcid_2018_xml].[dbo].[activity_employment]

-- Get the count of unique individuals
SELECT COUNT(DISTINCT(orcid)) from [orcid_2018_xml].[dbo].[activity_employment]

-- Get the count of unique mobile individuals
SELECT COUNT(DISTINCT(orcid)) from [orcid_2018_xml].[dbo].[activity_employment] WHERE [activity_employment_seq]>1
