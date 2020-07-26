################################################################################
# Snakefile_Network.smk
#
# Contains rules relating to the creation and computation on network
# representations of the data.
#
################################################################################

rule convert_to_network_edgelist:
    input: rules.calculate_org_flows.output,
    output: FLOWS_NETWORK
    shell:
        "Rscript scripts/ConvertFlowsToNetworkEdgelist.R --input {input} \
        --output {output}"

rule calculate_network_centralities:
    input: rules.convert_to_network_edgelist.output
    output: NETWORK_CENTRALITIES
    shell:
        "python scripts/calculate_network_centralities.py \
        --input {input} --output {output}"


rule plot_centrality_times_compare:
    input:
        lookup = ancient(rules.add_state_to_lookup.output),
        centrality = rules.calculate_network_centralities.output
    params:
        times = ORG_RANKINGS.format(ranking = "times"),
    output: CENTRALITY_TIMES_RANK_PLOT
    shell:
        "Rscript scripts/PlotTimesVsCentralityRank.R --lookup {input.lookup} \
        --times {params.times} --centrality {input.centrality} \
        --measure {wildcards.measure} --output {output}"

rule plot_centrality_semaxis_compare:
    input:
        lookup = ancient(rules.add_state_to_lookup.output),
        centrality = rules.calculate_network_centralities.output,
        semaxis = rules.calculate_semaxis_prestige_projections.output,
    params:
        times = ORG_RANKINGS.format(ranking = "times"),
    output: SEMAXIS_RANK_CENTRALITY_PLOT
    shell:
        "Rscript scripts/PlotSemAxisVsCentralityRank.R --lookup {input.lookup} \
        --semaxis {input.semaxis} --centrality {input.centrality} \
        --measure {wildcards.measure} --times {params.times} --output {output}"
