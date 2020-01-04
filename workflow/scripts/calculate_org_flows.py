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
# Iterate through each list, incremenet co-occurence count
co_occur = defaultdict(lambda: defaultdict(float))
logging.info('Filling in co-occurences')
for sublist in transition_lists:
    for i, org1 in enumerate(sublist):
        for org2 in sublist[i + 1:]:
            if org1 != org2:
                co_occur[org1][org2] += 1
                co_occur[org2][org1] += 1

# Make it as a tuple
tuple_list = []
for org1, v in co_occur.items():
    for org2, value in v.items():
        tuple_list.append((org1, org2, value))

# Make tuple as a DataFrame
co_occur_df = pd.DataFrame(tuple_list, columns=["org1", "org2", "count"])

# Write to csv
co_occur_df.to_csv(args.output, index = False)
