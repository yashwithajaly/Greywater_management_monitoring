import requests

API_KEY = "AIzaSyAqpMiSjDQh3CQmUmnLFQngZuvz-FcoeXA"
url = f"https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key={API_KEY}"

payload = {
    "contents": [
        {"parts": [{"text": "What is the pH of drinking water?"}]}
    ]
}

response = requests.post(url, json=payload)

print(response.json())
