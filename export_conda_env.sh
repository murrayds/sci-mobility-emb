#!/bin/bash

# Assumes that the `mobility` conda environment is currently active

# Export requirements details
conda list -e > requirements.txt

# Export the .yml file
# Can load file from .yml using `conda env create -f mobility.yml`
conda env export | grep -v "^prefix: " > mobility.yml
