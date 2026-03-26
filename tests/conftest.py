import pytest
import requests
from config.settings import BASE_URL, ADMIN_USER, ADMIN_PASS, VIEWER_USER, VIEWER_PASS


# ── Token fixtures ─────────────────────────────────────────────────────────────

@pytest.fixture(scope="session")
def admin_token():
    """JWT for the admin user — fetched once per test session."""
    resp = requests.post(
        f"{BASE_URL}/auth/login",
        data={"username": ADMIN_USER, "password": ADMIN_PASS},
    )
    assert resp.status_code == 200, f"Admin login failed: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture(scope="session")
def viewer_token():
    """JWT for the read-only viewer user."""
    resp = requests.post(
        f"{BASE_URL}/auth/login",
        data={"username": VIEWER_USER, "password": VIEWER_PASS},
    )
    assert resp.status_code == 200, f"Viewer login failed: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture
def admin_headers(admin_token):
    return {"Authorization": f"Bearer {admin_token}"}


@pytest.fixture
def viewer_headers(viewer_token):
    return {"Authorization": f"Bearer {viewer_token}"}


# ── Reusable resource factories ────────────────────────────────────────────────

@pytest.fixture
def make_supplier(admin_headers):
    """Creates a supplier and deletes it after the test."""
    created = []

    def _make(name="Test Supplier", email=None, country="US"):
        import uuid
        unique_email = email or f"supplier-{uuid.uuid4().hex[:8]}@test.com"
        unique_name  = f"{name}-{uuid.uuid4().hex[:6]}"
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": unique_name, "email": unique_email, "country": country},
            headers=admin_headers,
        )
        assert resp.status_code == 201, f"make_supplier failed: {resp.text}"
        supplier = resp.json()
        created.append(supplier["id"])
        return supplier

    yield _make

    # Teardown — best-effort cleanup
    for sid in created:
        requests.delete(f"{BASE_URL}/suppliers/{sid}", headers=admin_headers)


@pytest.fixture
def make_item(admin_headers):
    """Creates an item and deletes it after the test."""
    created = []

    def _make(supplier_id, name="Widget", sku=None, unit_price=9.99):
        import uuid
        unique_sku = sku or f"SKU-{uuid.uuid4().hex[:8].upper()}"
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": name, "sku": unique_sku, "unit_price": unit_price, "supplier_id": supplier_id},
            headers=admin_headers,
        )
        assert resp.status_code == 201, f"make_item failed: {resp.text}"
        item = resp.json()
        created.append(item["id"])
        return item

    yield _make

    for iid in created:
        requests.delete(f"{BASE_URL}/items/{iid}", headers=admin_headers)


@pytest.fixture
def make_order(admin_headers):
    """Creates a purchase order and cancels + deletes it after the test."""
    created = []

    def _make(supplier_id, lines):
        resp = requests.post(
            f"{BASE_URL}/orders",
            json={"supplier_id": supplier_id, "lines": lines},
            headers=admin_headers,
        )
        assert resp.status_code == 201, f"make_order failed: {resp.text}"
        order = resp.json()
        created.append(order["id"])
        return order

    yield _make

    for oid in created:
        # Cancel first so delete is allowed
        requests.patch(
            f"{BASE_URL}/orders/{oid}/status",
            json={"status": "cancelled"},
            headers=admin_headers,
        )
        requests.delete(f"{BASE_URL}/orders/{oid}", headers=admin_headers)
