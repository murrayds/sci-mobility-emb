import sys
from gensim.models import Word2Vec
import sklearn.metrics as mt
import scipy.spatial.distance as ssd
from scipy.cluster.hierarchy import (
    linkage,
    dendrogram,
    fcluster,
    set_link_color_palette,
)
from collections import Counter
import pandas as pd
import numpy as np
from clusim.clustering import Clustering
import clusim.sim as sim
from common import get_awesome_c_list


def draw_figure(
    INPUT_EMBEDDING_FILE,
    INPUT_META_INFO_FILE,
    COUNTRY_META_INFO_FILE,
    FONT_PATH,
    BOLD_FONT_PATH,
    DENDROGRAM_PART_PATH,
    HEATMAP_PART_PATH,
    CLUSIM_PART_PATH,
):
    model = Word2Vec.load(INPUT_EMBEDDING_FILE)
    print(BOLD_FONT_PATH)
    # Get institution meta data
    meta_info = pd.read_csv(INPUT_META_INFO_FILE, sep="\t")
    meta_info = meta_info.set_index("cwts_org_no")
    code_to_country = meta_info["country_iso_name"].to_dict()

    # Get country meta data
    country_meta_data = pd.read_csv(COUNTRY_META_INFO_FILE, sep=",")
    country_to_continent = country_meta_data.set_index("wos_country")[
        "continent"
    ].to_dict()
    country_to_language = country_meta_data.set_index("wos_country")[
        "language"
    ].to_dict()
    country_to_language_family = country_meta_data.set_index("wos_country")[
        "ethnologue_family"
    ].to_dict()

    # Get result vectors
    institute_list = np.array(list(model.wv.vocab.keys()))
    embedding_list = np.array([model.wv[x] for x in institute_list])
    country_list = np.array([code_to_country[int(inst)] for inst in institute_list])

    # Get representative vector, calculate pairwise similarity, and do hierarchical clustering.
    target_countries = [
        k for k, v in Counter(country_list).items() if v >= 25 and k != "United States"
    ]
    representative_vector = [
        embedding_list[country_list == country].mean(axis=0)
        for country in target_countries
    ]
    sim_mtx = mt.pairwise.cosine_similarity(representative_vector)
    for i in range(len(sim_mtx)):
        sim_mtx[i][i] = 1
    dist_mtx = 1 - sim_mtx
    distArray = ssd.squareform(dist_mtx)
    linked = linkage(distArray, method="ward")
    th = 0.65

    # Get country meta data list for visualzation
    continent_list = [country_to_continent[country] for country in target_countries]
    language_list = [country_to_language[country] for country in target_countries]
    language_family_list = [
        country_to_language_family[country] for country in target_countries
    ]

    # Convert name for visualize
    name_convert_dict = {row: row for row in target_countries}
    name_convert_dict["Korea, Republic of"] = "S. Korea"
    name_convert_dict["Taiwan, Province of China"] = "Taiwan"
    name_convert_dict["Iran, Islamic Republic of"] = "Iran"
    name_convert_dict["United Kingdom"] = "U.K."
    name_convert_dict["Russian Federation"] = "Russia"
    name_convert_dict["South Africa"] = "S. Africa"
    name_convert_dict["Czech Republic"] = "Czech"
    target_countries = [name_convert_dict[row] for row in target_countries]

    # Color configuration
    c_list = get_awesome_c_list()
    continent_color_mapper = {
        "South America": 5,
        "Africa": 8,
        "Europe": 2,
        "Asia": 3,
        "Oceania": 4,
        "North America": 0,
    }
    languae_color_mapper = {
        "en": "#D6A023",
        "zh": "#FF5722",
        "de": "#F5CC26",
        "pt": "#009688",
        "nl": "#BDA661",
        "fr": "#d3d3d3",
        "es": "#d3d3d3",
        "it": "#d3d3d3",
        "ja": "#d3d3d3",
        "ko": "#d3d3d3",
        "ru": "#d3d3d3",
        "no": "#d3d3d3",
        "pl": "#d3d3d3",
        "hi": "#d3d3d3",
        "tr": "#d3d3d3",
        "cs": "#d3d3d3",
        "sv": "#d3d3d3",
        "he": "#d3d3d3",
        "fa": "#d3d3d3",
        "el": "#d3d3d3",
        "fi": "#d3d3d3",
        "hu": "#d3d3d3",
        "da": "#d3d3d3",
        "ro": "#d3d3d3",
        "uk": "#d3d3d3",
        "th": "#d3d3d3",
        "ar": "#d3d3d3",
        "af": "#d3d3d3",
    }
    languae_family_color_mapper = {
        "Italic": c_list[10],
        "Germanic": c_list[5],
        "Sintic": c_list[3],
        "Slavic": c_list[12],
        "Semitic": c_list[0],
        "Japanic": c_list[-1],
        "Korean": c_list[-1],
        "Indo-Aryan": c_list[-1],
        "Turkic": c_list[-1],
        "Iranian": c_list[-1],
        "Hellenic": c_list[-1],
        "Finno-permic": c_list[-1],
        "Urgic": c_list[-1],
        "Tai": c_list[-1],
    }
    languae_color_list = [languae_color_mapper[i] for i in language_list]
    languae_family_color_list = [
        languae_family_color_mapper[i] for i in language_family_list
    ]
    continent_color_list = [c_list[continent_color_mapper[i]] for i in continent_list]
    cluster_result = fcluster(linked, th, "distance")
    leaves_color_mapper = {1: 18, 2: 15, 3: 16, 4: 13, 5: 10, 6: 8}
    leaves_color_dict = {
        name: c_list[leaves_color_mapper[cluster_index]]
        for name, cluster_index in zip(target_countries, cluster_result)
    }

    # Draw dendrogram part
    import seaborn as sns

    sns.set(color_codes=True)
    import matplotlib.pyplot as plt
    from pylab import rcParams
    import matplotlib.font_manager as font_manager
    import matplotlib.patches as patches

    set_link_color_palette([c_list[x] for x in [18, 15, 16, 13, 10, 8]])
    fig, ax = plt.subplots(1, 1, figsize=(13, 26))
    fig = dendrogram(linked, orientation="left", color_threshold=th, distance_sort=True)
    ax.get_yticks()
    plt.axis("off")
    plt.savefig(DENDROGRAM_PART_PATH, bbox_inches="tight")

    prop = font_manager.FontProperties(fname=FONT_PATH, size=22)
    bold_prop = font_manager.FontProperties(fname=BOLD_FONT_PATH, size=22)
    small_prop = font_manager.FontProperties(fname=FONT_PATH, size=20)
    tick_prop = font_manager.FontProperties(fname=FONT_PATH, size=16)

    # Draw heatmap part
    g = sns.clustermap(
        sim_mtx,
        cmap="viridis_r",
        yticklabels=target_countries,
        vmax=0.776,
        row_linkage=linked,
        col_linkage=linked,
        row_colors=[
            continent_color_list,
            languae_family_color_list,
            languae_color_list,
        ],
        linewidths=0.01,
        figsize=(20, 16),
        cbar_pos=(0.99, 0.53, 0.03, 0.220),
    )
    g.ax_col_dendrogram.set_visible(False)
    g.ax_row_dendrogram.set_visible(False)
    ax = g.ax_heatmap
    ax.set_xticks([])
    for label in ax.get_yticklabels():
        ax.text(
            label._x - 10,
            label._y + 0.22,
            label.get_text(),
            c=leaves_color_dict[label.get_text()],
            fontproperties=small_prop,
        )
    ax.set_yticks([])

    ax.collections[0].colorbar.ax.set_title("Similarity\n", fontproperties=bold_prop)
    ax.collections[0].colorbar.set_ticks([0.3, 0.5, 0.7])
    for label in ax.collections[0].colorbar.ax.get_yticklabels():
        label.set_fontproperties(prop)

    from matplotlib.patches import Rectangle

    ax.add_patch(
        Rectangle((-4.6, 0), 4.6, 7, fill=False, clip_on=False, edgecolor="black", lw=3)
    )
    ax.add_patch(
        Rectangle((-4.6, 7), 4.6, 4, fill=False, clip_on=False, edgecolor="black", lw=3)
    )
    ax.add_patch(
        Rectangle(
            (-4.6, 11), 4.6, 6, fill=False, clip_on=False, edgecolor="black", lw=3
        )
    )
    ax.add_patch(
        Rectangle(
            (-4.6, 17), 4.6, 8, fill=False, clip_on=False, edgecolor="black", lw=3
        )
    )
    ax.add_patch(
        Rectangle(
            (-4.6, 25), 4.6, 6, fill=False, clip_on=False, edgecolor="black", lw=3
        )
    )
    ax.add_patch(
        Rectangle(
            (-4.6, 31), 4.6, 5, fill=False, clip_on=False, edgecolor="black", lw=3
        )
    )
    lp = lambda i: plt.plot(
        [],
        color=c_list[continent_color_mapper[i]],
        ms=15,
        mec="none",
        label=i[0].upper() + i[1:],
        ls="",
        marker="o",
    )[0]
    handles = [
        lp(k)
        for k in [
            "Asia",
            "Europe",
            "North America",
            "Africa",
            "Oceania",
            "South America",
        ]
    ]
    continent_legend = plt.legend(
        handles=handles,
        bbox_to_anchor=(0.5, 1.74),
        prop=prop,
        frameon=False,
        ncol=6,
        handlelength=0,
        handletextpad=1,
    )
    plt.text(-11.2, 1.07, "Continent", fontproperties=bold_prop)

    lp = lambda i: plt.plot(
        [],
        color=languae_family_color_mapper[i],
        ms=15,
        mec="none",
        label=i[0].upper() + i[1:],
        ls="",
        marker="o",
    )[0]
    handles = [lp(k) for k in ["Sintic", "Germanic", "Slavic", "Italic", "Semitic"]]
    language_family_legend = plt.legend(
        handles=handles,
        bbox_to_anchor=(-4.2, 1.59),
        prop=prop,
        frameon=False,
        ncol=5,
        handlelength=0,
        handletextpad=1,
    )
    plt.text(-11.2, 1, "Language Family", fontproperties=bold_prop)

    language_name_convert_dict = {
        "en": "English",
        "zh": "Chinese",
        "de": "German",
        "pt": "Portuguese",
        "nl": "Dutch",
    }
    lp = lambda i: plt.plot(
        [],
        color=languae_color_mapper[i],
        ms=15,
        mec="none",
        label=language_name_convert_dict[i],
        ls="",
        marker="o",
    )[0]
    handles = [lp(k) for k in ["zh", "en", "de", "pt", "nl"]]
    language_legend = plt.legend(
        handles=handles,
        bbox_to_anchor=(-4.2, 1.45),
        prop=prop,
        frameon=False,
        ncol=5,
        handlelength=0,
        handletextpad=1,
    )
    plt.text(-11.2, 0.93, "Language", fontproperties=bold_prop)

    plt.gca().add_artist(continent_legend)
    plt.gca().add_artist(language_family_legend)
    plt.savefig(HEATMAP_PART_PATH, bbox_inches="tight")

    # Calculate clusim part
    hierarchical_clu = Clustering()
    continent_clu = Clustering()
    language_clu = Clustering()
    language_family_clu = Clustering()

    hierarchical_clu.from_scipy_linkage(linked, dist_rescaled=False)
    continent_clu.from_membership_list(continent_list)
    language_clu.from_membership_list(language_list)
    language_family_clu.from_membership_list(language_family_list)

    r_list = list(range(-5, 21))
    similiarties_continent = [
        sim.element_sim(hierarchical_clu, continent_clu, r=r) for r in r_list
    ]
    similiarties_language = [
        sim.element_sim(hierarchical_clu, language_clu, r=r) for r in r_list
    ]
    similiarties_language_family = [
        sim.element_sim(hierarchical_clu, language_family_clu, r=r) for r in r_list
    ]

    sns.set_style("white")
    fig, ax = plt.subplots(1, figsize=(10, 6))
    ax.plot(r_list, similiarties_continent, "-", label="Continent")
    ax.plot(r_list, similiarties_language_family, "-", label="Language Family")
    ax.plot(r_list, similiarties_language, "-", label="Language")
    ax.set_xlabel("r, Scaling parameter", fontproperties=prop)
    ax.set_ylabel("Similarity", fontproperties=prop)
    ax.legend(bbox_to_anchor=(0.43, 0.68), prop=small_prop, frameon=False)

    for label in ax.get_xticklabels():
        label.set_fontproperties(tick_prop)
    for label in ax.get_yticklabels():
        label.set_fontproperties(tick_prop)

    plt.savefig(CLUSIM_PART_PATH, bbox_inches="tight")


if __name__ == "__main__":
    INPUT_EMBEDDING_FILE = sys.argv[1]
    INPUT_META_INFO_FILE = sys.argv[2]
    COUNTRY_META_INFO_FILE = sys.argv[3]
    FONT_PATH = sys.argv[4] if sys.argv[4] != "None" else None
    BOLD_FONT_PATH = sys.argv[5] if sys.argv[5] != "None" else None
    DENDROGRAM_PART_PATH = sys.argv[6]
    HEATMAP_PART_PATH = sys.argv[7]
    CLUSIM_PART_PATH = sys.argv[8]

    draw_figure(
        INPUT_EMBEDDING_FILE,
        INPUT_META_INFO_FILE,
        COUNTRY_META_INFO_FILE,
        FONT_PATH,
        BOLD_FONT_PATH,
        DENDROGRAM_PART_PATH,
        HEATMAP_PART_PATH,
        CLUSIM_PART_PATH,
    )
