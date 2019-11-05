"""

dimreduce_with_umap.py

author: Dakota Murray

Conducts UMAP dimensioanlity reduction on the word2vec model.

"""
from gensim.models import Word2Vec
import pandas as pd
import umap
import argparse


# The number of components to reduce to
N_COMPONENTS = 2
AXIS1_COLUMN_NAME = 'axis1'
AXIS2_COLUMN_NAME = 'axis2'
TOKEN_COLUMN_NAME = 'token'

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-mod", "--model", help = "Path to word2vec model",
                    type = str, required = True)
parser.add_argument("-met", "--metric", help = "Metric to use for UMAP",
                    type = str, required = True)
parser.add_argument("-n", "--neighbors", help = "Number neighbors for UMAP",
                    type = int, required = True)
parser.add_argument("-d", "--mindistance", help = "Minimum distance for UMAP",
                    type = float, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

# Build lists for the tokens and their labels
tokens = [model[word] for word in model.wv.vocab]

# Setup the UMAP reducer
reducer = umap.UMAP(metric = args.metric,
                    n_neighbors = args.neighbors,
                    min_dist = args.mindistance,
                    n_components = N_COMPONENTS
                    )
umap_embedding = reducer.fit_transform(tokens)

# Convert to pandas dataframe and assign axis names
umap_coords_df = pd.DataFrame(umap_embedding, columns = [AXIS1_COLUMN_NAME, AXIS2_COLUMN_NAME])

# Add the token (word) as a column, labelling each coordinate
umap_coords_df[TOKEN_COLUMN_NAME] = [word for word in model.wv.vocab]

# Save the output
umap_coords_df.to_csv(args.output)
