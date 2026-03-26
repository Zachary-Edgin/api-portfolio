import requests
from config.settings import BASE_URL


class TestItemCRUD:
    def test_create_item_returns_201(self, make_supplier, make_item):
        supplier = make_supplier()
        item = make_item(supplier_id=supplier["id"], name="Bolt", unit_price=1.50)
        assert item["id"] is not None
        assert item["unit_price"] == 1.50

    def test_create_item_response_schema(self, make_supplier, make_item):
        supplier = make_supplier()
        item = make_item(supplier_id=supplier["id"])
        assert all(k in item for k in ["id", "name", "sku", "unit_price", "supplier_id"])

    def test_get_item_by_id(self, make_supplier, make_item, admin_headers):
        supplier = make_supplier()
        item = make_item(supplier_id=supplier["id"])
        resp = requests.get(f"{BASE_URL}/items/{item['id']}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == item["id"]

    def test_get_nonexistent_item_returns_404(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/items/999999", headers=admin_headers)
        assert resp.status_code == 404

    def test_list_items_returns_list(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/items", headers=admin_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)

    def test_update_item_price(self, make_supplier, make_item, admin_headers):
        supplier = make_supplier()
        item = make_item(supplier_id=supplier["id"], unit_price=5.00)
        resp = requests.patch(
            f"{BASE_URL}/items/{item['id']}",
            json={"unit_price": 12.99},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["unit_price"] == 12.99

    def test_delete_item(self, make_supplier, admin_headers):
        import uuid
        supplier = make_supplier()
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Temp", "sku": f"TEMP-{uuid.uuid4().hex[:6]}", "unit_price": 1.0, "supplier_id": supplier["id"]},
            headers=admin_headers,
        )
        assert resp.status_code == 201
        iid = resp.json()["id"]
        del_resp = requests.delete(f"{BASE_URL}/items/{iid}", headers=admin_headers)
        assert del_resp.status_code == 204


class TestItemBusinessRules:
    def test_negative_price_returns_422(self, make_supplier, admin_headers):
        import uuid
        supplier = make_supplier()
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Bad Item", "sku": f"BAD-{uuid.uuid4().hex[:6]}", "unit_price": -5.00, "supplier_id": supplier["id"]},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_zero_price_returns_422(self, make_supplier, admin_headers):
        import uuid
        supplier = make_supplier()
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Free Item", "sku": f"FREE-{uuid.uuid4().hex[:6]}", "unit_price": 0, "supplier_id": supplier["id"]},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_duplicate_sku_returns_409(self, make_supplier, make_item, admin_headers):
        supplier = make_supplier()
        item = make_item(supplier_id=supplier["id"])
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Duplicate SKU", "sku": item["sku"], "unit_price": 1.0, "supplier_id": supplier["id"]},
            headers=admin_headers,
        )
        assert resp.status_code == 409

    def test_item_with_unknown_supplier_returns_404(self, admin_headers):
        import uuid
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Orphan", "sku": f"ORP-{uuid.uuid4().hex[:6]}", "unit_price": 1.0, "supplier_id": 999999},
            headers=admin_headers,
        )
        assert resp.status_code == 404

    def test_viewer_cannot_create_item(self, make_supplier, viewer_headers):
        import uuid
        supplier_resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": f"S-{uuid.uuid4().hex[:6]}", "email": f"v-{uuid.uuid4().hex[:6]}@test.com", "country": "US"},
            headers={"Authorization": viewer_headers["Authorization"].replace("viewer", "admin")},
        )
        # Just test that viewer gets 403 on item creation
        resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Blocked", "sku": "BLK-001", "unit_price": 1.0, "supplier_id": 1},
            headers=viewer_headers,
        )
        assert resp.status_code == 403
