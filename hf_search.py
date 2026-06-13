import urllib.request
import json

url = 'https://huggingface.co/api/models?search=knight'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    response = urllib.request.urlopen(req).read().decode('utf-8')
    data = json.loads(response)
    for model in data[:10]:
        print(model['id'])
except Exception as e:
    print(f"Error: {e}")
