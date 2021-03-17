import logging
import pickle
import sys

import numpy as np
import pandas as pd
import umap
from gensim.models import Word2Vec

from py_scimobility.core import get_and_save_umap_coordinate

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")


def get_umap_coordinate_by_level(
    INPUT_EMBEDDING_FILE,
    INPUT_META_INFO_FILE,
    LEVEL,
    TARGET,
    N_NEIGHBOR,
    MIN_DIST,
    RANDOM_SEED,
    OUTPUT_FILE,
):

    model = Word2Vec.load(INPUT_EMBEDDING_FILE)
    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")

    institute_list = np.array(list(model.wv.vocab.keys()))

    if LEVEL == "global":
        pass

    elif LEVEL == "nation":
        code_to_country = meta_info["country_iso_name"].to_dict()
        country_list = np.array([code_to_country[int(inst)] for inst in institute_list])
        TARGET = TARGET.replace("_", " ")
        target_list = TARGET.split("-")
        institute_list = institute_list[np.isin(country_list, target_list)]

    elif LEVEL == "region":
        code_to_region = meta_info["region"].to_dict()
        region_list = np.array([code_to_region[int(inst)] for inst in institute_list])
        TARGET = TARGET.replace("_", " ")
        target_list = TARGET.split("-")
        institute_list = institute_list[np.isin(region_list, target_list)]

    embedding_list = np.array([model.wv[x] for x in institute_list])
    get_and_save_umap_coordinate(
        embedding_list,
        institute_list,
        n_neighbor=N_NEIGHBOR,
        min_dist=MIN_DIST,
        random_state=RANDOM_SEED,
        out_file_path=OUTPUT_FILE,
    )


if __name__ == "__main__":
    INPUT_EMBEDDING_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    LEVEL = sys.argv[3]
    TARGET = sys.argv[4]
    N_NEIGHBOR = int(sys.argv[5])
    MIN_DIST = float(sys.argv[6])
    RANDOM_SEED = int(sys.argv[7])
    OUTPUT_FILE = sys.argv[8]

    get_umap_coordinate_by_level(
        INPUT_EMBEDDING_FILE,
        INPUT_META_INFO_FILE,
        LEVEL,
        TARGET,
        N_NEIGHBOR,
        MIN_DIST,
        RANDOM_SEED,
        OUTPUT_FILE,
    )
