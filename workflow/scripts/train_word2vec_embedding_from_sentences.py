"""

train_word2vec_embeddings_from_sentences.py

author: Dakota Murray

This performs the word2vec training procedure.

"""
EMBEDDING_VECTOR_SIZE_KEY = "vector_size"
EMBEDDING_WINDOW_SIZE_KEY = "window_size"
EMBEDDING_MIN_WORD_COUNT_KEY = "min_word_freq"
EMBEDDING_NUM_WORKERS_KEY = "num_workers"
EMBEDDING_ITERATIONS_KEY = "iterations"

import sys
import gensim
import pandas as pd
import json

# Set up the logging so that we can see progress
import logging
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# System arguments
# First, get the set of mobility paths that we will be working with
MOBILITY_SENTENCES_PATHS = sys.argv[1:len(sys.argv) - 2]

# Then, get the dictionary containing the parameters
PARAM_PATH = sys.argv[len(sys.argv) - 2 ]

# Finally, the output data path
MOBILITY_OUTPUT_PATH = sys.argv[len(sys.argv) - 1]

# Load all of the the data to use in the embedding
mobility_frames = []
for path in MOBILITY_SENTENCES_PATHS:
    mobility_frames.append(pd.read_csv(path))

mobility_df = pd.concat(mobility_frames)


# Tokenize the sentences into a format that gensim can work with
mobility_tokens = []
for sentence in mobility_df.sentence:
    mobility_tokens.append(sentence.split(' '))


vector_size, window_size, min_word_freq, num_workers, iterations = [None] * 5

# Now load and process the parameter file
with open(PARAM_PATH) as param_file:
    params = json.load(param_file)
    vector_size = params[EMBEDDING_VECTOR_SIZE_KEY]
    window_size = params[EMBEDDING_WINDOW_SIZE_KEY]
    min_word_freq = params[EMBEDDING_MIN_WORD_COUNT_KEY]
    num_workers = params[EMBEDDING_NUM_WORKERS_KEY]
    iterations = params[EMBEDDING_ITERATIONS_KEY]


print("training model")
# Build and train the gensim word2vec model
model = gensim.models.Word2Vec(
            mobility_tokens,
            size = vector_size,
            window = window_size, # just use the entire sentence
            min_count = min_word_freq, # Remove tokens that don't appear enough
            workers = num_workers, # paralellize, use 4 workers
            iter = iterations,
            sg = 1 # use the skip_gram model
) # end model

# Save the model
model.save(MOBILITY_OUTPUT_PATH)
