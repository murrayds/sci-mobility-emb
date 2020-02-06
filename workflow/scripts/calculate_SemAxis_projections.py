"""

calculate_org_flows.py

author: Dakota Murray

Calculates the institutional flows as a matrix of co-occurences of institutions
by individual.

"""
from gensim.models import Word2Vec
import pandas as pd

# For SemAxis
import numpy as np
from scipy import spatial
import argparse

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument(
    "-i",
    "--input",
    help="Input file, contianing path to word2vec model to use",
    type=str,
    required=True,
)
parser.add_argument(
    "-a",
    "--axis",
    help="Input file, path to file containing which orgs to use to define the axis",
    type=str,
    required=True,
)
parser.add_argument("-o", "--output", help="Output data path", type=str, required=True)
args = parser.parse_args()

# Functions should be offloaded to a package at a later date,
def get_avg_vec_from_list(emb, wordlist):
    tmp = [emb.wv[word] for word in wordlist if word in model.wv.vocab]
    return np.mean(tmp, axis=0)

def project_onto_axis(emb, word, antonym):
    axis = antonym[1] - antonym[0]
    return(1.0 - spatial.distance.cosine(emb.wv[word], axis))

# Load the word2vec model
model = Word2Vec.load(args.input)
vocab = model.wv.vocab

# Load the orgs for the axis, should just be a file containing
# the org code and the type, where type should be no more than
# two unique arguments
axis = pd.read_csv(args.axis)

# Get the unique variables from the 'type' column
pole1, pole2 = list(set(axis['type']))

pole1_orgs = [str(org) for org in axis[axis.type == pole1]['cwts_org_no']]
pole2_orgs = [str(org) for org in axis[axis.type == pole2]['cwts_org_no']]

pole1_avg = get_avg_vec_from_list(model, pole1_orgs)
pole2_avg = get_avg_vec_from_list(model, pole2_orgs)

orgs = []
sims = []
for org in vocab:
    orgs.append(org)
    sims.append(project_onto_axis(model, org, [pole1_avg, pole2_avg]))

# Convert to dataframe and save
df = pd.DataFrame({"cwts_org_no": orgs, "sim": sims})
df.to_csv(args.output, index = False)
