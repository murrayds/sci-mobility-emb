"""

calculate_org_geo_distance.py

author: Dakota Murray

Calculates the geographic distance between organizations

"""
import pandas as pd
import numpy as np
from scipy.spatial.distance import pdist, squareform
from geopy.distance import great_circle

import py_scimobility.core as mob

import logging
logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-i", "--input", help = "Input file contianing organization lookup table",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load transition data
logging.info('Loading organization transitions')
organizations = pd.read_csv(args.input, sep = "\t", encoding = "ISO-8859-1")


coordinates = [[row.latitude, row.longitude] for index, row in organizations.iterrows()]

# Using the vincenty distance function.
logging.info('Computing geographic distances')
dist = pdist(coordinates, lambda u, v: mob.compute_geo_distance(u, v))

# Convert distance matrix to a dataframe
distance_df = pd.DataFrame(squareform(dist))

# Set the row and column names
distance_df.columns = organizations.cwts_org_no
distance_df['org1'] = organizations.cwts_org_no
distance_df = distance_df.set_index('org1')

# Get upper triangle
upper_tri = distance_df.where(np.triu(np.ones(distance_df.shape)).astype(np.bool))
upper_tri = upper_tri.stack().reset_index()

# write the output
upper_tri.columns = ['org1', 'org2', 'distance']

# Write to csv
upper_tri.to_csv(args.output, index = False)
