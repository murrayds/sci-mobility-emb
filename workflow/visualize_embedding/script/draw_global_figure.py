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
    size_data = size_data.drop(size_data.index[len(size_data) - 1])
    size_data.person_count = size_data.person_count.astype(int)
    mean_size_dict = (
        size_data.groupby("cwts_org_no")["person_count"].apply(np.mean).to_dict()
    )
    size_list = np.array([mean_size_dict[inst] for inst in institute_list])

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
        umap_coords[:, 1],
        -umap_coords[:, 0],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

    ## NA annoate
    c = awesome_c_list[0]
    plt.text(-8.2, -8.2, "U.S.A.", c=c, fontproperties=prop)
    plt.text(-7.8, 2.5, "Canada", c=c, fontproperties=prop)
    plt.text(2, -14, "Mexico", c=c, fontproperties=prop)

    ## Asia annotate
    c = awesome_c_list[3]
    plt.text(-13.2, 3.5, "China", c=c, fontproperties=prop)
    plt.text(-2, 10.9, "Japan", c=c, fontproperties=prop)
    plt.text(-3.5, 8.7, "S.Korea", c=c, fontproperties=prop)
    plt.text(-8, -1, "Singapore", c=c, fontproperties=prop)
    plt.text(-6, 7, "India", c=c, fontproperties=prop)
    plt.text(-14.5, -3.5, "Israel", c=c, fontproperties=prop)
    plt.text(-7, 9.2, "Taiwan", c=c, fontproperties=prop)
    plt.text(-2.7, 7.2, "Viet Nam", c=c, fontproperties=prop)
    plt.text(-3.8, 1.5, "Iran", c=c, fontproperties=prop)

    ## Europe annotate
    c = awesome_c_list[2]
    plt.text(6.8, -6.5, "France", c=c, fontproperties=prop)
    plt.text(0.5, -0.5, "U.K.", c=c, fontproperties=prop)
    plt.text(-0.8, -7.5, "Norway", c=c, fontproperties=prop)
    plt.text(-0.2, -5.5, "Sweden", c=c, fontproperties=prop)
    plt.text(13, 2.8, "Italy", c=c, fontproperties=prop)
    plt.text(3, -11.5, "Spain", c=c, fontproperties=prop)
    plt.text(6.8, 6.0, "Netherlands", c=c, fontproperties=prop)
    plt.text(1.9, 3.2, "Germany", c=c, fontproperties=prop)
    plt.text(7.6, 0.3, "Austria", c=c, fontproperties=prop)
    plt.text(12.5, -3.8, "Romania", c=c, fontproperties=prop)
    plt.text(12, -6.3, "Poland", c=c, fontproperties=prop)
    plt.text(13.8, -0.3, "Greece", c=c, fontproperties=prop)
    plt.text(1, 6.5, "Russia", c=c, fontproperties=prop)
    plt.text(5.5, -15, "Portugal", c=c, fontproperties=prop)
    plt.text(7.5, -3, "Belgium", c=c, fontproperties=prop)
    plt.text(7, 3.4, "Switzerland", c=c, fontproperties=prop)
    plt.text(6.4, 8.8, "Finland", c=c, fontproperties=prop)
    plt.text(10, 5.3, "Hungary", c=c, fontproperties=prop)
    plt.text(10.6, 1, "Czechia", c=c, fontproperties=prop)
    plt.text(8.2, -1.0, "Slovakia", c=c, fontproperties=prop)
    plt.text(-5.8, 0.8, "Turkey", c=c, fontproperties=prop)
    plt.text(3.0, 7.6, "Ukraine", c=c, fontproperties=prop)

    ## Africa annotate
    c = awesome_c_list[8]
    plt.text(2, -8, "Algeria,\nMorocco", c=c, fontproperties=prop)
    plt.annotate(
        "",
        xy=(3, -6.5),
        xytext=(3.5, -4.5),
        arrowprops=dict(arrowstyle="-", color=c, lw=2),
    )

    ## SA annotate
    c = awesome_c_list[5]
    plt.text(-1.8, -16.9, "Brazil", c=c, fontproperties=prop)
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
    plt.legend(handles=handles, bbox_to_anchor=(0.85, 0.24), prop=prop, frameon=False)
    
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
