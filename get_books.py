import urllib.request
import json
import ssl

context = ssl._create_unverified_context()
url = "https://firestore.googleapis.com/v1/projects/kutubfm-1ef89/databases/(default)/documents/books?pageSize=100"
try:
    response = urllib.request.urlopen(url, context=context)
    data = json.loads(response.read().decode('utf-8'))
    docs = data.get('documents', [])
    for doc in docs:
        fields = doc.get('fields', {})
        book_id = doc.get('name', '').split('/')[-1]
        print(f"--- Book ID: {book_id} ---")
        for key, val in fields.items():
            print(f"  {key}: {val}")
except Exception as e:
    print("Error:", e)
