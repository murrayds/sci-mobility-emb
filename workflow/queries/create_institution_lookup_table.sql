-- generate institution lookup table
SELECT
a.cwts_org_no, a.wos_name, a.full_name, a.city, a.country_iso_num_code, a.latitude, a.longitude,
b.org_type_code,
c.org_type,
d.iso_name as country_iso_name, d.country_iso_alpha3_code as country_iso_alpha
FROM [wosaddr1913].[dbo].[org] as a
join [wosaddr1913].[dbo].[org_org_type] as b on b.cwts_org_no=a.cwts_org_no
left join [wosaddr1913].[dbo].[org_type] as c on c.org_type_code = b.org_type_code
left join [wosaddr1913].[dbo].[country] as d on a.country_iso_num_code = d.country_iso_num_code
