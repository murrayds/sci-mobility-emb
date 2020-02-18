"""
SemAxis utils

Adapted from the SemAxis approach authored by Jisun An, Haewoon Kwak,
and Yong-Yeol Ahn at the following repository:

https://github.com/ghdi6758/SemAxis

"""
import numpy as np
from gensim.models import Word2Vec
from scipy import spatial

# Functions should be offloaded to a package at a later date,
def get_avg_vec_from_list(emb, wordlist):
    """Calculate the average vector in a word2vec embedding model
       from the provided list of terms

    arguments:
    emb -- Word2vec embedding model
    wordlist -- The list of terms in the model
    """
    tmp = [emb.wv[word] for word in wordlist if word in emb.wv.vocab]
    return np.mean(tmp, axis=0)

def project_onto_axis(emb, word, antonym):
    """Project word in model onto the defined antonym axis

    arguments:
    emb -- Word2vec embedding model
    word -- The term to project onto the antonym axis
    antonym -- List of two vectors to be used as the poles of the antonym axis
    """
    axis = antonym[1] - antonym[0]
    return(1.0 - spatial.distance.cosine(emb.wv[word], axis))
