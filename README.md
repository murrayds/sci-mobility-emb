# sci-mobility-emb
Embedding of scientific mobility across institutions, cities, regions, and countries

**Authors:** Dakota Murray, Jisung Yoon, Woo-Sung Jung, Stasa Milojevic, Rodrigo Costas, Yong-Yeol Ahn

# Reproducing:

Load the provided conda environment, provided in `mobility.yml`, using the command `conda env create -f mobility.yml`. Then be sure to activate this environment in your working directory using `conda activate mobility`.

You can download data for this analysis at [<link pending>](). Create a file called `workflow/PROJ_HOME_DIR` that has a path to the root data folder. For example, `/Dropbox/SME-Dropbox/`.

Change directory to the `workflow` directory and run the `snakemake` command. You can find more information about running snakemake in [the wiki](https://github.com/murrayds/sci-mobility-emb/wiki/Snakemake). This will produce the final figures and all intermediary data used in the research project. As much data as possible has been provided to speed up this process, but it will take some time.
