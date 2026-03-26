"""
End-to-end workflow tests.

These tests mirror real procurement integration work — they chain multiple
API calls together so that the output of one call feeds into the next,
just like validating a real ERP sync workflow.
"""
import requests
from config.settings import BASE_URL


class TestProcurementWorkflow:
    def test_full_order_lifecycle(self, admin_headers):
        """
        Complete happy-path workflow:
        Create supplier → create items → place order →
        verify total → approve → ship → deliver → verify final state.
        """
        # Step 1: Create a supplier
        import uuid
        supplier_resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={"name": f"Global Parts-{uuid.uuid4().hex[:6]}", "email": f"gp-{uuid.uuid4().hex[:6]}@test.com", "country": "DE"},
            headers=admin_headers,
        )
        assert supplier_resp.status_code == 201
        supplier = supplier_resp.json()
        supplier_id = supplier["id"]

        # Step 2: Create two items under that supplier
        item_a_resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Steel Bolt", "sku": f"BOLT-{uuid.uuid4().hex[:6]}", "unit_price": 0.50, "supplier_id": supplier_id},
            headers=admin_headers,
        )
        assert item_a_resp.status_code == 201
        item_a = item_a_resp.json()

        item_b_resp = requests.post(
            f"{BASE_URL}/items",
            json={"name": "Steel Nut", "sku": f"NUT-{uuid.uuid4().hex[:6]}", "unit_price": 0.25, "supplier_id": supplier_id},
            headers=admin_headers,
        )
        assert item_b_resp.status_code == 201
        item_b = item_b_resp.json()

        # Step 3: Place a purchase order
        order_resp = requests.post(
            f"{BASE_URL}/orders",
            json={
                "supplier_id": supplier_id,
                "lines": [
                    {"item_id": item_a["id"], "quantity": 100},  # 50.00
                    {"item_id": item_b["id"], "quantity": 100},  # 25.00
                ],
            },
            headers=admin_headers,
        )
        assert order_resp.status_code == 201
        order = order_resp.json()
        order_id = order["id"]

        # Step 4: Verify order total is calculated correctly
        assert order["total"] == 75.00
        assert order["status"] == "pending"
        assert len(order["lines"]) == 2

        # Step 5: Walk through full status lifecycle
        for expected_status, next_status in [
            ("pending",   "approved"),
            ("approved",  "shipped"),
            ("shipped",   "delivered"),
        ]:
            current = requests.get(f"{BASE_URL}/orders/{order_id}", headers=admin_headers).json()
            assert current["status"] == expected_status

            transition_resp = requests.patch(
                f"{BASE_URL}/orders/{order_id}/status",
                json={"status": next_status},
                headers=admin_headers,
            )
            assert transition_resp.status_code == 200
            assert transition_resp.json()["status"] == next_status

        # Step 6: Verify final state
        final = requests.get(f"{BASE_URL}/orders/{order_id}", headers=admin_headers).json()
        assert final["status"] == "delivered"
        assert final["total"] == 75.00

        # Cleanup
        requests.delete(f"{BASE_URL}/items/{item_a['id']}", headers=admin_headers)
        requests.delete(f"{BASE_URL}/items/{item_b['id']}", headers=admin_headers)
        requests.delete(f"{BASE_URL}/suppliers/{supplier_id}", headers=admin_headers)

    def test_supplier_deactivation_does_not_affect_existing_orders(self, make_supplier, make_item, make_order, admin_headers):
        """
        Deactivating a supplier (setting active=0) should not destroy existing orders.
        The orders should still be retrievable and accurate.
        """
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=50.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 2}])

        # Deactivate supplier
        patch_resp = requests.patch(
            f"{BASE_URL}/suppliers/{supplier['id']}",
            json={"active": 0},
            headers=admin_headers,
        )
        assert patch_resp.status_code == 200
        assert patch_resp.json()["active"] == 0

        # Order should still exist and be intact
        order_resp = requests.get(f"{BASE_URL}/orders/{order['id']}", headers=admin_headers)
        assert order_resp.status_code == 200
        assert order_resp.json()["total"] == 100.00

    def test_cross_supplier_order_is_rejected(self, make_supplier, make_item, admin_headers):
        """
        Attempting to include an item from Supplier B on an order for Supplier A
        must be rejected — a key integration rule in procurement systems.
        """
        supplier_a = make_supplier()
        supplier_b = make_supplier()
        item_b     = make_item(supplier_id=supplier_b["id"], unit_price=10.00)

        resp = requests.post(
            f"{BASE_URL}/orders",
            json={
                "supplier_id": supplier_a["id"],
                "lines": [{"item_id": item_b["id"], "quantity": 1}],
            },
            headers=admin_headers,
        )
        assert resp.status_code == 422
        assert "does not belong to this supplier" in resp.json()["detail"]

    def test_viewer_can_read_but_not_modify(self, make_supplier, make_item, make_order, viewer_headers, admin_headers):
        """
        Viewer role should have full read access but zero write access
        across all resources.
        """
        supplier = make_supplier()
        item     = make_item(supplier_id=supplier["id"], unit_price=1.00)
        order    = make_order(supplier_id=supplier["id"], lines=[{"item_id": item["id"], "quantity": 1}])

        # Reads should all succeed
        assert requests.get(f"{BASE_URL}/suppliers",             headers=viewer_headers).status_code == 200
        assert requests.get(f"{BASE_URL}/suppliers/{supplier['id']}", headers=viewer_headers).status_code == 200
        assert requests.get(f"{BASE_URL}/items",                 headers=viewer_headers).status_code == 200
        assert requests.get(f"{BASE_URL}/orders",                headers=viewer_headers).status_code == 200
        assert requests.get(f"{BASE_URL}/orders/{order['id']}",  headers=viewer_headers).status_code == 200

        # Writes should all be blocked
        import uuid
        assert requests.post(f"{BASE_URL}/suppliers",
            json={"name": f"X-{uuid.uuid4().hex[:4]}", "email": f"x-{uuid.uuid4().hex[:4]}@test.com", "country": "US"},
            headers=viewer_headers).status_code == 403

        assert requests.patch(f"{BASE_URL}/suppliers/{supplier['id']}",
            json={"country": "FR"}, headers=viewer_headers).status_code == 403

        assert requests.patch(f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "approved"}, headers=viewer_headers).status_code == 403
