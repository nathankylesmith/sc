import requests

url = "http://127.0.0.1:5000/upload"
data = {
    "filename": "testfile.wav",
    "userId": 1,
    "transcription": "This is a test transcription.",
    "vector": [0.1, 0.2, 0.3]
}
response = requests.post(url, json=data)
print(response.json())