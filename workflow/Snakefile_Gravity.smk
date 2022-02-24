################################################################################
# Snakefile_Gravity.smk
#
# Contains rules relating to relating proximities to the gravity law, in terms
# of explaining total flux or making predictions.
#
################################################################################

###############################################################################
# VARIANCE EXPLAINED
###############################################################################
rule plot_gravity_relationship:
    input: rules.build_aggregate_org_distances.output
    output: GRAVITY_RELATIONSHIP_PLOT
    params:
        filterflag = lambda w: '--{}'.format(w.to_filter)
    shell:
        "Rscript scripts/PlotGravityLawRelationship.R --input {input} \
                 --output {output} --geo {wildcards.geo_constraint} \
                 --distance {wildcards.distance} {params.filterflag} --showcoef"

###############################################################################
# PREDICTIONS
###############################################################################
rule calculate_predicted_vs_actual:
    input: rules.build_aggregate_org_distances.output,
    output: PREDICTED_VS_ACTUAL,
    shell:
        "Rscript scripts/CalculatePredictedVsActual.R --input {input} \
        --output {output} --geo {wildcards.geo_constraint} \
        --distance {wildcards.distance}"

rule plot_predicted_vs_actual:
    input: rules.calculate_predicted_vs_actual.output
    output: PREDICTED_VS_ACTUAL_PLOT
    shell:
        "Rscript scripts/PlotPredictedVsActual.R --input {input} \
        --model {wildcards.model} --output {output}"

rule plot_predicted_vs_actual_filtered:
    input: rules.calculate_predicted_vs_actual.output,
    output: PREDICTED_VS_ACTUAL_PLOT_FILT
    shell:
        "Rscript scripts/PlotPredictedVsActual.R --input {input} --output {output} \
        --model {wildcards.model} --geo {wildcards.geo_constraint_filt}"

rule calculate_cpc_measures:
    input: expand(rules.calculate_predicted_vs_actual.output, traj = "precedence", geo_constraint = "global", dimensions = 300, window = 1, gamma = 1.0, model = GRAVITY_MODEL_TYPES, sizetype = "all", distance = DISTANCE_PARAMS),
    output: CPC_MEASURES
    shell:
        "python scripts/calculate_cpc_measures.py --output {output} --input {input}"

rule plot_cpc_performance:
    input: rules.calculate_cpc_measures.output
    output: CPC_PERFORMANCE_PLOT
    shell:
        "Rscript scripts/PlotCPCMeasurePerformance.R --input {input} --output {output}"

###############################################################################
# HYPERPARAMETER PERFORMANCE
###############################################################################
rule get_aggregate_gravity_slopes:
    input:
        [expand(rules.build_aggregate_org_distances.output,
                traj = TRAJECTORIES,
                dimensions = W2V_DIMENSIONS,
                window = W2V_WINDOW_SIZE,
                gamma = W2V_GAMMA,
                sizetype = SIZETYPE)]
    output: AGGREGATE_SLOPES
    shell:
        # using default argument parsing here
        "Rscript scripts/GetAggregateSlopes.R {input} {output}"


rule get_aggregate_gravity_r2:
    input:
        [expand(rules.build_aggregate_org_distances.output,
                traj = TRAJECTORIES,
                dimensions = W2V_DIMENSIONS,
                window = W2V_WINDOW_SIZE,
                gamma = W2V_GAMMA,
                sizetype = SIZETYPE)]
    threads: 4
    output: AGGREGATE_R2
    shell:
        # using default argument parsing here
        "Rscript scripts/GetAggregateGravityR2.R {input} {output}"


rule get_aggregate_rmse:
    input:
        [expand(rules.calculate_predicted_vs_actual.output,
                traj = TRAJECTORIES,
                distance = DISTANCE_PARAMS,
                geo_constraint = GEO_CONSTRAINTS,
                dimensions = TARGET_DIMENSIONS,
                window = TARGET_WINDOW_SIZE,
                gamma = TARGET_GAMMA,
                sizetype = SIZETYPE,
                model = GRAVITY_MODEL_TYPES)]
    output: AGGREGATE_RMSE
    shell:
        "Rscript scripts/GetAggregateRMSE.R {input} {output}"


rule plot_hyperparameter_performance:
    input:
        rules.get_aggregate_gravity_r2.output
    output: HYPERPARAMETER_PERFORMANCE
    shell:
        "Rscript scripts/PlotHyperparameterPerformance.R --input {input} --output {output}"

rule plot_distance_metric_performance:
    input:
        r2 = rules.get_aggregate_gravity_r2.output,
        rmse = rules.get_aggregate_rmse.output
    output: DISTANCE_METRIC_PERFORMANCE
    shell:
        "Rscript scripts/PlotDistanceMetricPerformance.R --r2 {input.r2} \
        --rmse {input.rmse} --output {output}"

rule plot_distance_prediction_performance:
    input: rules.get_aggregate_rmse.output
    output: DISTANCE_PREDICTION_PERFORMANCE
    shell:
        "Rscript scripts/PlotDistancePredictionPerformance.R --input {input} --output {output}"

###############################################################################
# MISC: PLOT ELEMENTS
###############################################################################
rule plot_gradient_legend:
    output: GRADIENT_LEGEND
    shell:
        "Rscript scripts/PlotGradientLegend.R --output {output}"
