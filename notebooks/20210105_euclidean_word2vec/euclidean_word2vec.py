import numpy as np
from scipy import sparse
from sklearn.manifold import MDS


def embedding(T, dim, min_flow_rate = 0.1):

    # Calculate the stationary distribution
    pi = np.array(np.sum(T, axis = 0)).reshape(-1)
    m = np.sum(pi)
    
    # Expecte flow under no positional info
    ET = np.outer(pi, pi) / m

    # Add minimum flow
    T = ( 1- min_flow_rate) * T + min_flow_rate * ET 

    # calculate the stationary distribution
    D = - np.log(T / np.outer(pi, pi))
    D = D - np.diag(np.diag(D))
    
    # MDS algorithm
    emb = MDS(n_components=dim, dissimilarity="precomputed").fit_transform(D)
    
    return emb
    