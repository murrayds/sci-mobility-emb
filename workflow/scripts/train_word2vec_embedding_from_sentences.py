"""

train_word2vec_embeddings_from_sentences.py

author: Dakota Murray

This performs the word2vec training procedure.

"""
import gensim
import pandas as pd
import random

# Set up the logging so that we can see progress
import logging
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# Helper functions, to eventually be moved off into the package
# This first one simply takes a sentence, and shuffles the words within
def shuffle_sentence(x):
    x = x.split()
    x = random.sample(x, len(x))
    return(' '.join(x))

# This next function takes the mobility dataframe, and
# builds a vocabulary from the mobility across all years,
# shuffling if the paramter is set to true.
def build_sentences(df, shuffle = False):
    if (shuffle):
        df['sentence'] = df['sentence'].apply(shuffle_sentence)

    df = df.groupby(['cluster_id'])['sentence'].apply(lambda x: ' '.join(x)).reset_index()

    # Tokenize the sentences into a format that gensim can work with
    tokens = []
    for sentence in df.sentence:
        tokens.append(sentence.split(' '))

    return(tokens)


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
logging.info("Loading mobility trajectories")
mobility_frames = []
for path in args.files:
    mobility_frames.append(pd.read_csv(path))

mobility_df = pd.concat(mobility_frames)

# Tokenize the sentences into a format that gensim can work with
logging.info("Building initial vocabulary")
tokens = build_sentences(mobility_df, shuffle = False)

# Build and train the gensim word2vec model.
# First, perform initial training on unshuffled vocabulary
model = gensim.models.Word2Vec(
            tokens,
            size = args.dimensions,
            window = args.window, # just use the entire sentence
            min_count = args.minfrequency, # Remove tokens that don't appear enough
            workers = args.numworkers, # paralellize, use 4 workers
            iter = 1,
            sg = 1 # use the skip_gram model
) # end model

# Now update the model, training with shuffled versions of the
# mobility sentences. One iteration has already been completed, so
# repeat for the remaining iterations.
for i in range(args.iterations - 1):
    logging.info("Building new shuffled vocabulary for iteration {}".format(i + 2))
    tokens = build_sentences(mobility_df, shuffle = True)
    model.train(
        tokens,
        total_examples = len(tokens),
        epochs = 1
    )

# Save the model
model.save(args.output)
