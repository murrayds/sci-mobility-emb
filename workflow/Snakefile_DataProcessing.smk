################################################################################
# Snakefile_DataProcessing.smk
#
# Contains rules relating to calculation, aggregation, and general processing
# of data relating to the science mobility project.
#
################################################################################

###############################################################################
# ORG LOOKUP FILE
###############################################################################
rule fix_org_coordinates:
    input: ORG_LOOKUP
    params: fixed = ORG_FIXED_COORDINATES
    output: ORG_LOOKUP_FIXED
    shell:
        "Rscript scripts/FixOrgCoordinates.R --lookup {input} \
        --coordinates {params.fixed} --output {output}"

rule lookup_state_from_coords:
    input: ancient(rules.fix_org_coordinates.output)
    output: ORG_STATE_NAMES
    shell:
        "python scripts/lookup_state_from_coords.py --input {input} --sleep 1.1 --output {output}"

rule add_state_to_lookup:
    input: coords = rules.fix_org_coordinates.output,
           states = ancient(rules.lookup_state_from_coords.output)
    output: ORG_LOOKUP_WITH_STATES
    shell:
        "Rscript scripts/AddStatesToLookup.R --lookup {input.coords} --output {output} \
                 --states {input.states}"

###############################################################################
# MOBILITY TRAJECTORY FILES
###############################################################################
rule filter_to_mobile:
    input: ancient(MOBILITY_RAW)
    output: MOBILE_RESEARCHERS
    shell:
        "Rscript scripts/FilterRawByMobilityStatus.R --input {input} \
        --output {output} --mobile"

rule filter_to_nonmobile:
    input: MOBILITY_RAW
    output: NONMOBILE_RESEARCHERS
    shell:
        "Rscript scripts/FilterRawByMobilityStatus.R --input {input} \
         --output {output} --nonmobile"

rule calculate_traj_precedence_rules:
    input: rules.filter_to_mobile.output
    output: TRAJ_PRECEDENCE
    shell:
        "Rscript scripts/CalculateTrajPrecedenceRules.R --input {input} \
        --output {output}"

rule format_trajectories:
    input:
        trajectories = rules.filter_to_mobile.output,
        precedence = rules.calculate_traj_precedence_rules.output
    output:
        MOBILITY_TRAJECTORIES
    shell:
        "Rscript scripts/FormatMobilityTrajectories.R --input {input.trajectories} \
        --output {output} --precedence {input.precedence} --traj {wildcards.traj}"

rule dissagregate_pubs_to_yearly:
    input: rules.format_trajectories.output
    output: MOBILITY_TRAJECTORIES_YEARLY
    shell: "Rscript scripts/FilterRawMobilityToSingleYear.R {input} {wildcards.year} {output}"

rule pubs_to_sentences:
    input: rules.dissagregate_pubs_to_yearly.output
    output: MOBILITY_SENTENCES
    shell:
        "Rscript scripts/FormatPubsToSentences.R {input} org {output}"

###############################################################################
# WORD2VEC
###############################################################################
rule train_word2vec_model:
    input: [expand(MOBILITY_SENTENCES, traj = TRAJECTORIES, year = ALL_YEARS)]
    output: WORD2VEC_EMBEDDINGS
    threads: W2V_NUM_WORKERS
    params:
        wf = W2V_MIN_WORD_FREQ,
        nw = W2V_NUM_WORKERS,
        niter = W2V_ITERATIONS
    shell:
        "python scripts/train_word2vec_embedding_from_sentences.py --files {input} \
                --dimensions {wildcards.dimensions} --window {wildcards.window} \
                --gamma {wildcards.gamma} \
                --minfrequency {params.wf} --numworkers {params.nw} \
                --iterations {params.niter} --output {output}"

rule decompose_word2vec_model:
    input: rules.train_word2vec_model.output
    output: ORG_W2V_FACTORS
    shell:
        "python scripts/calculate_word2vec_decomposition.py --model {input} \
        --output {output}"

rule l2norm_by_country:
    input:
        model = rules.train_word2vec_model.output,
        lookup = ancient(rules.add_state_to_lookup.output)
    output: NORM_BY_COUNTRY
    shell:
        "python scripts/calculate_l2norm_country.py --model {input.model} \
        --lookup {input.lookup} --output {output}"

