import sys
import logging
import pandas as pd
import numpy as np
import umap
import pickle
from gensim.models import Word2Vec

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")


def get_umap_coordinate(
    INPUT_EMBEDDING_FILE,
    INPUT_META_INFO_FILE,
    LEVEL,
    TARGET,
    N_NEIGHBOR,
    MIN_DIST,
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
        target_list = TARGET.split(",")
        print(target_list)
        print(country_list)
        institute_list = institute_list[np.isin(country_list, target_list)]

    elif LEVEL == "region":
        code_to_region = meta_info["region"].to_dict()
        region_list = np.array([code_to_region[int(inst)] for inst in institute_list])
        TARGET = TARGET.replace("_", " ")
        print(TARGET)
        target_list = TARGET.split(",")
        print(target_list)
        institute_list = institute_list[np.isin(region_list, target_list)]

    embedding_list = np.array([model.wv[x] for x in institute_list])
    umap_result = umap.UMAP(
        n_neighbors=N_NEIGHBOR, min_dist=MIN_DIST, metric="cosine"
    ).fit_transform(embedding_list)

    umap_result_dict = {inst: umap for inst, umap in zip(institute_list, umap_result)}
    pickle.dump(umap_result_dict, open(OUTPUT_FILE, "wb"))


if __name__ == "__main__":
    INPUT_EMBEDDING_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    LEVEL = sys.argv[3]
    TARGET = sys.argv[4]
    N_NEIGHBOR = int(sys.argv[5])
    MIN_DIST = float(sys.argv[6])
    OUTPUT_FILE = sys.argv[7]

    get_umap_coordinate(
        INPUT_EMBEDDING_FILE,
        INPUT_META_INFO_FILE,
        LEVEL,
        TARGET,
        N_NEIGHBOR,
        MIN_DIST,
        OUTPUT_FILE,
    )
