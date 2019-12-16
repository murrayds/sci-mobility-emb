import sys
import pickle
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
from pylab import rcParams
from common import get_awesome_c_list


def draw_figure(
    INPUT_UMAP_COORD_FILE,
    INPUT_META_INFO_FILE,
    INPUT_SIZE_FILE,
    FONT_PATH,
    OUTPUT_FILE,
):
    umap_result = pickle.load(open(INPUT_UMAP_COORD_FILE, "rb"))
    institute_list = np.array(list(umap_result.keys()))
    umap_coords = np.array([umap_result[inst] for inst in institute_list])

    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")
    code_to_country = meta_info["country_iso_name"].to_dict()
    country_list = np.array([code_to_country[int(inst)] for inst in institute_list])

    size_data = pd.read_csv(INPUT_SIZE_FILE, sep="\t", dtype={"cwts_org_no": str})
    size_data = size_data.drop(size_data.index[len(size_data) - 1])
    size_data.person_count = size_data.person_count.astype(int)
    mean_size_dict = (
        size_data.groupby("cwts_org_no")["person_count"].apply(np.mean).to_dict()
    )
    size_list = np.array([mean_size_dict[inst] for inst in institute_list])

    # plot config
    rcParams["figure.figsize"] = 10, 9
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=22)
    else:
        prop = font_manager.FontProperties(size=22)

    # color by continent
    awesome_c_list = get_awesome_c_list()
    color_by_category = [3, 8, 13]
    color_dict = {
        "Saudi Arabia": color_by_category[0],
        "Egypt": color_by_category[0],
        "Oman": color_by_category[0],
        "Jordan": color_by_category[0],
        "Iraq": color_by_category[0],
        "Qatar": color_by_category[0],
        "Oman": color_by_category[0],
        "United Arab Emirates": color_by_category[0],
        "Palestine, State of": color_by_category[0],
        "Indonesia": color_by_category[1],
        "Thailand": color_by_category[1],
        "Viet Nam": color_by_category[1],
        "Malaysia": color_by_category[1],
        "Philippines": color_by_category[1],
        "Pakistan": color_by_category[2],
        "Bangladesh": color_by_category[2],
        "Sri Lanka": color_by_category[2],
    }
    color_by_category_dict = {
        "Western Asia": color_by_category[0],
        "Southeast Asia": color_by_category[1],
        "South Asia": color_by_category[2],
    }
    c_list = [awesome_c_list[color_dict[row]] for row in country_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.3) for size in size_list])

    # draw figure
    plt.scatter(
        umap_coords[:, 0],
        umap_coords[:, 1],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

    ## Western Asia annotate
    c = awesome_c_list[color_by_category[0]]
    plt.text(7.8, 3.8, "Egypt", c=c, fontproperties=prop)
    plt.text(6.6, 1.2, "Omen", c=c, fontproperties=prop)
    plt.text(4.5, 3.8, "Jordan", c=c, fontproperties=prop)
    plt.text(4.4, 2.2, "Qatar", c=c, fontproperties=prop)
    plt.text(6.8, 1.9, "Saudi Arabia", c=c, fontproperties=prop)
    plt.text(5.6, 0.7, "Iraq, Palestine", c=c, fontproperties=prop)
    plt.text(4.4, 3.1, "U.A.E", c=c, fontproperties=prop)

    c = awesome_c_list[color_by_category[1]]
    plt.text(6.5, -4, "Thailand", c=c, fontproperties=prop)
    plt.text(3.6, -3.2, "Philippines", c=c, fontproperties=prop)
    plt.text(1.2, -1.8, "Vietnam", c=c, fontproperties=prop)
    plt.text(4.3, -1.6, "Indonesia", c=c, fontproperties=prop)
    plt.text(5.7, 0, "Malaysia", c=c, fontproperties=prop)

    c = awesome_c_list[color_by_category[2]]
    plt.text(7.4, -1.2, "Sri Lanka", c=c, fontproperties=prop)
    plt.text(2.3, -0.4, "Bangladesh", c=c, fontproperties=prop)
    plt.text(2.5, 1.1, "Pakistan", c=c, fontproperties=prop)

    plt.axis("off")
    lp = lambda i: plt.plot(
        [],
        color=awesome_c_list[color_by_category_dict[i]],
        ms=10,
        mec="none",
        label=i,
        ls="",
        marker="o",
    )[0]
    handles = [lp(k) for k in list(color_by_category_dict.keys())]
    plt.legend(handles=handles, bbox_to_anchor=(0.33, 0.22), prop=prop, frameon=False)
    plt.savefig(OUTPUT_FILE, bbox_inches="tight")


if __name__ == "__main__":
    INPUT_UMAP_COORD_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    INPUT_SIZE_FILE = sys.argv[3]
    FONT_PATH = sys.argv[4] if sys.argv[4] != "None" else None
    OUTPUT_FILE = sys.argv[5]

    draw_figure(
        INPUT_UMAP_COORD_FILE,
        INPUT_META_INFO_FILE,
        INPUT_SIZE_FILE,
        FONT_PATH,
        OUTPUT_FILE,
    )
