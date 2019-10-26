"""

dimreduce_with_tsne.py

author: Dakota Murray

Conducts tsne dimensionality reduction on the word2vec model.

"""
PERPLEXITY = 10
N_COMPONENTS = 2
N_ITER = 2000

import sys
from gensim.models import Word2Vec
import pandas as pd
from sklearn.manifold import TSNE

# System arguments
# The path to the word2vec model
WORD2VEC_MODEL_PATH = sys.argv[1]

# The output data path
OUTPUT_PATH = sys.argv[2]

# Load the word2vec model
model = Word2Vec.load(WORD2VEC_MODEL_PATH)

# Perform tsne dimensionality reduction
# Build lists for the tokens and their labels
tokens = [model[word] for word in model.wv.vocab]

# Setup the dimensionality reduction
tsne_model = TSNE(perplexity = PERPLEXITY,
                  n_components = N_COMPONENTS,
                  init = 'pca',
                  n_iter = N_ITER,
                  verbose = True)
# Perform the reduction and get the new components
new_values = tsne_model.fit_transform(tokens)

# Build a dataframe with the new values
x = []
y = []
labels = [word for word in model.wv.vocab]
for value in new_values:
    x.append(value[0])
    y.append(value[1])

tsne_coords_df = pd.DataFrame({'axis1': x, 'axis2': y, 'token': labels})

# Save the output
tsne_coords_df.to_csv(OUTPUT_PATH)
