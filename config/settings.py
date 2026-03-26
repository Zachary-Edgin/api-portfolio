import os

ENVIRONMENTS = {
    "local":   "http://localhost:8000",
    "docker":  "http://app:8000",
    "staging": "http://staging.your-app.com",
}

BASE_URL = os.getenv("BASE_URL") or ENVIRONMENTS.get(os.getenv("ENV", "local"))

ADMIN_USER     = os.getenv("ADMIN_USER",    "admin")
ADMIN_PASS     = os.getenv("ADMIN_PASS",    "secret123")
VIEWER_USER    = os.getenv("VIEWER_USER",   "viewer")
VIEWER_PASS    = os.getenv("VIEWER_PASS",   "viewpass")
