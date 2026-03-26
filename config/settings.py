import os

# Switch environments by setting ENV=staging before running pytest
# ENV=staging pytest   → hits staging
# pytest               → hits local (default)

ENVIRONMENTS = {
    "local":   "http://localhost:8000",
    "staging": "http://staging.your-app.com",  # replace when you have a real staging URL
}

BASE_URL = ENVIRONMENTS.get(os.getenv("ENV", "local"))

# Default credentials
ADMIN_USER     = os.getenv("ADMIN_USER",    "admin")
ADMIN_PASS     = os.getenv("ADMIN_PASS",    "secret123")
VIEWER_USER    = os.getenv("VIEWER_USER",   "viewer")
VIEWER_PASS    = os.getenv("VIEWER_PASS",   "viewpass")
