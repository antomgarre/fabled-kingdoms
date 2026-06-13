import urllib.request
import re
import zipfile
import os

url = 'https://quaternius.com/packs/ultimateplatformer.html'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    html = urllib.request.urlopen(req).read().decode('utf-8')
    match = re.search(r'href="(https://[^\"]+\.zip)"', html)
    if not match:
        match = re.search(r'href="([^"]+\.zip)"', html)
        
    if match:
        zip_url = match.group(1)
        if not zip_url.startswith('http'):
            zip_url = 'https://quaternius.com' + ('/' if not zip_url.startswith('/') else '') + zip_url
            
        print(f"Found zip: {zip_url}")
        
        # Download
        zip_path = "pack.zip"
        urllib.request.urlretrieve(zip_url, zip_path)
        print("Downloaded. Extracting...")
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall("quaternius_pack")
            
        print("Extracted to quaternius_pack/")
    else:
        print("No zip found.")
except Exception as e:
    print(f"Error: {e}")
