################################################################################
# Snakefile_Descriptive.smk
#
# Contains rules relating to plotting descriptive statistics from our data
#
################################################################################

###############################################################################
# PUBLICATIONS OVER TIME
###############################################################################
rule plot_pubs_over_time:
    input:
        flows = rules.format_trajectories.output,
        researchers = ancient(rules.get_researcher_metadata.output)
    output:
        PUBS_OVER_TIME_PLOT
    shell:
        "Rscript scripts/PlotPubsOverTime.R --input {input.flows} \
                 --researchers {input.researchers} --output {output}"

rule plot_prop_over_time:
    input:
        flows = rules.format_trajectories.output,
        researchers = ancient(rules.get_researcher_metadata.output)
    output:
        PROP_OVER_TIME_PLOT
    shell:
        "Rscript scripts/PlotPropOverTime.R --input {input.flows} \
                 --researchers {input.researchers} --output {output}"

rule plot_pubs_over_time_by_discipline:
    input: rules.format_trajectories.output
    output: PUBS_DISC_OVER_TIME_PLOT
    shell:
        "Rscript scripts/PlotPubsOverTimeByDiscipline.R --input {input} \
                 --output {output}"

rule plot_prop_over_time_by_discipline:
    input: rules.format_trajectories.output
    output: PROP_DISC_OVER_TIME_PLOT
    shell:
        "Rscript scripts/PlotPropOverTimeByDiscipline.R --input {input} \
                 --output {output}"

###############################################################################
# MOBILITY AND AFFILIATIONS
###############################################################################
rule plot_num_affiliations_ecdf:
    input: ancient(rules.get_researcher_metadata.output)
    output: NUM_AFFILIATIONS_ECDF
    shell:
        "Rscript scripts/PlotMobilityECDF.R --input {input} \
                 --output {output}"

rule plot_prop_mobile_by_country:
    input:
        flows = rules.format_trajectories.output,
        nonmobile = rules.filter_to_nonmobile.output,
        researchers = rules.get_researcher_metadata.output,
        lookup = ancient(rules.add_state_to_lookup.output)
    output: PROP_MOBILE_BY_COUNTRY
    shell:
        "Rscript scripts/PlotProportionMobilityByCountry.R --flows {input.flows}\
                 --nonmobile {input.nonmobile} --researchers {input.researchers} --lookup {input.lookup} \
                 --output {output}"

rule plot_org_country_mobility:
    input:
        flows = rules.format_trajectories.output,
        nonmobile = rules.filter_to_nonmobile.output,
        researchers = rules.get_researcher_metadata.output,
        lookup = ancient(rules.add_state_to_lookup.output)
    output: PROP_ORG_COUNTRY_MOBILITY
    shell:
        "Rscript scripts/PlotOrgCountryMobility.R --flows {input.flows}\
                 --nonmobile {input.nonmobile} --researchers {input.researchers} --lookup {input.lookup} \
                 --output {output}"

rule plot_country_mobility_ecdf:
    input:
        flows = rules.format_trajectories.output,
        nonmobile = rules.filter_to_nonmobile.output,
        researchers = rules.get_researcher_metadata.output,
        lookup = ancient(rules.add_state_to_lookup.output)
    output: COUNTRY_MOBILITY_ECDF
    shell:
        "Rscript scripts/PlotCountryMobilityECDF.R --flows {input.flows}\
                 --nonmobile {input.nonmobile} --researchers {input.researchers} --lookup {input.lookup} \
                 --output {output}"

rule plot_country_mobility_distribution:
    input:
        flows = ancient(rules.format_trajectories.output),
        nonmobile = rules.filter_to_nonmobile.output,
        researchers = ancient(rules.get_researcher_metadata.output),
        lookup = ancient(rules.add_state_to_lookup.output)
    output: COUNTRY_MOBILITY_DISTRIBUTION
    shell:
        "Rscript scripts/PlotCountryMobilityDistribution.R --flows {input.flows}\
                 --nonmobile {input.nonmobile} --researchers {input.researchers} --lookup {input.lookup} \
                 --output {output}"
