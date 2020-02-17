################################################################################
# Snakefile_UMAP.smk
#
# Contains rules relating to creating and visualizing UMAP projections of
# the embedding space
#
################################################################################

###############################################################################
# PROJECTION
###############################################################################
rule dimreduce_umap:
    input: model = rules.train_word2vec_model.output,
           lookup = ancient(rules.add_state_to_lookup.output)
    output: UMAP_DATA
    shell:
        'python scripts/dimreduce_with_umap.py --model {input.model} \
                --metric {wildcards.metric} --neighbors {wildcards.neighbors} \
                --mindistance 0.1 --country {wildcards.country} \
                --lookup {input.lookup} --output {output}'

###############################################################################
# VISUALIZATION
###############################################################################
rule plot_umap_org:
    input: rules.dimreduce_umap.output
    params:
        orgs = ancient(rules.add_state_to_lookup.output),
        countries = COUNTRY_LOOKUP
    output: UMAP_VISUALIZATIONS_ORG
    shell:
        "Rscript scripts/PlotOrgDimReducedEmbedding.R {input} {params.orgs} \
        {params.countries} {output}"
