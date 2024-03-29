""" core utils for the project """
import os
import logging
import umap
import pickle
import numpy as np

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")

from geopy.distance import great_circle


def compute_geo_distance(u, v):
    """Compute geographic distance (great circle), between two
       sets of coordinates. Outputs NaN when any distnace is NaN

    arguments:
    u -- First coordinate, list in form [<lat>, <lon>]
    v -- Second coordinate, list in form [<lat>, <lon>]
    """
    if np.isnan([u[0], u[1], v[0], v[1]]).any():
        return np.nan
    else:
        return great_circle(u, v).kilometers


def get_and_save_umap_coordinate(
    embedding_list,
    entity_list,
    n_neighbor=10,
    min_dist=0.1,
    random_state=None,
    out_file_path=None,
):
    umap_result = umap.UMAP(
        n_neighbors=n_neighbor, min_dist=min_dist, metric="cosine", random_state=random_state
    ).fit_transform(embedding_list)

    umap_result_dict = {entity: umap for entity, umap in zip(entity_list, umap_result)}

    if out_file_path:
        pickle.dump(umap_result_dict, open(out_file_path, "wb"))
        logging.info("Save umap result dict under {}".format(out_file_path))

    return umap_result_dict


def get_awesome_c_list():
    c_list = [
        "#607D8B",
        "#9E9E9E",
        "#795548",
        "#FF5722",
        "#FF9800",
        "#FFC107",
        "#FFEB3B",
        "#CDDC39",
        "#8BC34A",
        "#4CAF50",
        "#009688",
        "#00BCD4",
        "#03A9F4",
        "#2196F3",
        "#3F51B5",
        "#673AB7",
        "#9C27B0",
        "#E91E63",
        "#F44336",
        "#d3d3d3",
    ]
    return c_list
