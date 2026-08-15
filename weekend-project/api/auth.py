import requests
from config.settings import LOGIN_ENDPOINT, API_USERNAME, API_PASSWORD


def get_token():
    """POST to login endpoint and return the auth token."""
    payload = {"username": API_USERNAME, "password": API_PASSWORD}
    response = requests.post(LOGIN_ENDPOINT, json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()
    token = data.get("token")
    if not token:
        raise ValueError(f"Login response did not contain a token: {data}")
    print(f"[auth] Token obtained successfully")
    return token
