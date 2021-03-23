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
    INPUT_COUNTRY_TO_CONTI,
    INPUT_SIZE_FILE,
    FONT_PATH,
    OUTPUT_FILE,
):
    umap_result = pickle.load(open(INPUT_UMAP_COORD_FILE, "rb"))
    institute_list = np.array(list(umap_result.keys()))
    umap_coords = np.array([umap_result[inst] for inst in institute_list])

    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")
    code_to_country_iso = meta_info["country_iso_alpha"].to_dict()

    iso_to_country = pd.read_csv(INPUT_COUNTRY_TO_CONTI, sep="\t")
    iso_to_country = iso_to_country.set_index("Alpha_code_3")
    country_to_continent = iso_to_country["Continent_name"].to_dict()
    cont_list = np.array(
        [
            country_to_continent[code_to_country_iso[int(inst)]]
            for inst in institute_list
        ]
    )

    size_data = pd.read_csv(INPUT_SIZE_FILE, sep="\t", dtype={"cwts_org_no": str})
    size_dict = size_data.set_index('cwts_org_no')['size'].to_dict()
    size_list = np.array([size_dict[inst] for inst in institute_list])

    # plot config
    rcParams["figure.figsize"] = 20, 18
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=22)
    else:
        prop = font_manager.FontProperties(size=22)

    # color by continent
    awesome_c_list = get_awesome_c_list()
    color_dict = {
        "South America": 5,
        "Africa": 8,
        "Europe": 2,
        "Asia": 3,
        "Oceania": 4,
        "North America": 0,
    }
    c_list = [awesome_c_list[color_dict[row]] for row in cont_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.3) for size in size_list])

    # draw figure
    plt.scatter(
        -umap_coords[:, 1],
        -umap_coords[:, 0],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

#     ## NA annoate
#     c = awesome_c_list[0]
#     plt.text(-8.2, -6.5, "U.S.A.", c=c, fontproperties=prop)
#     plt.text(-4.8, 0.3, "Canada", c=c, fontproperties=prop)
#     plt.text(3, -6, "Canada,\nQuebec-\nMontreal", c=c, fontproperties=prop)
#     plt.text(-1.1, -10.5, "Mexico", c=c, fontproperties=prop)

#     ## Asia annotate
#     c = awesome_c_list[3]
#     plt.text(-12.2, 0.6, "China", c=c, fontproperties=prop)
#     plt.text(-0.1, 8.9, "Japan", c=c, fontproperties=prop)
#     plt.text(-5.2, 9.7, "S.Korea", c=c, fontproperties=prop)
#     plt.text(-8.1, 0.9, "Singapore", c=c, fontproperties=prop)
#     plt.text(-6.3, 6.2, "India", c=c, fontproperties=prop)
#     plt.text(-2, -8.2, "Israel", c=c, fontproperties=prop)
#     plt.text(-10.2, 6.9, "Taiwan", c=c, fontproperties=prop)
#     plt.text(-2.9, 6.4, "Vietnam", c=c, fontproperties=prop)
#     plt.text(-5.7, 13.8, "Iran", c=c, fontproperties=prop)
#     plt.text(-3.5, 11, "Thailand", c=c, fontproperties=prop)

#     ## Europe annotate
#     c = awesome_c_list[2]
#     plt.text(6.5, -6.5, "France", c=c, fontproperties=prop)
#     plt.text(0.5, -4.8, "U.K.", c=c, fontproperties=prop)
#     plt.text(-1.3, 1.3, "Norway", c=c, fontproperties=prop)
#     plt.text(0.6, 0.7, "Sweden", c=c, fontproperties=prop)
#     plt.text(12, 1.8, "Italy", c=c, fontproperties=prop)
#     plt.text(2.4, -10.8, "Spain", c=c, fontproperties=prop)
#     plt.text(0.2, 3.7, "Netherlands", c=c, fontproperties=prop)
#     plt.text(6, 4.2, "Germany", c=c, fontproperties=prop)
#     plt.text(4.8, 2.5, "Austria", c=c, fontproperties=prop)
#     plt.text(5.3, 12, "Romania", c=c, fontproperties=prop)
#     plt.text(9.1, 10.6, "Poland", c=c, fontproperties=prop)
#     plt.text(13, -4.8, "Greece", c=c, fontproperties=prop)
#     plt.text(3.5, 7.5, "Russia", c=c, fontproperties=prop)
#     plt.text(3, -13.5, "Portugal", c=c, fontproperties=prop)
#     plt.text(6.4, 0, "Belgium", c=c, fontproperties=prop)
#     plt.text(6.8, 1.9, "Switzerland", c=c, fontproperties=prop)
#     plt.text(3.1, 0.4, "Finland", c=c, fontproperties=prop)
#     plt.text(5.7, 9.8, "Hungary", c=c, fontproperties=prop)
#     plt.text(10.5, 4.8, "Czechia", c=c, fontproperties=prop)
#     plt.text(10.5, 6, "Slovakia", c=c, fontproperties=prop)
#     plt.text(3, 13.4, "Turkey", c=c, fontproperties=prop)
#     plt.text(7.0, 7.9, "Ukraine", c=c, fontproperties=prop)
#     plt.text(-4.5, 3.4, "Denmark", c=c, fontproperties=prop)
#     plt.text(10.2, 7.8, "Latvia", c=c, fontproperties=prop)
#     plt.text(10.6, 8.7, "Lithuania", c=c, fontproperties=prop)

#     ## Africa annotate
#     c = awesome_c_list[8]
#     plt.text(8, -2.1, "Algeria,\nMorocco", c=c, fontproperties=prop)

#     ## SA annotate
#     c = awesome_c_list[5]
#     plt.text(-2.8, -14.5, "Brazil", c=c, fontproperties=prop)

#     ## Oceneia annotate
#     c = awesome_c_list[4]
#     plt.text(-8.5, 3.2, "Austrailia", c=c, fontproperties=prop)
#     plt.text(-7, 5.3, "New Zealand", c=c, fontproperties=prop)
#     plt.annotate(
#         "",
#         xy=(-5.5, 5.2),
#         xytext=(-5, 4.5),
#         arrowprops=dict(arrowstyle="-", color=c, lw=2),
#     )

    plt.axis("off")

    # make a lengend
    lp = lambda i: plt.plot(
        [],
        color=awesome_c_list[color_dict[i]],
        ms=10,
        mec="none",
        label=i,
        ls="",
        marker="o",
    )[0]
    handles = [
        lp(k)
        for k in [
            "North America",
            "South America",
            "Europe",
            "Asia",
            "Oceania",
            "Africa",
        ]
    ]
    plt.legend(handles=handles, bbox_to_anchor=(0.2, 0.26), prop=prop, frameon=False)
    plt.savefig(OUTPUT_FILE, bbox_inches="tight")


if __name__ == "__main__":
    INPUT_UMAP_COORD_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    INPUT_COUNTRY_TO_CONTI = sys.argv[3]
    INPUT_SIZE_FILE = sys.argv[4]
    FONT_PATH = sys.argv[5] if sys.argv[5] != "None" else None
    OUTPUT_FILE = sys.argv[6]

    draw_figure(
        INPUT_UMAP_COORD_FILE,
        INPUT_META_INFO_FILE,
        INPUT_COUNTRY_TO_CONTI,
        INPUT_SIZE_FILE,
        FONT_PATH,
        OUTPUT_FILE,
    )
