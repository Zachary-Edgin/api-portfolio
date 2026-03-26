import requests
from config.settings import BASE_URL


class TestLogin:
    def test_valid_admin_login_returns_token(self):
        resp = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "admin", "password": "secret123"},
        )
        assert resp.status_code == 200
        body = resp.json()
        assert "access_token" in body
        assert body["token_type"] == "bearer"

    def test_valid_viewer_login_returns_token(self):
        resp = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "viewer", "password": "viewpass"},
        )
        assert resp.status_code == 200
        assert "access_token" in resp.json()

    def test_wrong_password_returns_401(self):
        resp = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "admin", "password": "wrongpassword"},
        )
        assert resp.status_code == 401

    def test_unknown_user_returns_401(self):
        resp = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "ghost", "password": "doesntmatter"},
        )
        assert resp.status_code == 401

    def test_missing_credentials_returns_422(self):
        resp = requests.post(f"{BASE_URL}/auth/login", data={})
        assert resp.status_code == 422


class TestProtectedRoutes:
    def test_no_token_returns_401(self):
        resp = requests.get(f"{BASE_URL}/suppliers")
        assert resp.status_code == 401

    def test_invalid_token_returns_401(self):
        resp = requests.get(
            f"{BASE_URL}/suppliers",
            headers={"Authorization": "Bearer this.is.not.valid"},
        )
        assert resp.status_code == 401

    def test_malformed_auth_header_returns_401(self):
        resp = requests.get(
            f"{BASE_URL}/suppliers",
            headers={"Authorization": "NotBearer sometoken"},
        )
        assert resp.status_code == 401

    def test_valid_token_grants_access(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/suppliers", headers=admin_headers)
        assert resp.status_code == 200

    def test_me_endpoint_returns_correct_user(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/auth/me", headers=admin_headers)
        assert resp.status_code == 200
        body = resp.json()
        assert body["username"] == "admin"
        assert body["role"] == "admin"

    def test_viewer_cannot_create_supplier(self, viewer_headers):
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": "Blocked Supplier", "email": "blocked@test.com", "country": "US"},
            headers=viewer_headers,
        )
        assert resp.status_code == 403
