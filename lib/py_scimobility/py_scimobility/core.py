""" core utils for the project """
import os
import numpy as np

from geopy.distance import great_circle


def compute_geo_distance(u, v):
    """Compute geographic distance (great circle), between two
       sets of coordinates. Outputs NaN when any distnace is NaN

    arguments:
    u -- First coordinate, list in form [<lat>, <lon>]
    v -- Second coordinate, list in form [<lat>, <lon>]
    """
    if np.isnan([u[0], u[1], v[0], v[1]]).any():
        return(np.nan)
    else:
        return(great_circle(u, v).kilometers)
