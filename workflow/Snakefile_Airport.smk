################################################################################
# Snakefile_Airport.smk
#
# Contains rules relating to relating proximities in the US Airport
# trajectory network
#
################################################################################

###############################################################################
# VARIANCE EXPLAINED
###############################################################################
rule plot_gravity_relationship_airport:
    input: AIRPORT_DATA
    output: GRAVITY_AIRPORT_PLOT
    shell:
        "Rscript scripts/PlotGravityLawRelationshipAirport.R --input {input} \
        --output {output} --distance {wildcards.airdistance} --showcoef"

# ###############################################################################
# # PREDICTIONS
# ###############################################################################
rule calculate_predicted_vs_actual_airport:
    input: AIRPORT_DATA,
    output: AIRPORT_PREDICTED_VS_ACTUAL,
    shell:
        "Rscript scripts/CalculatePredictedVsActualAirport.R --input {input} \
        --output {output} --distance {wildcards.airdistance}"

rule plot_predicted_vs_actual_airport:
    input: rules.calculate_predicted_vs_actual_airport.output
    output: AIRPORT_PREDICTED_VS_ACTUAL_PLOT
    shell:
        "Rscript scripts/PlotPredictedVsActualAirport.R --input {input} \
        --model {wildcards.model} --output {output}"
#
# rule plot_predicted_vs_actual_filtered:
#     input: rules.calculate_predicted_vs_actual.output,
#     output: PREDICTED_VS_ACTUAL_PLOT_FILT
#     shell:
#         "Rscript scripts/PlotPredictedVsActual.R --input {input} --output {output} \
#         --model {wildcards.model} --geo {wildcards.geo_constraint_filt}"
#
# ###############################################################################
# # HYPERPARAMETER PERFORMANCE
# ###############################################################################
# rule get_aggregate_gravity_slopes:
#     input:
#         [expand(rules.build_aggregate_org_distances.output,
#                 traj = TRAJECTORIES,
#                 dimensions = W2V_DIMENSIONS,
#                 window = W2V_WINDOW_SIZE)]
#     output: AGGREGATE_SLOPES
#     shell:
#         # using default argument parsing here
#         "Rscript scripts/GetAggregateSlopes.R {input} {output}"
#
#
# rule get_aggregate_gravity_r2:
#     input:
#         [expand(rules.build_aggregate_org_distances.output,
#                 traj = TRAJECTORIES,
#                 dimensions = W2V_DIMENSIONS,
#                 window = W2V_WINDOW_SIZE)]
#     threads: 4
#     output: AGGREGATE_R2
#     shell:
#         # using default argument parsing here
#         "Rscript scripts/GetAggregateGravityR2.R {input} {output}"
#
# rule plot_hyperparameter_performance:
#     input:
#         rules.get_aggregate_gravity_r2.output
#     output: HYPERPARAMETER_PERFORMANCE
#     shell:
#         "Rscript scripts/PlotHyperparameterPerformance.R --input {input} --output {output}"
#
# ###############################################################################
# # MISC: PLOT ELEMENTS
# ###############################################################################
# rule plot_gradient_legend:
#     output: GRADIENT_LEGEND
#     shell:
#         "Rscript scripts/PlotGradientLegend.R --output {output}"
