"""

calculate_network_centralities.py

author: Dakota Murray

Calculate the network centrality using the global
mobility co-occurence network

"""
import pandas as pd
import numpy as np
import networkx as nx

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("--input", help = "Path to the network edgelist",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the network edgelist
edges = pd.read_csv(args.input)

# Construct the network from the edgelist df
g = nx.from_pandas_edgelist(edges, 'Source', 'Target', ['weight'])

# Get a list of nodes
orgs = g.nodes

# Get the degree centralities
degree_centralities = g.degree(weight = 'weight')

# Get the eigenvector centrality
eigen_centralities = nx.eigenvector_centrality_numpy(g, weight = 'weight')

# Build the dataframe
df = pd.DataFrame({
    'cwts_org_no': orgs,
    'degree': [degree_centralities[org] for org in orgs],
    'eigen': [eigen_centralities[org] for org in orgs],
})

# Write the output
df.to_csv(args.output, index = False)
