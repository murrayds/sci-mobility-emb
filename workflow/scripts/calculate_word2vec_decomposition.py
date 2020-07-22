"""

calculate_word2vec_decomposition.py

author: Jisun Yoon (original); Dakota Murray (workflow)

Decomposes the word2vec model into a set of useful variables
such as the pulling force (s_i, s_j), and the gravitation potential

"""

from gensim.models import Word2Vec
import pandas as pd
import numpy as np
from tqdm import tqdm

def vector_dist(x_i, x_j):
    """
    A helper function for calculate the l2 distnace between vectors
    TODO: move to project package
    """
    l2_distance = np.linalg.norm(x_i - x_j)
    distance_part = np.power(l2_distance, 2) / 2
    return 1 / np.exp(distance_part)

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("--model", help = "the gensim word2vec model to decompose",
                    type = str, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

# Extract the vocabulary, and produce lists of in-vectors and out-vectors
vocab_list = set(list(model.wv.vocab.keys()))
embedding_dict = {k: model.wv[k] for k in vocab_list}
vocab_list_ = model.wv.index2word
out_emb = {word: model.syn1neg[index] for index, word in enumerate(vocab_list_)}

# Construct the s_i/s_j, otherwise the in-vector and out-vector pulling force
in_si = [np.exp(np.power(np.linalg.norm(embedding_dict[vocab]), 2) / 2) for vocab in vocab_list]
out_si = [np.exp(np.power(np.linalg.norm(out_emb[vocab]), 2) / 2) for vocab in vocab_list]

l2norm = [np.linalg.norm(embedding_dict[vocab]) for vocab in vocab_list]

# Calculate the gravitation potential, defined as the product of the
# pulling force and the distance between the embedding vectors
matrix_for_potential = np.zeros((len(vocab_list), len(vocab_list)))
for i, word_1 in tqdm(enumerate(vocab_list)):
    for j, word_2 in enumerate(vocab_list):
        val = in_si[j] * vector_dist(embedding_dict[word_1], embedding_dict[word_2])
        matrix_for_potential[i][j] = val

# create a copy without the "self" potential, i.e. between the vector
# and itself
negative_gravity_potential = []
for i, vocab in enumerate(vocab_list):
    dummy = 0
    for j, vocab_ in enumerate(vocab_list):
        if i != j:
            # accumulate the sum over each vector (excluding)
            dummy += matrix_for_potential[i][j]
    negative_gravity_potential.append(dummy)

# Estiamte the flow of researchers between orgs, $\pi$, based on the
# distance in the embedding space.
dot_product_matrix = np.zeros((len(vocab_list), len(vocab_list)))
for i, word_1 in tqdm(enumerate(vocab_list)):
    for j, word_2 in enumerate(vocab_list):
        dot_product_matrix[i][j] = np.dot(embedding_dict[word_1], embedding_dict[word_2])
partition_function_array = dot_product_matrix.sum(axis=1)

# construct a dataframe from the w2v factors
df = pd.DataFrame({
    'cwts_org_no': list(vocab_list),
    'l2norm': list(l2norm),
    'gravity_potential': list(negative_gravity_potential),
    's_i': list(in_si),
    's_j': list(out_si),
    'pi_i': list(partition_function_array)
})

# Write the output
df.to_csv(args.output, index = False)
