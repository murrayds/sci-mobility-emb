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
    INPUT_SIMPLIFITED_ORGS_FILE,
    INPUT_SIZE_FILE,
    FONT_PATH,
    OUTPUT_FILE,
):
    umap_result = pickle.load(open(INPUT_UMAP_COORD_FILE, "rb"))
    institute_list = np.array(list(umap_result.keys()))
    umap_coords = np.array([umap_result[inst] for inst in institute_list])

    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")
    code_to_org_type = meta_info["org_type"].to_dict()

    simple_orgs_file = pd.read_csv(INPUT_SIMPLIFITED_ORGS_FILE)
    simple_orgs_file = simple_orgs_file.set_index("org_type")
    orgs_to_simple_orgs = simple_orgs_file["org_type_simplified"].to_dict()
    orgs_list = np.array(
        [orgs_to_simple_orgs[code_to_org_type[int(inst)]] for inst in institute_list]
    )

    size_data = pd.read_csv(INPUT_SIZE_FILE, sep="\t", dtype={"cwts_org_no": str})
    size_data = size_data.drop(size_data.index[len(size_data) - 1])
    size_data.person_count = size_data.person_count.astype(int)
    mean_size_dict = (
        size_data.groupby("cwts_org_no")["person_count"].apply(np.mean).to_dict()
    )
    size_list = np.array([mean_size_dict[inst] for inst in institute_list])

    rcParams["figure.figsize"] = 20, 18
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=28)
        large_prop = font_manager.FontProperties(fname=FONT_PATH, size=40)
    else:
        prop = font_manager.FontProperties(size=28)
        large_prop = font_manager.FontProperties(size=40)
    awesome_c_list = get_awesome_c_list()
    color_dict = {"Institute": 0, "Hospital": 3, "University": 4, "Teaching": 7}
    c_list = [awesome_c_list[color_dict[row]] for row in orgs_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.1) for size in size_list])

    plt.scatter(
        umap_coords[:, 0],
        umap_coords[:, 1],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.4,
        edgecolor="white",
    )

    plt.text(1.3, 3.8, "Pittsburgh", c="black", fontproperties=large_prop)
    plt.text(2.4, 1.5, "Philadelphia", c="black", fontproperties=large_prop)

    ## Univ annoate
    c = awesome_c_list[4]
    plt.text(1.08, 4.6, "CMU", c=c, fontproperties=prop)
    plt.text(5.08, 0.8, "UPenn", c=c, fontproperties=prop)
    plt.text(3.65, 0.88, "Villanova", c=c, fontproperties=prop)
    plt.text(2.82, -1.35, "Lehigh", c=c, fontproperties=prop)
    plt.text(3, -2.7, "Pennsylvania\nState System", c=c, fontproperties=prop)
    plt.text(1.35, 5.05, "Pittsburgh", c=c, fontproperties=prop)
    plt.text(2.78, 2.45, "Drexel", c=c, fontproperties=prop)
    plt.text(4.17, 2.8, "Temple", c=c, fontproperties=prop)
    plt.text(2.2, 4.6, "Duquesne", c=c, fontproperties=prop)
    plt.text(1.23, 0.9, "Thomas\nJefferson", c=c, fontproperties=prop)

    ## Hospital annoate
    c = awesome_c_list[3]
    plt.text(4.7, 0.84, "UPenn\nHealth\nSystem", c=c, fontproperties=prop)
    plt.text(0.88, 2.1, "Thomas Jefferson\nU. Hospital", c=c, fontproperties=prop)
    plt.text(
        2.3,
        -3.3,
        "Penn State Health Milton\nS. Hershey Medical Center",
        c=c,
        fontproperties=prop,
    )
    plt.text(1.4, 5.6, "U.Pittsburgh\nMedical Center", c=c, fontproperties=prop)
    plt.text(1.5, 4.2, "UPMC Presbyterian", c=c, fontproperties=prop)

    ## Inst annoate
    c = awesome_c_list[0]
    plt.text(3.85, 3.3, "Fox Chase\nCancer Center", c=c, fontproperties=prop)
    plt.text(2, 4.9, "National Energy\nTechnology Laboratory", c=c, fontproperties=prop)
    plt.text(
        3.75,
        -2.75,
        "The Sigfried and\nJanet Weis\nCenter for Research",
        c=c,
        fontproperties=prop,
    )
    plt.text(4.4, 1.7, "Wistar\nInstitute", c=c, fontproperties=prop)

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
    handles = [lp(k) for k in ["Institute", "Hospital", "University", "Teaching"]]
    plt.legend(handles=handles, bbox_to_anchor=(1.06, 0.15), prop=prop, frameon=False)
    plt.savefig(OUTPUT_FILE, bbox_inches="tight")


if __name__ == "__main__":
    INPUT_UMAP_COORD_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    INPUT_SIMPLIFITED_ORGS_FILE = sys.argv[3]
    INPUT_SIZE_FILE = sys.argv[4]
    FONT_PATH = sys.argv[5] if sys.argv[5] != "None" else None
    OUTPUT_FILE = sys.argv[6]

    draw_figure(
        INPUT_UMAP_COORD_FILE,
        INPUT_META_INFO_FILE,
        INPUT_SIMPLIFITED_ORGS_FILE,
        INPUT_SIZE_FILE,
        FONT_PATH,
        OUTPUT_FILE,
    )
