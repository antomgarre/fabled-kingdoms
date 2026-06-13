import urllib.request
import json

url = 'https://api.github.com/repos/doctor-g/KayKitAnimationInGodot/git/trees/main?recursive=1'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    response = urllib.request.urlopen(req).read().decode('utf-8')
    data = json.loads(response)
    for item in data.get('tree', []):
        if item['path'].endswith('.glb') or item['path'].endswith('.gltf'):
            print(item['path'])
except Exception as e:
    print(f"Error: {e}")
