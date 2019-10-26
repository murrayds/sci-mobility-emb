"""

dimreduce_with_tsne.py

author: Dakota Murray

Conducts UMAP dimensioanlity reduction on the word2vec model.

"""
import sys
from gensim.models import Word2Vec
import pandas as pd
import umap

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


reducer = umap.UMAP()
umap_embedding = reducer.fit_transform(tokens)
umap_coords_df = pd.DataFrame(umap_embedding, columns = ['axis1', 'axis2'])
umap_coords_df['token'] = [word for word in model.wv.vocab]

# Save the output
umap_coords_df.to_csv(OUTPUT_PATH)
