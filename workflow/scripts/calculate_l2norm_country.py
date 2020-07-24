"""

calculate_l2norm_country.py

author: Dakota Murray

Calculate the l2 norm using the aggregate vector of a
country's organizations

"""

from gensim.models import Word2Vec
import pandas as pd
import numpy as np

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("--model", help = "the gensim word2vec model to decompose",
                    type = str, required = True)
parser.add_argument("--lookup", help = "Path to the organization lookup file")
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load the word2vec model
model = Word2Vec.load(args.model)

meta = pd.read_csv(args.lookup, sep = "\t")

# pre-process the metadata file
meta = meta.fillna(-1)
meta = meta.astype({'cwts_org_no': int})
meta = meta.astype({'cwts_org_no': str})

# Limit the metadata to orgs that are actually in the w2v model vocabulary
vocab = list(model.wv.vocab.keys())
meta = meta.loc[meta.cwts_org_no.isin(vocab)]


l2_vals = []
counts = []
countries = list(set(meta.country_iso_alpha))

# Iterate over countries, calculate mean vector of orgs, and calculate norm
for country in countries:
    # Get all the orgs per country
    orgs = list(meta.loc[meta.country_iso_alpha == country]['cwts_org_no'])
    # Get the mean vector
    mu_vec = np.array([model.wv[x] for x in orgs]).mean(axis = 0)

    l2_vals.append(np.linalg.norm(mu_vec))
    counts.append(len(orgs))

# Build the dataframe
df = pd.DataFrame({
    'country': countries,
    'l2norm': l2_vals,
    'count': counts,
})

# Write the output
df.to_csv(args.output, index = False)
