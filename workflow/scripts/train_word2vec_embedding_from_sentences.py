"""

train_word2vec_embeddings_from_sentences.py

author: Dakota Murray

This performs the word2vec training procedure.

"""
import gensim
import pandas as pd

# Set up the logging so that we can see progress
import logging
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-f", "--files", help = "Files containing mobility sentences",
                    type = str, required = True, nargs = '+')
parser.add_argument("-d", "--dimensions", help = "Embedding dimensionality",
                    type = int, required = True)
parser.add_argument("-w", "--window", help = "Window size for word2vec",
                    type = int, required = True)
parser.add_argument("-wf", "--minfrequency", help = "Minimum word frequency for word2vec",
                    type = int, required = True)
parser.add_argument("-p", "--numworkers", help = "Number of paralell workers",
                    type = int, required = True)
parser.add_argument("-i", "--iterations", help = "Number of training iterations",
                    type = int, required = True)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load all of the the data to use in the embedding
mobility_frames = []
for path in args.files:
    mobility_frames.append(pd.read_csv(path))

mobility_df = pd.concat(mobility_frames)

# We want a sentence representing mobility across the whole period, join all
mobility_df = mobility_df.groupby(['cluster_id'])['sentence'].apply(lambda x: ' '.join(x)).reset_index()

# Tokenize the sentences into a format that gensim can work with
mobility_tokens = []
for sentence in mobility_df.sentence:
    mobility_tokens.append(sentence.split(' '))

# Build and train the gensim word2vec model
model = gensim.models.Word2Vec(
            mobility_tokens,
            size = args.dimensions,
            window = args.window, # just use the entire sentence
            min_count = args.minfrequency, # Remove tokens that don't appear enough
            workers = args.numworkers, # paralellize, use 4 workers
            iter = args.iterations,
            sg = 1 # use the skip_gram model
) # end model

# Save the model
model.save(args.output)
