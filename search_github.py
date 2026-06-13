import urllib.request
import json
import os

url = 'https://api.github.com/search/code?q=filename:knight.glb'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    response = urllib.request.urlopen(req).read().decode('utf-8')
    data = json.loads(response)
    for item in data.get('items', []):
        print(f"Repo: {item['repository']['full_name']}")
        print(f"Path: {item['path']}")
        raw_url = f"https://raw.githubusercontent.com/{item['repository']['full_name']}/master/{item['path']}"
        print(f"Raw URL: {raw_url}")
        print("---")
except Exception as e:
    print(f"Error: {e}")
