import requests
from config.settings import BASE_URL


class TestSupplierCRUD:
    def test_create_supplier_returns_201(self, make_supplier):
        supplier = make_supplier(name="Acme Corp", country="US")
        assert supplier["id"] is not None
        assert supplier["active"] == 1

    def test_create_supplier_response_schema(self, make_supplier):
        supplier = make_supplier()
        assert all(k in supplier for k in ["id", "name", "email", "country", "active"])

    def test_get_supplier_by_id(self, make_supplier, admin_headers):
        supplier = make_supplier()
        resp = requests.get(f"{BASE_URL}/suppliers/{supplier['id']}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == supplier["id"]

    def test_get_nonexistent_supplier_returns_404(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/suppliers/999999", headers=admin_headers)
        assert resp.status_code == 404

    def test_list_suppliers_returns_list(self, admin_headers, make_supplier):
        make_supplier()
        resp = requests.get(f"{BASE_URL}/suppliers", headers=admin_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    def test_update_supplier_country(self, make_supplier, admin_headers):
        supplier = make_supplier(country="US")
        resp = requests.patch(
            f"{BASE_URL}/suppliers/{supplier['id']}",
            json={"country": "CA"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["country"] == "CA"

    def test_update_nonexistent_supplier_returns_404(self, admin_headers):
        resp = requests.patch(
            f"{BASE_URL}/suppliers/999999",
            json={"country": "CA"},
            headers=admin_headers,
        )
        assert resp.status_code == 404

    def test_delete_supplier(self, admin_headers):
        import uuid
        # Create directly so we control the teardown
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": f"Delete-Me-{uuid.uuid4().hex[:6]}", "email": f"del-{uuid.uuid4().hex[:6]}@test.com", "country": "US"},
            headers=admin_headers,
        )
        assert resp.status_code == 201
        sid = resp.json()["id"]
        del_resp = requests.delete(f"{BASE_URL}/suppliers/{sid}", headers=admin_headers)
        assert del_resp.status_code == 204

    def test_delete_nonexistent_supplier_returns_404(self, admin_headers):
        resp = requests.delete(f"{BASE_URL}/suppliers/999999", headers=admin_headers)
        assert resp.status_code == 404


class TestSupplierBusinessRules:
    def test_duplicate_email_returns_409(self, make_supplier, admin_headers):
        supplier = make_supplier()
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": "Another Name", "email": supplier["email"], "country": "US"},
            headers=admin_headers,
        )
        assert resp.status_code == 409

    def test_missing_required_fields_returns_422(self, admin_headers):
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": "No Email Supplier"},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_invalid_email_format_returns_422(self, admin_headers):
        resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": "Bad Email", "email": "not-an-email", "country": "US"},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_cannot_delete_supplier_with_active_order(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=10.00)
        make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        resp = requests.delete(f"{BASE_URL}/suppliers/{supplier['id']}", headers=admin_headers)
        assert resp.status_code == 409
