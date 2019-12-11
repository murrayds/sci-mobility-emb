import sys
import pickle
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
from pylab import rcParams

awesome_c_list = [
    "#607D8B",
    "#9E9E9E",
    "#795548",
    "#FF5722",
    "#FF9800",
    "#FFC107",
    "#FFEB3B",
    "#CDDC39",
    "#8BC34A",
    "#4CAF50",
    "#009688",
    "#00BCD4",
    "#03A9F4",
    "#2196F3",
    "#3F51B5",
    "#673AB7",
    "#9C27B0",
    "#E91E63",
    "#F44336",
]


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
    size_data = size_data.drop(size_data.index[len(size_data) - 1])
    size_data.person_count = size_data.person_count.astype(int)
    mean_size_dict = (
        size_data.groupby("cwts_org_no")["person_count"].apply(np.mean).to_dict()
    )
    size_list = np.array([mean_size_dict[inst] for inst in institute_list])

    rcParams["figure.figsize"] = 20, 18
    if FONT_PATH:
        prop = font_manager.FontProperties(fname=FONT_PATH, size=22)
    else:
        prop = font_manager.FontProperties(size=22)

    color_dict = {"west": 5, "pacific": 8, "midwest": 0, "northeast": 2, "south": 3}
    c_list = [awesome_c_list[color_dict[row]] for row in census_division_list]
    argumented_size_list = np.array([np.log(size) / np.log(1.3) for size in size_list])

    plt.scatter(
        umap_coords[:, 0],
        umap_coords[:, 1],
        s=argumented_size_list * 1.5,
        c=c_list,
        linewidth=0.3,
        edgecolor="white",
    )

    ## NorthEast annotate
    c = awesome_c_list[2]
    plt.text(6.5, -1.0, "New York", c=c, fontproperties=prop)
    plt.text(3.5, 0.4, "New Jersey", c=c, fontproperties=prop)
    plt.text(3, -0.9, "Pennsylvania", c=c, fontproperties=prop)
    plt.text(-7.3, -3, "Pennsylvania,\nPittsburgh", c=c, fontproperties=prop)
    plt.text(1.5, 4.2, "Massachusetts ", c=c, fontproperties=prop)
    plt.text(2.4, 3.1, "Rhode Island", c=c, fontproperties=prop)
    plt.text(1.85, 1.55, "Connecticut", c=c, fontproperties=prop)

    # South annotate
    c = awesome_c_list[3]
    plt.text(-1, -5.3, "Texas", c=c, fontproperties=prop)
    plt.text(-6.5, -1, "Maryland", c=c, fontproperties=prop)
    plt.text(-4.7, -0.6, "North Carolina", c=c, fontproperties=prop)
    plt.text(-0.7, -0.6, "Florida", c=c, fontproperties=prop)
    plt.text(-3.2, -9, "Flordia", c=c, fontproperties=prop)
    plt.text(-1.4, -2.95, "Georgia", c=c, fontproperties=prop)
    plt.text(1.6, 0.2, "Virginia", c=c, fontproperties=prop)

    # West annotate
    c = awesome_c_list[5]
    plt.text(0.1, 5.4, "New Mexico", c=c, fontproperties=prop)
    plt.text(-6, 4.8, "California", c=c, fontproperties=prop)
    plt.text(-1.3, 5.9, "Arizona", c=c, fontproperties=prop)
    plt.text(-8, 1.8, "Washington", c=c, fontproperties=prop)
    plt.text(-3.7, 1.1, "Colrado", c=c, fontproperties=prop)

    # Midwest annotate
    c = awesome_c_list[0]
    plt.text(-4.5, -4.5, "Michigan", c=c, fontproperties=prop)
    plt.text(-2.5, -6.5, "Indiana", c=c, fontproperties=prop)
    plt.text(-4.5, -2.7, "Illinois", c=c, fontproperties=prop)
    plt.text(-5.2, -7.4, "Ohio", c=c, fontproperties=prop)
    plt.text(1.9, -2.5, "Nebraska", c=c, fontproperties=prop)
    plt.text(0.6, -2.8, "Missouri", c=c, fontproperties=prop)
    plt.text(0.1, -0.11, "Wisconsin", c=c, fontproperties=prop)
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
    plt.legend(handles=handles, bbox_to_anchor=(1, 0.22), prop=prop, frameon=False)
    plt.savefig(OUTPUT_FILE, bbox_inches="tight")
    plt.show()


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
