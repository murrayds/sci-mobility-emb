"""

calculate_org_flows.py

author: Dakota Murray

Calculates the institutional flows as a matrix of co-occurences of institutions
by individual.

"""
import pandas as pd
import numpy as np

import argparse

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-i", "--input", help = "Input file, contianing mobility transitons",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load transition data
print('Reading transitions')
transitions = pd.read_csv(args.input, sep = "\t")

# Get a list containing institutions for each individual
transition_lists = transitions.groupby('cluster_id')['cwts_org_no'].apply(list)

# Populate a dictionary of dictionaries, that will hold our co-occurence info
print('Populating empty co-occurence matrix')
co_occur = {}
vocab = transitions.cwts_org_no.unique()
for v1 in vocab:
    # If doesn't yet exist, create the sub-dictionary
    if v1 not in co_occur.keys():
        co_occur[v1] = {}
    # Initialize to zero
    for v2 in vocab:
        co_occur[v1][v2] = 0

# Iterate through each list, incremenet co-occurence count
print('Filling in co-occurences')
for sublist in transition_lists:
    for org1 in sublist:
        for org2 in sublist:
            co_occur[org1][org2] += 1

# Convert into dataframe
co_occur_df = pd.DataFrame(co_occur)

# Fill the diagonal with the row sums
print('Filling diagonal with zeroes')
np.fill_diagonal(co_occur_df.values, 0)

# Get the upper triangle of the matrix
print('Converting to long format')
upper_tri = co_occur_df.where(np.triu(np.ones(co_occur_df.shape)).astype(np.bool))

# Convert into long format
upper_tri = upper_tri.stack().reset_index()

# Set column names
upper_tri.columns = ['org1', 'org2', 'count']

# Write to csv
upper_tri.to_csv(args.output, index_label = False)
