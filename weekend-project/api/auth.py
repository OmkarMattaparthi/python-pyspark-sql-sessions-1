import requests
from config.settings import API_BASE_URL, API_USERNAME, API_PASSWORD


def get_token():
    url = f"{API_BASE_URL}/api/auth/login/"
    payload = {
        "username": API_USERNAME,
        "password": API_PASSWORD
    }

    response = requests.post(url, json=payload)
    print("Login status:", response.status_code)

    data = response.json()
    token = data["token"]
    print("Token received:", token)
    return token
