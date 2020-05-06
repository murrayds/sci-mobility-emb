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
