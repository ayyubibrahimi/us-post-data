import os
import requests
import pandas as pd
import io

# Dictionary of states with their respective Dropbox links
state_links = {
    "alaska": "https://www.dropbox.com/scl/fi/46hmzd088xsfodjvrn1nd/alaska_index.csv?rlkey=sxm9twoj6e5yunourtxbtxtdf&st=9yrbcvvm&dl=1",
    "arizona": "https://www.dropbox.com/scl/fi/7l9iaj2qbzq2i0azey2fl/arizona_index.csv?rlkey=2kvtnw5iaonixm08i922c5yw0&st=01o4r4j0&dl=1",
    "california": "https://www.dropbox.com/scl/fi/ait32murofp7b360p9hni/california_index.csv?rlkey=vup9ugrdrbne4kf9mdzuiocle&st=7ud05clp&dl=1",
    "florida": "https://www.dropbox.com/scl/fi/xbvuqf3sx6spr0369j5po/florida_index.csv?rlkey=qhbulvsqggtqqs1t52n5d3hbb&st=1lu4dgzm&dl=1",
    "georgia": "https://www.dropbox.com/scl/fi/zt5bjmti0ib53zret4cjl/georgia_index.csv?rlkey=vxdihmruxipj0t70qkg6gv3f3&st=vteh8461&dl=1",
    "idaho": "https://www.dropbox.com/scl/fi/8ympcc6r01bs7usm7erzz/idaho_index.csv?rlkey=dskj3a3czdg4de3ortkeiq7k9&st=oketnn73&dl=1",
    "illinois": "https://www.dropbox.com/scl/fi/853ypyqq4jz77569npo7w/illinois_index.csv?rlkey=6rsa807ec0an01ndna0jwvmnp&st=3l9fwzw1&dl=1",
    #"indiana": "https://www.dropbox.com/scl/fi/pqurhfpdugciuuzefcau2/indiana_index.csv?rlkey=g6bufpogn4n7bqmrvvz6asm5s&st=bc8tf1k9&dl=1",
    "indiana": "https://www.dropbox.com/scl/fi/vmgoh3ip4n8w0q582x3u8/indiana_index.csv?rlkey=yzuy32qcrnjshsqm9myfx9zm0&st=79r6tcct&dl=1",
    "kansas": "https://www.dropbox.com/scl/fi/mqst15jw3wh0qbeqvaeko/ks-2022-index.csv?rlkey=e03f23fjdht8q97sdiptiow6z&st=28bsdgxv&dl=1",
    "kentucky": "https://www.dropbox.com/scl/fi/vfrc4hk6rc4xxe7abbrqq/kentucky_index.csv?rlkey=jhon9hgnp0cwptndu8u6pnx5a&st=65tycia0&dl=1",
    "maryland": "https://www.dropbox.com/scl/fi/il78zwhiwr96nkjz1y6qy/maryland_index.csv?rlkey=6zaiii9fyov5qq8j8vb8oln4y&st=ff0jfo7m&dl=1",
    "north_carolina": "https://www.dropbox.com/scl/fi/jjinf4bfyk5umweq203bh/north_carolina_index.csv?rlkey=yrcwnb442xgpbi1ybvrsk6ur8&st=s2ffmcxt&dl=1",
    "new_mexico": "https://www.dropbox.com/scl/fi/pcu06g15rfs2x9deyu2ws/new-mexico_index.csv?rlkey=n1fd3oae5vb0ih1jlzzjz66vt&st=oti4cvh0&dl=1",
    "ohio": "https://www.dropbox.com/scl/fi/nxdwwcuo2c4mz2igxyzrl/ohio_index.csv?rlkey=rne8ji1x4rarh2zggsuz6pnng&st=89fm02rd&dl=1",
    "oregon": "https://www.dropbox.com/scl/fi/6bhtcbs4u0i4zv0odj62v/oregon_index.csv?rlkey=w2gcmt61xmnhlu8hyc7b9ybci&st=t5vydjay&dl=1",
    "south_carolina": "https://www.dropbox.com/scl/fi/j3c6mioqjmxddv1cs6602/south_carolina_index.csv?rlkey=w0d2crkkdjhleal88zxe16tzr&st=1fmrbk16&dl=1",
    "tennessee": "https://www.dropbox.com/scl/fi/lxz9ocw7gr2qsaexc3cbh/tennessee_index.csv?rlkey=vqgsf94kre0bexaf3rf97np9o&st=gatjace4&dl=1",
    "texas": "https://www.dropbox.com/scl/fi/9257upb2n6inzs5sbwbz8/texas_index.csv?rlkey=ulz5ws8qyn0mmzs2feuvtz3c3&st=1jud1usv&dl=1",
    "utah": "https://www.dropbox.com/scl/fi/fmvoa5fvehuhcxuo1kn2n/utah_index.csv?rlkey=itmztmc6mcohioum0gpjwztdw&st=296tbj2w&dl=1",
    "vermont": "https://www.dropbox.com/scl/fi/39hyl81d50bwqu53dyecy/vermont_index.csv?rlkey=3zn94khz6lvmc3eqn77036zf5&st=exsgi7uv&dl=1",
    #"washington": "https://www.dropbox.com/scl/fi/7hrjnpbrgq6iw4bbgozbv/washington_index.csv?rlkey=shs9lpp2vmq38d3gttvp8d65g&st=q59u51v7&dl=1",
    "washington": "https://www.dropbox.com/scl/fi/mbrnx3i8nj4mj0mlqmlpf/wa-2024-npi-index.csv?rlkey=qxf7zmirlymorffy6lr3g1cyr&st=d94s64o6&dl=1",
    "west_virginia": "https://www.dropbox.com/scl/fi/iubdg5lxd3vf29sfbrwyu/west_virginia_index.csv?rlkey=g8r9fwgxp36xhd9h508n5ztfz&st=aq9zl624&dl=1",
    "wyoming": "https://www.dropbox.com/scl/fi/4c0bb071llxee25vzw4vm/wyoming_index.csv?rlkey=1ihzu4lme06urgrszldkdg0ns&st=gduoqyhf&dl=1",
    }

# Directory to save the CSV files
output_dir = "data"

# Create the directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Download and save the CSV files
for state, url in state_links.items():
    state_dir = os.path.join(output_dir, state)
    os.makedirs(state_dir, exist_ok=True)
    file_path = os.path.join(state_dir, f"{state}_index.csv")
    
    # Check if the file already exists
    if os.path.exists(file_path):
        print(f"{file_path} already exists. Skipping download.")
        continue
    
    # Download the file if it doesn't exist
    response = requests.get(url)
    response.raise_for_status()  # Ensure the download was successful
    
    # Read the CSV file into a pandas DataFrame
    csv_data = pd.read_csv(io.StringIO(response.text))
    
    # Save the DataFrame to a CSV file
    csv_data.to_csv(file_path, index=False)
    
    print(f"Saved {state} data to {file_path}")
