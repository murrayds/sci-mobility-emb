"""

calculate_cpc_measures.py

author: Dakota Murray

Calculates the Common part of commuters measures.

"""
import pandas as pd
import numpy as np
import os
import logging

logging.basicConfig(format="%(levelname)s:%(message)s", level=logging.INFO)

import argparse

parser = argparse.ArgumentParser()

# System arguments
parser.add_argument(
    "-i",
    "--input",
    help="Input file, contianing predicted-vs-actual information",
    type=str,
    required=True,
    nargs='+'
)
parser.add_argument("-o", "--output", help="Output data path", type=str, required=True)

args = parser.parse_args()

measures = []
for file in args.input:
    df = pd.read_csv(file)
    dist = os.path.basename(os.path.dirname(file))
    NCC_power = np.sum(np.minimum(df["actual"], df["expected.power"]))
    NCC_exp = np.sum(np.minimum(df["actual"], df["expected.exp"]))
    NC_T = np.sum(df["actual"])
    CPC_power = (2 * NCC_power) / (NC_T + np.sum( df["expected.power"]))
    CPC_exp = (2 * NCC_exp) / (NC_T + np.sum(df["expected.exp"]))
    print(CPC_power, CPC_exp)
    measures.append((dist, CPC_power, CPC_exp))

out_df = pd.DataFrame(measures, columns =['Distance', 'CPC_power', 'CPC_exp'])

# Write to csv
out_df.to_csv(args.output, index=False)
