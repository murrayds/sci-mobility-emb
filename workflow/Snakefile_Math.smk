################################################################################
# Snakefile_Math.smk
#
# Contains rules relating to demonstrating mathematical relationships of
# word2vec and the gravity model
#
################################################################################

rule plot_pulling_force_comparison:
    input: rules.decompose_word2vec_model.output
    output: PULLING_FORCE_COMPARE_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingForceComparison.R \
        --input {input} --output {output}"

rule plot_pulling_vs_potential:
    input: rules.decompose_word2vec_model.output
    output: PULLING_VS_POTENTIAL_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingVsPotential.R \
        --input {input} --output {output}"

rule plot_pulling_vs_size:
    input: rules.decompose_word2vec_model.output,
    params: ORG_SIZES
    output: PULLING_VS_SIZE_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingVsSize.R \
        --input {input} --sizes {params} --output {output}"

rule plot_pulling_vs_pi:
    input: rules.decompose_word2vec_model.output,
    params: ORG_SIZES
    output: PULLING_VS_PI_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingVsPi.R \
        --input {input} --output {output}"


rule plot_potential_vs_pi:
    input: rules.decompose_word2vec_model.output,
    params: ORG_SIZES
    output: POTENTIAL_VS_PI_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPotentialVsPi.R \
        --input {input} --output {output}"

rule plot_factors_all_meta:
    input:
        factors = rules.decompose_word2vec_model.output,
        lookup = ancient(rules.add_state_to_lookup.output)
    params:
        ranking = ORG_RANKINGS.format(ranking = "leiden"),
        times = ORG_RANKINGS.format(ranking = "times"),
        carnegie = CARNEGIE_INFO,
        cw = UNI_CROSSWALK,
        sizes = ORG_SIZES
    output: FACTORS_ALL_CONTINUOUS_META_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotContinuousFactorsByMeta.R \
        --input {input.factors} --lookup {input.lookup} --times {params.times} \
        --carnegie {params.carnegie} --unicw {params.cw} \
        --leiden {params.ranking} --sizes {params.sizes} \
        --toplot {wildcards.factor} --output {output}"
