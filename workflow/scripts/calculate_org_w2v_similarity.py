"""

calculate_org_geo_distance.py

author: Dakota Murray

Calculates the geographic distance between organizations

"""
import pandas as pd
import numpy as np
from gensim.models import Word2Vec
from collections import defaultdict
from itertools import combinations


import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-mod", "--model", help = "Path to word2vec model",
                    type = str, required = True)
parser.add_argument("--type", help = "Type of similarity, 'dot', 'euclidean', or 'cos'",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

# Get the vocabulary of the model
vocab = model.wv.vocab

# Construct the distnace matrix
D = defaultdict(lambda: defaultdict(float))

# There is some code repetition here, but its worth it to
# not check the args.type every iteration of the loop
if args.type == 'cos':
    for word1, word2 in combinations(vocab, 2):
        temp_sim = model.similarity(word1, word2)
        D[word1][word2] = temp_sim
        D[word2][word1] = temp_sim
elif args.type == 'dot':
    for word1, word2 in combinations(vocab, 2):
        temp_sim = np.dot(model.wv[word1], model.wv[word2])
        D[word1][word2] = temp_sim
        D[word2][word1] = temp_sim
elif args.type == 'euclidean':
    for word1, word2 in combinations(vocab, 2):
        w1 = model.wv[word1]
        w2 = model.wv[word2]
        temp_sim = np.power(np.linalg.norm(w1 - w2), 2) / 2
        D[word1][word2] = temp_sim
        D[word2][word1] = temp_sim

# Convert distance matrix to a dataframe
distance_df = pd.DataFrame(D)

# Get upper triangle
upper_tri = distance_df.where(np.triu(np.ones(distance_df.shape)).astype(np.bool))
upper_tri = upper_tri.stack().reset_index()

# write the output
upper_tri.columns = ['org1', 'org2', 'similarity']

# Write to csv
upper_tri.to_csv(args.output, index = False)
