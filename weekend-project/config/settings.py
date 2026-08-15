import os
from dotenv import load_dotenv

load_dotenv()

# API
API_BASE_URL  = os.getenv("API_BASE_URL", "https://ev-project-navy-mu.vercel.app")
API_USERNAME  = os.getenv("API_USERNAME")
API_PASSWORD  = os.getenv("API_PASSWORD")

# Endpoints
LOGIN_ENDPOINT    = f"{API_BASE_URL}/api/auth/login/"
PAYMENTS_ENDPOINT = f"{API_BASE_URL}/api/db/payments/"

# Pagination / throttling
PAGE_SIZE         = int(os.getenv("PAGE_SIZE", 100))
REQUEST_DELAY_SEC = float(os.getenv("REQUEST_DELAY_SEC", 0.3))
MAX_RETRIES       = int(os.getenv("MAX_RETRIES", 5))
RETRY_BACKOFF_SEC = float(os.getenv("RETRY_BACKOFF_SEC", 10))

# Database
DB_HOST     = os.getenv("DB_HOST", "localhost")
DB_PORT     = int(os.getenv("DB_PORT", 5432))
DB_NAME     = os.getenv("DB_NAME", "python_practice")
DB_USER     = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "hariom")

# Target
BRONZE_SCHEMA  = "bronze"
PAYMENTS_TABLE = "payments"
METADATA_TABLE = "pipeline_metadata"
PIPELINE_NAME  = "voltgrid_payments"
