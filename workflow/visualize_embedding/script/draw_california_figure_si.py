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
    # for missclassfied kavil foundation
    orgs_to_simple_orgs["Funding Organisation"] = "Institute"
    orgs_list = np.array(
        [orgs_to_simple_orgs[code_to_org_type[int(inst)]] for inst in institute_list]
    )

    size_data = pd.read_csv(INPUT_SIZE_FILE, sep="\t", dtype={"cwts_org_no": str})
    size_dict = size_data.set_index('cwts_org_no')['size'].to_dict()
    size_list = np.array([size_dict[inst] for inst in institute_list])

    rcParams["figure.figsize"] = 20, 18
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=28)
        large_prop = font_manager.FontProperties(fname=FONT_PATH, size=40)
    else:
        prop = font_manager.FontProperties(size=28)
        large_prop = font_manager.FontProperties(size=40)
    awesome_c_list = get_awesome_c_list()
    color_dict = {
        "Institute": 0,
        "Hospital": 3,
        "University": 4,
        "Teaching": 7,
        "Government": 9,
    }
    c_list = [awesome_c_list[color_dict[row]] for row in orgs_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.1) for size in size_list])

    plt.scatter(
        -umap_coords[:, 1],
        umap_coords[:, 0],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.4,
        edgecolor="white",
    )

#     plt.text(3, -3.7, "San Francisco\nBay Area", c="black", fontproperties=large_prop)
#     plt.text(-3, 0.6, "Los Angeles", c="black", fontproperties=large_prop)
#     plt.text(-4.6, -3.6, "San Diego", c="black", fontproperties=large_prop)

#     ## Univ annoa
#     c = awesome_c_list[4]
#     plt.text(-0.4, -5.1, "California State \nSystem", c=c, fontproperties=prop)
#     plt.text(0.65, -2.4, "Stanford", c=c, fontproperties=prop)
#     plt.text(-0.65, -1.85, "Caltech", c=c, fontproperties=prop)
#     plt.text(-2.85, -0.05, "UCLA", c=c, fontproperties=prop)
#     plt.text(1.9, -3.05, "UC Berkeley", c=c, fontproperties=prop)
#     plt.text(-3.55, -2.5, "UCSD", c=c, fontproperties=prop)
#     plt.text(-0.2, 0.5, "USC", c=c, fontproperties=prop)
#     plt.text(-1.35, -2.05, "UCSB", c=c, fontproperties=prop)
#     plt.text(-4.2, 0.03, "UC Irvine", c=c, fontproperties=prop)
#     plt.text(0, -2.9, "UC Davis", c=c, fontproperties=prop)
#     plt.text(3.6, -2.1, "UCSF", c=c, fontproperties=prop)

#     ## Hospital annoate
#     c = awesome_c_list[3]
#     plt.text(1.2, -2.8, "UC Davis\nMedical Center", c=c, fontproperties=prop)
#     plt.text(-3.1, -0.64, "UCLA\nHealth", c=c, fontproperties=prop)
#     plt.text(2.5, -2.4, "UCSF\nMedical\nCenter", c=c, fontproperties=prop)
#     plt.text(-1.95, -0.1, "Cedars-Sinai\nMedical Center", c=c, fontproperties=prop)
#     plt.text(1.6, -1.8, "Standford\nHealth Care", c=c, fontproperties=prop)
#     plt.text(-3.4, -3.3, "UCSD\nHealth", c=c, fontproperties=prop)

#     ## Inst annoate
#     c = awesome_c_list[0]
#     plt.text(-4.9, -2.55, "Scripps\nResearch\nInstitute", c=c, fontproperties=prop)
#     plt.text(
#         0.5, -3.8, "SLAC National\nAccelerator\nLaboratory", c=c, fontproperties=prop
#     )
#     plt.text(-2.2, -3.6, "Lockheed\nMartin\nATC", c=c, fontproperties=prop)
#     plt.text(0.4, 0.5, "City of Hope\nNational Cancer Center", c=c, fontproperties=prop)

    ## Goverment annoate
    c = awesome_c_list[9]

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
    plt.legend(handles=handles, bbox_to_anchor=(1.08, 0.21), prop=prop, frameon=False)
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
