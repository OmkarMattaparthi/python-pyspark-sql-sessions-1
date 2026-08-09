import requests

url = 'https://ev-project-navy-mu.vercel.app/api/auth/login/'

payload = {
    "username": "voltgrid_demo",
    "password": "EVcharge@AU2025"
}

response = requests.post(
    url,
    json=payload
)

print(response.status_code)
token = response.json().get("token")

BASE_URL = 'https://ev-project-navy-mu.vercel.app'
PAYMENT_ENDPOINT = '/api/db/payments/'

FULL_URL = BASE_URL+PAYMENT_ENDPOINT

params = {
    "page": 1,
    "page_size": 20,
    "updated_after": '2026-07-01T21:04:00Z'
}

headers = {
    "Authorization": f"Token {token}",
    "content-type": 'application/json'
}

response = requests.get(
    FULL_URL,
    params=params,
    headers=headers
)

print(response.json())
