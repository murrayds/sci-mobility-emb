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

    plt.text(-1.9, 5.5, "Houston", c="black", fontproperties=large_prop)
    plt.text(-2.9, 1.9, "Austin", c="black", fontproperties=large_prop)
    plt.text(-2.3, 0.1, "Dallas", c="black", fontproperties=large_prop)

    ## Univ annoate
    c = awesome_c_list[4]
    plt.text(-1.78, 4.3, "Rice", c=c, fontproperties=prop)
    plt.text(-2.65, 2.3, "UT Austin", c=c, fontproperties=prop)
    plt.text(-2.25, 1.3, "Southern\nMethodist", c=c, fontproperties=prop)
    plt.text(-3.4, -5.7, "Texas A&M System", c=c, fontproperties=prop)
    plt.text(-2.95, -3.65, "Baylor", c=c, fontproperties=prop)
    plt.text(-2.3, -1.9, "Texas\nChristian", c=c, fontproperties=prop)
    plt.text(-2.78, 1.1, "UT Dallas", c=c, fontproperties=prop)
    plt.text(-2.5, 5.5, "U.Houston", c=c, fontproperties=prop)
    plt.text(-0.6, 0, "UT System", c=c, fontproperties=prop)
    plt.text(-3.75, -2.4, "Texas Tech", c=c, fontproperties=prop)
    plt.text(-3.1, -0.8, "U.North Texas", c=c, fontproperties=prop)
    plt.text(-2.9, 3.6, "UT Health", c=c, fontproperties=prop)

    ## Hospital annoate
    c = awesome_c_list[3]
    plt.text(-0.7, 5, "Methodist\nHospital,\nHouston", c=c, fontproperties=prop)
    plt.text(-2.75, -4.3, "Baylor Scott and\nWhite Health", c=c, fontproperties=prop)
    plt.text(
        -2.15,
        2.8,
        "Memorial\nHermann-\nTexas\nMedical Center",
        c=c,
        fontproperties=prop,
    )
    plt.text(-0.9, 4.5, "Texas Children's Hospital", c=c, fontproperties=prop)
    plt.text(-1.5, 3.8, "Baylor St. Luke's\nMedical Center", c=c, fontproperties=prop)

    ## Inst annoate
    c = awesome_c_list[0]
    plt.text(-2.85, 4.3, "M.D. Anderson\nCancer Center", c=c, fontproperties=prop)
    plt.text(-0.7, 1.82, "Southwest Research\nInstitute", c=c, fontproperties=prop)
    plt.text(
        -1.85, 2.2, "US Army Institute\nof Surgircal Research", c=c, fontproperties=prop
    )
    plt.text(-3.9, -4.2, "Texas AgriLife", c=c, fontproperties=prop)

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
    handles = [lp(k) for k in ["Institute", "Hospital", "University",]]
    plt.legend(handles=handles, bbox_to_anchor=(1.09, 0.15), prop=prop, frameon=False)
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
