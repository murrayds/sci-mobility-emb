import pickle
import sys

import matplotlib.font_manager as font_manager
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pylab import rcParams

from py_scimobility.core import get_awesome_c_list


def draw_figure(
    INPUT_UMAP_COORD_FILE,
    INPUT_META_INFO_FILE,
    INPUT_STATE_TO_REGION,
    INPUT_SIZE_FILE,
    FONT_PATH,
    OUTPUT_FILE,
):
    umap_result = pickle.load(open(INPUT_UMAP_COORD_FILE, "rb"))
    institute_list = np.array(list(umap_result.keys()))
    umap_coords = np.array([umap_result[inst] for inst in institute_list])

    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")
    code_to_city = meta_info["city"].to_dict()
    code_to_state = meta_info["region"].to_dict()

    states_to_region = pd.read_csv(INPUT_STATE_TO_REGION)
    states_to_region = states_to_region.set_index("region")
    states_to_census_division = states_to_region["census_division"].to_dict()
    census_division_list = np.array(
        [states_to_census_division[code_to_state[int(inst)]] for inst in institute_list]
    )

    size_data = pd.read_csv(INPUT_SIZE_FILE, sep="\t", dtype={"cwts_org_no": str})
    size_dict = size_data.set_index('cwts_org_no')['size'].to_dict()
    size_list = np.array([size_dict[inst] for inst in institute_list])

    rcParams["figure.figsize"] = 20, 18
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=28)
    else:
        prop = font_manager.FontProperties(size=28)

    awesome_c_list = get_awesome_c_list()
    color_dict = {"west": 4, "pacific": 8, "midwest": 0, "northeast": 2, "south": 3}
    c_list = [awesome_c_list[color_dict[row]] for row in census_division_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.3) for size in size_list])

    plt.scatter(
        umap_coords[:, 1],
        umap_coords[:, 0],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

    plt.axis("off")

    lp = lambda i: plt.plot(
        [],
        color=awesome_c_list[color_dict[i]],
        ms=10,
        mec="none",
        label=i[0].upper() + i[1:],
        ls="",
        marker="o",
    )[0]
    handles = [lp(k) for k in ["west", "south", "midwest", "northeast", "pacific"]]
    plt.legend(handles=handles, bbox_to_anchor=(0.9, 0.23), prop=prop, frameon=False)
    plt.savefig(OUTPUT_FILE, bbox_inches="tight")


if __name__ == "__main__":
    INPUT_UMAP_COORD_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    INPUT_STATE_TO_REGION = sys.argv[3]
    INPUT_SIZE_FILE = sys.argv[4]
    FONT_PATH = sys.argv[5] if sys.argv[5] != "None" else None
    OUTPUT_FILE = sys.argv[6]

    draw_figure(
        INPUT_UMAP_COORD_FILE,
        INPUT_META_INFO_FILE,
        INPUT_STATE_TO_REGION,
        INPUT_SIZE_FILE,
        FONT_PATH,
        OUTPUT_FILE,
    )
