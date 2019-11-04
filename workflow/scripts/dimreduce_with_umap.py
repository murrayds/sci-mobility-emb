"""

dimreduce_with_tsne.py

author: Dakota Murray

Conducts UMAP dimensioanlity reduction on the word2vec model.

"""
from gensim.models import Word2Vec
import pandas as pd
import umap
import argparse


# The number of components to reduce to
N_COMPONENTS = 2

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-mod", "--model", help="Path to word2vec model", type=str)
parser.add_argument("-met", "--metric", help="Metric to use for UMAP", type = str)
parser.add_argument("-n", "--neighbors", help="Number neighbors for UMAP", type=int)
parser.add_argument("-d", "--mindistance", help="Minimum distance for UMAP", type=float)
parser.add_argument("-o", "--output", help="Output data path", type=str)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

# Perform tsne dimensionality reduction
# Build lists for the tokens and their labels
tokens = [model[word] for word in model.wv.vocab]


reducer = umap.UMAP(metric = args.metric,
                    n_neighbors = args.neighbors,
                    min_dist = args.mindistance,
                    n_components = N_COMPONENTS
                    )
umap_embedding = reducer.fit_transform(tokens)
umap_coords_df = pd.DataFrame(umap_embedding, columns = ['axis1', 'axis2'])
umap_coords_df['token'] = [word for word in model.wv.vocab]

# Save the output
umap_coords_df.to_csv(args.output)
