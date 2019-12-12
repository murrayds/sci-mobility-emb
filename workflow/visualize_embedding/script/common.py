import logging
import umap
import pickle

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")


def get_and_save_umap_coordinate(
    embedding_list,
    entity_list,
    n_neighbor,
    min_dist,
    out_file_path=None,
):
    umap_result = umap.UMAP(
        n_neighbors=n_neighbor, min_dist=min_dist, metric="cosine"
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
    ]
    return c_list

