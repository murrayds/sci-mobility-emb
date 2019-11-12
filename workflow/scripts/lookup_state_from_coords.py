"""

lookup_state_from_coords.py

author: Dakota Murray

Uses the Nominatim API to lookup geographic metadata using latitude and
longitude coordinates of each organization. Specifically, we are interested in
county and regional information.

"""

API_KEY = open('LOCATIONIQ_API_KEY').read().strip()
BASE_URL = "https://us1.locationiq.com/v1/reverse.php?key={}&lat={}&lon={}&format=json&zoom=5&namedetails=1"

#BASE_URL = 'https://nominatim.openstreetmap.org/reverse?lat={}&lon={}&format=json&zoom=5&namedetails=1&email=dakmurra@iu.edu'

 # Import necessary libraries
import pandas as pd
import requests
from time import sleep

import logging
logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)

import argparse
parser = argparse.ArgumentParser()

# System arguments
parser.add_argument("-i", "--input", help = "Input file contianing organization lookup table",
                    type = str, required = True)
parser.add_argument("-s", "--sleep", help = "The number of seconds to wait in betwee API requests",
                    type = float, default = 0.5, required = False)
parser.add_argument("-o", "--output", help = "Output data path",
                    type = str, required = True)

args = parser.parse_args()

# Load transition data
logging.info('Loading organization lookup table')
lookup = pd.read_csv(args.input, sep = "\t")

jsonlist = []

# Iterate through objects
for index, row in lookup.iterrows():
    #print("lat: {}, lon: {}".format(row.latitude, row.longitude))
    url_with_coords = BASE_URL.format(API_KEY, row.latitude, row.longitude)
    logging.info("\nOrg: {}\nCountry: {}\nURL: {}\n---".format(
                 row.full_name, row.country_iso_name, url_with_coords)
    )

    request = requests.get(url_with_coords)
    data = request.json()
    if 'address' in data.keys():
        address = data['address']
        address['latitude'] = row.latitude
        address['longitude'] = row.longitude
        address['cwts_org_no'] = row.cwts_org_no
        if 'namedetails' in data.keys():
            if 'name:en' in data['namedetails'].keys():
                address['nameen'] = data['namedetails']['name:en']
        jsonlist.append(address)
    sleep(args.sleep)

json_df = pd.DataFrame(jsonlist)

# Write to csv
json_df.to_csv(args.output)
