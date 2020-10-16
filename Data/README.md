# Data

Derived data and metadata can be downloaded from ...

Raw data cannot be provided due to the proprietary nature of these datasets. If you would like more infomration or would like to fully replicate our results, please contact the auhtors and we can assist you.


#### Raw/

The raw data has not been made available in this analysis due to the propietary nature of the datasets. 

More information on sourcing and downloading the U.S. Flight Itinerary Datasets can be found using the [Airport Origin and Destination Survey](https://www.transtats.bts.gov/DatabaseInfo.asp?DB_ID=125) operated by the U.S. Bureau of Transportation Statistics. 

We use a version of the Web of Science dataset licensed and maintained by the Center for Science and Technology Studies at Leiden Univeristy. 


#### Derived/

All files in the `Derived` folder have been generated via Snakemake or another automated workflow. These files, coupled with those in `Additional/` should allow the creation of nearly all figures using the Snakemake workflow. 

- **CountryPairwise/:** Files for pairwise embedding distances between countries
- **Descriptive/:** Organization- and researcher-level metadata generated from raw data and metadata to support visualization
- **Embeddings/:** Trained embeddings learned from data on scientific mobility, as well as U.S. flight itineraties and South Korean accomodation reservations. Also contains organization vector norms and factorized values for each organization in the scientific mobility embedding
- **Network/:** Network representations of scientific mobility along with infomration generated from the network
- **SemAxis/:** Data derived from applications of the SemAxis technique on the scientific mobility embedding space
- **Sentences/:** 'Sentences' derived from the mobility data, where each sentence is a mobility trajectory generated for an individual in the WoS dataset
- **Stat/:** Quantitative results generated from the embedding and metadata, such as predictions made using the gravity model
- **Visualzation_coordinates/:** UMAP coordinates used to visualize the embedding space



#### Additional/

The `Additional/` folder contains metadata, pulled from various sourced, used to support analysis related to scientific mobility

- **2008-2019_inst_sizes.txt:** the number of unique mobile and non-mobile authors who published at least one article affiliated with the given institution, each year form 2008 to 2019. Used to calculate organization size
- **20191024_discipline_lookup.txt:** Maps disciplinary codes from the WoS data to a full name of that discipline
- **20191024_institution_lookup.txt:** Partial metadata related to each scientific organization in the WoS dataset
- **carnegie_cwts_us_uni_crosswalk.csv:** Crosswalk table that maps U.S. universities in the Web of Science dataset to their records in the Carnegie Classification of Higher Education institutions. Manually created.
- **CCIHE2018-PublicData.xlsx:** Metadata for U.S. univeristies sourced from the Carnegie Classification of Higher Education Institutions
- **city_to_region:** Maps city/country IDs of scientific organizations to a city and country name
- **country_language.csv:** Country-level metadata of the most commonly-spoken language in that country
- **country_metadata.csv:** Additional country-level metadata, including its region, family of most widely-spoken language, and Science & Technology Index
- **fixed_org_coordinates:** Coordinates for 2,267 unique organizations correponding to incorrect or missing coordinates taken from the WoS dataset, which in turn were sourced from the GRID institutional metadata. These fixed coordinates were manually obtained by searching the organization name in Google Earth, and taking an approximate coordinate (if the organization was found) or the approximate midpoint of the City (if the organization was not found)
- **institution_lookup_fixed.txt:** Organization-level metadata, with coordinates fixed using the `fixed_org_coordinates` file
- **institution_lookup_with_states.txt:** organizational-level metadata, with state (region?) level classification for each organization. For example, the organization "Indiana Univeristy" would be mapped to the state of "Indiana", whereas "Univeristy of Mealbourne" would be mapped to "Victoria"
- **iso_to_country.txt:** Maps ISO country codes (both size 2 and 3) to other country-level metadata
- **leiden_ranking.csv:** Organization-level impact taken from the Leiden Ranking of World Univeristies, using information from 2014 to 2019. The relevant column is `impact_frac_mncs` which is the fractional mean-normalized citation score of publications published by the organization. 
- **org_impact_scores.txt:** Org-impact scores derived from the Web of Science for all organizations, not only univeristies. These are used for supplemental analyses regarding non-univeristy organizations, such as teaching colleges and government organizations.
- **org_shortlabels:** Shortened labels for organizations, manually created
- **org_states.csv:** State assignments made to organizations based on their geographic coordiantes, queried using LocationIQ reverse-geocoding service
- **org_to_scales.txt:** Maps organizations to cities and countires. Defunct in current analysis
- **org_types.csv:** Maps organization types from the Web of Science dataset to a simplifed taxonomy
- **OrgAxes/:** Folder containing lists of organizations, some manually and some automatically generated, used to define the poles of SemAxis analyses
- **orgs_not_government.csv:** List of organizations that, while classified as government organizations, due not naturally fit in this definition, and so are removed for relevant analyses
- **times_ranking.csv:** Scores of U.S. univeristies taken from the Times Ranking of Higher Education Institutions
- **traj_precedence_rules.txt:** Precedence rules determining when to exclude organizations in a trajectory. Some specific organizations always co-appear with a more high-level organization (i.e., "Harvard Medical School" with "Harvard Univeristy"); in these cases, the more general organization is removed. This file is generated systematically by looking at rates of co-occurence in the data. 
- **usa_states_to_regions.csv:** Maps U.S. states to census and economic regions. 
