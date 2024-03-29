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
    input:
        model = rules.decompose_word2vec_model.output,
        sizes = ORG_SIZES
    output: PULLING_VS_SIZE_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingVsSize.R \
        --input {input.model} --sizes {input.sizes} --output {output}"

rule plot_pulling_vs_pi:
    input:
        model = rules.decompose_word2vec_model.output,
    output: PULLING_VS_PI_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPullingVsPi.R \
        --input {input.model} --output {output}"


rule plot_potential_vs_pi:
    input: rules.decompose_word2vec_model.output,
    output: POTENTIAL_VS_PI_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotPotentialVsPi.R \
        --input {input} --output {output}"

rule plot_factors_all_meta:
    input:
        factors = rules.decompose_word2vec_model.output,
        lookup = ancient(rules.add_state_to_lookup.output),
        sizes = ORG_SIZES
    params:
        ranking = ORG_RANKINGS.format(ranking = "leiden"),
        times = ORG_RANKINGS.format(ranking = "times"),
        carnegie = CARNEGIE_INFO,
        cw = UNI_CROSSWALK,
    output: FACTORS_ALL_CONTINUOUS_META_PLOT
    shell:
        "Rscript scripts/PlotFactors/PlotContinuousFactorsByMeta.R \
        --input {input.factors} --lookup {input.lookup} --times {params.times} \
        --carnegie {params.carnegie} --unicw {params.cw} \
        --leiden {params.ranking} --sizes {input.sizes} \
        --toplot {wildcards.factor} --output {output}"

rule plot_boomerang_compare_to_usa:
    input:
        factors = rules.decompose_word2vec_model.output,
        lookup = ancient(rules.add_state_to_lookup.output),
        sizes = ORG_SIZES
    output: BOOMERANG_COMPARE_PLOT
    shell:
        "Rscript scripts/PlotBoomerangCompare.R --input {input.factors} \
        --lookup {input.lookup} --size {input.sizes} \
        --country1 USA --country2 {wildcards.country} --output {output}"

rule plot_boomerang_all_countries:
    input:
        factors = rules.decompose_word2vec_model.output,
        lookup = ancient(rules.add_state_to_lookup.output),
        sizes = ORG_SIZES
    output: BOOMERANG_ALL_COUNTRIES
    shell:
        "Rscript scripts/PlotBoomerangAllCountries.R --input {input.factors} \
        --lookup {input.lookup} --size {input.sizes} --output {output}"
