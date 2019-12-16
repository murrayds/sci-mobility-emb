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
    rcParams["figure.figsize"] = 10,9
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=22)
    else:
        prop = font_manager.FontProperties(size=22)

    # color by continent
    awesome_c_list = get_awesome_c_list()
    color_dict ={'Peru': 3,
             'Uruguay': 3,
             'Argentina': 3,
             'Mexico': 3,
             'Chile': 3,
             'Brazil': 13,
             'Portugal': 13,
             'Colombia': 3,
            'Spain': 3}
    c_list = [awesome_c_list[color_dict[row]] for row in country_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.3) for size in size_list])

    # draw figure
    plt.scatter(
        umap_coords[:, 1],
        umap_coords[:, 0],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

     ## NA annoate
    c = awesome_c_list[13]
    plt.text(0.5, 10, "Brazil", c=c, fontproperties=prop)
    plt.text(8.5, 9, "Portugal", c=c, fontproperties=prop)

    c = awesome_c_list[3]
    plt.text(-15, 4.6, "Mexico", c=c, fontproperties=prop)
    plt.text(5.8, -11, "Argentina", c=c, fontproperties=prop)
    plt.text(-1.2, -4.5, "Spain", c=c, fontproperties=prop)
    plt.text(-8, 2.6, "Chile", c=c, fontproperties=prop)
    plt.text(-4.5, 4.7, "Colombia", c=c, fontproperties=prop)
    plt.text(1, 4.7, "Peru", c=c, fontproperties=prop)
    plt.annotate(
            "",
            xy=(1, 4.7),
            xytext=(0, 3.5),
            arrowprops=dict(arrowstyle="-", color=c, lw=2),
        )
    plt.text(3, -3, "Uruguay", c=c, fontproperties=prop)
    plt.annotate(
            "",
            xy=(3, -3),
            xytext=(0.3, -2.9),
            arrowprops=dict(arrowstyle="-", color=c, lw=2),
        )
    plt.axis('off')

    speaking_language_label_dict = {'Portugal': 'Portuguese speaking countries', 'Spain': 'Spanish speaking countries'}
    lp = lambda i: plt.plot([],color=awesome_c_list[color_dict[i]], ms=10, mec="none",
                            label=speaking_language_label_dict[i], ls="", marker="o")[0]
    handles = [lp(k) for k in ['Portugal', 'Spain']]
    plt.legend(handles=handles, bbox_to_anchor=(0.7,0.18), prop=prop, frameon=False)
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
