"""

calculate_org_flows.py

author: Dakota Murray

Calculates the institutional flows as a matrix of co-occurences of institutions
by individual.

"""
import pandas as pd
import numpy as np
from collections import defaultdict
from itertools import combinations

import logging
logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-i", "--input", help = "Input file, contianing mobility transitons",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load transition data
logging.info('Reading transitions')
transitions = pd.read_csv(args.input, sep = "\t")

# Get a list containing institutions for each individual
transition_lists = transitions.groupby('cluster_id')['cwts_org_no'].apply(list)

# Populate a dictionary of dictionaries, that will hold our co-occurence info
logging.info('Populating empty co-occurence matrix')
co_occur = {}
vocab = transitions.cwts_org_no.unique()

co_occur = defaultdict(lambda: defaultdict(float))
for v1, v2 in combinations(vocab, 2):
    co_occur[v1][v2] = 0
    co_occur[v1][v2] = 0

# Iterate through each list, incremenet co-occurence count
logging.info('Filling in co-occurences')
for sublist in transition_lists:
    for org1 in sublist:
        for org2 in sublist:
            co_occur[org1][org2] += 1

# Convert into dataframe
co_occur_df = pd.DataFrame(co_occur)

# Fill the diagonal with the row sums
logging.info('Filling diagonal with zeroes')
np.fill_diagonal(co_occur_df.values, 0)

# Get the upper triangle of the matrix
logging.info('Converting to long format')
upper_tri = co_occur_df.where(np.triu(np.ones(co_occur_df.shape)).astype(np.bool))

# Convert into long format
upper_tri = upper_tri.stack().reset_index()

# Set column names
upper_tri.columns = ['org1', 'org2', 'count']

# Write to csv
upper_tri.to_csv(args.output, index = False)
