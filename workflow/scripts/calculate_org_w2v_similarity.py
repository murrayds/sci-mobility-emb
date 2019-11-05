"""

calculate_org_geo_distance.py

author: Dakota Murray

Calculates the geographic distance between organizations

"""
import pandas as pd
import numpy as np
from gensim.models import Word2Vec

import argparse

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-mod", "--model", help = "Path to word2vec model",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

# Get the vocabulary of the model
vocab = model.wv.vocab

# Construct the distnace matrix
D = {}
for word1 in vocab:
    D[word1] = {}
    for word2 in vocab:
        D[word1][word2] = model.similarity(word1, word2)

# Convert distance matrix to a dataframe
distance_df = pd.DataFrame(D)

# Get upper triangle
upper_tri = distance_df.where(np.triu(np.ones(distance_df.shape)).astype(np.bool))
upper_tri = upper_tri.stack().reset_index()

# write the output
upper_tri.columns = ['org1', 'org2', 'similarity']

# Write to csv
upper_tri.to_csv(args.output, index = False)
