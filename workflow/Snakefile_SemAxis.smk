################################################################################
# Snakefile_SemAxis.smk
#
# Contains rules relating to generating data and plotting "SemAxis" results
# from our embedding space, i.e., defining axes of meaningful poles and
# projecting organizations onto it.
#
################################################################################

###############################################################################
# IDENTIFY ORGS AT POLES OF AXES
###############################################################################
rule generate_prestige_axis_org_codes:
    input: ORG_RANKINGS,
    output: PRESTIGE_AXIS_ORGS
    params:
        lookup = rules.add_state_to_lookup.output,
        regions = US_CENSUS_REGIONS
    run:
        if "times" in {wildcards.ranking}:
            shell("Rscript scripts/GeneratePrestigeAxisOrgCodes.R --input {input} --output {output} \
                   --variable total_score --regions {params.regions} --lookup {params.lookup} \
                   --norgs {wildcards.numorgs}")
        else:
            shell("Rscript scripts/GeneratePrestigeAxisOrgCodes.R --input {input} --output {output} \
                   --variable impact_frac_mncs --regions {params.regions} --lookup {params.lookup} \
                   --norgs {wildcards.numorgs}")

rule generate_usa_coasts_axis_org_codes:
    input: rules.add_state_to_lookup.output,
    output: COASTS_AXIS_ORGS
    shell:
        "Rscript scripts/GenerateGeographicAxisOrgCodes.R --input {input} \
        --scale region --place1 California --place2 Massachusetts \
        --norgs {wildcards.numorgs} --output {output}"

###############################################################################
# PROJECT ONTO AXES
###############################################################################
rule calculate_semaxis_prestige_projections:
    input:
        w2v = rules.train_word2vec_model.output,
        axis = rules.generate_prestige_axis_org_codes.output
    output: PRESTIGE_AXIS_PROJECTIONS
    shell:
        "python scripts/calculate_SemAxis_projections.py --input {input.w2v} \
        --axis {input.axis} --output {output}"

rule calculate_semaxis_geography_projections:
    input:
        w2v = rules.train_word2vec_model.output,
        axis = rules.generate_usa_coasts_axis_org_codes.output
    output: COASTS_AXIS_PROJECTIONS
    shell:
        "python scripts/calculate_SemAxis_projections.py --input {input.w2v} \
        --axis {input.axis} --output {output}"

###############################################################################
# PRESIGE CORRELATIONS WITH REAL RANKINGS
###############################################################################
rule generate_aggregate_prestige_rank_correlations:
    input:
        axes = [expand(rules.calculate_semaxis_prestige_projections.output,
                       traj = TRAJECTORIES,
                       dimensions = W2V_DIMENSIONS,
                       window = W2V_WINDOW_SIZE,
                       ranking = RANKINGS,
                       numorgs = NUMORGS)],
        lookup = ancient(rules.add_state_to_lookup.output)
    params:
        country = "USA",
        times = ORG_RANKINGS.format(ranking = "times"),
        leiden = ORG_RANKINGS.format(ranking = "leiden"),
    output: PRESTIGE_AGGREGATE_RANK_COR
    shell:
        "Rscript scripts/GetAggregatePrestigeAxisTests.R \
        {input.lookup} \'{params.country}\' {params.times} {params.leiden} \
        {input.axes} {output}"

rule plot_rank_correlation:
    input:
        rules.generate_aggregate_prestige_rank_correlations.output
    output: RANK_CORRELATION_PLOT
    shell:
        "Rscript scripts/PlotPrestigeRankCorrelation.R --input {input} \
        --dim 300 --ws 1 --output {output}"

###############################################################################
# SEMAXIS PLOTS
###############################################################################
rule plot_1d_coasts_semaxis_projection:
    input:
        axis = rules.calculate_semaxis_geography_projections.output,
        lookup = rules.add_state_to_lookup.output
    output: SEMAXIS_1D_COASTS_PLOT
    shell:
        "Rscript scripts/Plot1DSemAxis.R --input {input.axis} --lookup {input.lookup} \
        --output {output} --country USA \
        --endlow California --endhigh Massachusetts \
        --place1 Arizona --place1code AZ --place2 Connecticut --place2code CT"

rule plot_1d_prestige_semaxis_projection:
    input:
        axis = rules.calculate_semaxis_prestige_projections.output,
        lookup = rules.add_state_to_lookup.output
    output: SEMAXIS_1D_PRESTIGE_PLOT
    shell:
        "Rscript scripts/Plot1DSemAxis.R --input {input.axis} --lookup {input.lookup} \
        --output {output} --country USA \
        --endlow Non-elite --endhigh Elite \
        --place1 Indiana --place1code IN --place2 Maryland --place2code MD"

rule plot_2d_semaxis_state_projection:
    input:
        axis1 = rules.calculate_semaxis_geography_projections.output,
        axis2 = rules.calculate_semaxis_prestige_projections.output,
        lookup = rules.add_state_to_lookup.output
    params:
        labels = ORG_SHORT_LABELS
    output: SEMAXIS_2D_COASTS_PRESTIGE_STATE_PLOT
    shell:
        "Rscript scripts/Plot2DSemAxis.R --axis1 {input.axis1} --axis2 {input.axis2} \
        --output {output} \
        --state {wildcards.state} \
        --lookup {input.lookup} --labels {params.labels}"

rule plot_2d_semaxis_projection_by_sector:
    input:
        axis1 = rules.calculate_semaxis_geography_projections.output,
        axis2 = rules.calculate_semaxis_prestige_projections.output,
        lookup = rules.add_state_to_lookup.output
    params:
        types = ORG_TYPES,
        labels = ORG_SHORT_LABELS
    output: SEMAXIS_2D_COASTS_PRESTIGE_SECTOR_PLOT
    shell:
        "Rscript scripts/Plot2DSemAxis.R --axis1 {input.axis1} --axis2 {input.axis2} \
        --output {output} \
        --lookup {input.lookup} --labels {params.labels} --types {params.types} \
        --sector {wildcards.sector}"

rule plot_2d_semaxis_overall_projection:
    input:
        axis1 = rules.calculate_semaxis_geography_projections.output,
        axis2 = rules.calculate_semaxis_prestige_projections.output,
        lookup = rules.add_state_to_lookup.output
    params:
        labels = ORG_SHORT_LABELS
    output: SEMAXIS_2D_COASTS_PRESTIGE_OVERALL_PLOT
    shell:
        "Rscript scripts/Plot2DSemAxis.R --axis1 {input.axis1} --axis2 {input.axis2} \
        --output {output} --overall \
        --lookup {input.lookup} --labels {params.labels}"