###############################################################################
# RESEARCHER METADATA
###############################################################################
rule get_researcher_metadata:
    input: raw = rules.format_trajectories.output,
           nonmobile = rules.filter_to_nonmobile.output,
           lookup = ancient(rules.add_state_to_lookup.output)
    output: RESEARCHER_META
    shell:
        "Rscript scripts/GetResearcherMetadata.R --input {input.raw} \
                --nonmobile {input.nonmobile} --lookup {input.lookup} --output {output}"

###############################################################################
# ORG METADATA
###############################################################################
rule get_org_metadata:
    input:
        raw = rules.format_trajectories.output,
        researchers = ancient(rules.get_researcher_metadata.output),
        lookup = ancient(rules.add_state_to_lookup.output)
    output: ORG_META
    shell:
        "Rscript scripts/GetOrgMetadata.R --input {input.raw} --lookup {input.lookup} \
                --researchers {input.researchers} --output {output}"

rule calculate_org_flows:
    input: rules.format_trajectories.output
    output: ORGANIZATION_FLOWS
    shell:
        "python scripts/calculate_org_flows.py --input {input} --output {output}"

rule calculate_org_geographic_distance:
    input: ancient(rules.add_state_to_lookup.output)
    output: ORG_GEO_DISTANCE
    shell:
        "python scripts/calculate_org_geo_distance.py --input {input} --output {output}"

rule calculate_org_w2v_similarities:
    input: rules.train_word2vec_model.output
    output: ORG_W2V_COS_SIMS
    shell:
        "python scripts/calculate_org_w2v_similarity.py \
        --model {input} --output {output} --type cos"

rule calculate_org_w2v_dot:
    input: rules.train_word2vec_model.output
    output: ORG_W2V_DOT_SIMS
    shell:
        "python scripts/calculate_org_w2v_similarity.py \
        --model {input} --output {output} --type dot"

###############################################################################
# AGGREGATE DISTANCES
###############################################################################
rule build_aggregate_org_distances:
    input: flows = rules.calculate_org_flows.output,
           geo = ancient(rules.calculate_org_geographic_distance.output),
           emb = ancient(rules.calculate_org_w2v_similarities.output),
           orgs = ancient(rules.add_state_to_lookup.output),
           dot = ancient(rules.calculate_org_w2v_dot.output),
           pprcos = ancient(ORG_PPR_COS_DISTANCE),
           pprjsd = ancient(ORG_PPR_JSD_DISTANCE),
           lapcos = ancient(ORG_LAP_COS_DISTANCE),
           svdcos = ancient(ORG_SVD_COS_DISTANCE),
           levycos = ancient(ORG_LEVY_COS_DISTANCE),
           levydot = ancient(ORG_LEVY_DOT_DISTANCE),
           levyeuc = ancient(ORG_LEVY_EUC_DISTANCE),
           sizes = ORG_SIZES
    # This can eat up a lot of memory which is a problem when running paralell.
    # Set a maximum, say 2.5-gb
    resources:
        mem_mb = 3000
    output: AGGREGATE_ORG_DISTANCES
    shell:
        "Rscript scripts/BuildAggregateDistanceFile.R --sizes {input.sizes} \
                 --flows {input.flows} --geo {input.geo} --emb {input.emb} \
                 --pprcos {input.pprcos} --pprjsd {input.pprjsd} --dot {input.dot} \
                 --lapcos {input.lapcos} --svdcos {input.svdcos} \
                 --levycos {input.levycos} --levydot {input.levydot} \
                 --levyeuc {input.levyeuc} --orgs {input.orgs} --out {output}"

###############################################################################
# MISC
###############################################################################
rule plot_dot_cosine_relationship:
    input: rules.build_aggregate_org_distances.output
    output: DOT_COSINE_RELATIONSHIP_PLOT
    shell:
        "Rscript scripts/PlotDotCosineRelationship.R --input {input} --output {output}"

rule tabulate_org_shortlabels:
    input: ORG_SHORT_LABELS
    output: ORG_LABEL_TABLE
    shell:
        "Rscript scripts/TabulateOrgShortLabels.R --labels {input} --output {output}"
