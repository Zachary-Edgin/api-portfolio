import requests
from config.settings import BASE_URL


class TestOrderCRUD:
    def test_create_order_returns_201(self, make_supplier, make_item, make_order):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=25.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 2}])
        assert order["id"] is not None
        assert order["status"] == "pending"

    def test_order_total_is_calculated_correctly(self, make_supplier, make_item, make_order):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=10.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 3}])
        assert order["total"] == 30.00

    def test_order_total_multi_line(self, make_supplier, make_item, make_order):
        supplier = make_supplier()
        item_a   = make_item(supplier_id=supplier["id"], unit_price=5.00)
        item_b   = make_item(supplier_id=supplier["id"], unit_price=20.00)
        order    = make_order(
            supplier_id=supplier["id"],
            lines=[
                {"item_id": item_a["id"], "quantity": 4},   # 20.00
                {"item_id": item_b["id"], "quantity": 1},   # 20.00
            ],
        )
        assert order["total"] == 40.00

    def test_order_response_schema(self, make_supplier, make_item, make_order):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        assert all(k in order for k in ["id", "supplier_id", "status", "total", "lines"])

    def test_get_order_by_id(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        resp     = requests.get(f"{BASE_URL}/orders/{order['id']}", headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == order["id"]

    def test_get_nonexistent_order_returns_404(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/orders/999999", headers=admin_headers)
        assert resp.status_code == 404

    def test_list_orders_returns_list(self, admin_headers):
        resp = requests.get(f"{BASE_URL}/orders", headers=admin_headers)
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)


class TestOrderStatusTransitions:
    def test_pending_to_approved(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        resp     = requests.patch(
            f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "approved"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "approved"

    def test_approved_to_shipped(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "approved"}, headers=admin_headers)
        resp = requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "shipped"}, headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["status"] == "shipped"

    def test_shipped_to_delivered(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "approved"}, headers=admin_headers)
        requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "shipped"},  headers=admin_headers)
        resp = requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "delivered"}, headers=admin_headers)
        assert resp.status_code == 200
        assert resp.json()["status"] == "delivered"

    def test_pending_to_cancelled(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        resp     = requests.patch(
            f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "cancelled"},
            headers=admin_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["status"] == "cancelled"

    def test_invalid_transition_returns_422(self, make_supplier, make_item, make_order, admin_headers):
        """pending → delivered is not a valid transition."""
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        resp     = requests.patch(
            f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "delivered"},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_delivered_order_cannot_be_changed(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        for status in ["approved", "shipped", "delivered"]:
            requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": status}, headers=admin_headers)
        resp = requests.patch(
            f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "cancelled"},
            headers=admin_headers,
        )
        assert resp.status_code == 422


class TestOrderBusinessRules:
    def test_item_from_wrong_supplier_returns_422(self, make_supplier, make_item, admin_headers):
        supplier_a = make_supplier()
        supplier_b = make_supplier()
        item_b     = make_item(supplier_id=supplier_b["id"], unit_price=1.00)
        resp       = requests.post(
            f"{BASE_URL}/orders",
            json={"supplier_id": supplier_a["id"], "lines": [{"item_id": item_b["id"], "quantity": 1}]},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_zero_quantity_returns_422(self, make_supplier, make_item, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        resp     = requests.post(
            f"{BASE_URL}/orders",
            json={"supplier_id": supplier["id"], "lines": [{"item_id": item["id"], "quantity": 0}]},
            headers=admin_headers,
        )
        assert resp.status_code == 422

    def test_cannot_delete_approved_order(self, make_supplier, make_item, make_order, admin_headers):
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])
        requests.patch(f"{BASE_URL}/orders/{order['id']}/status", json={"status": "approved"}, headers=admin_headers)
        resp = requests.delete(f"{BASE_URL}/orders/{order['id']}", headers=admin_headers)
        assert resp.status_code == 409
