"""
Data-driven tests for the Procurement API.

The core idea: test logic lives here, test data lives in tests/data/.
Adding new scenarios requires zero code changes — just add rows to the
CSV or entries to the JSON.

This pattern mirrors real-world regression suites where QA teams maintain
large spreadsheets of test cases that non-engineers can extend.
"""
import csv
import json
import uuid
import pytest
import requests
from pathlib import Path
from config.settings import BASE_URL

# ── Helpers ───────────────────────────────────────────────────────────────────

DATA_DIR = Path(__file__).parent / "data"


def load_supplier_scenarios():
    """
    Read supplier_scenarios.csv and return a list of pytest parameter sets.
    Each row becomes one test case. The test_id and description are used as
    the pytest node ID so failures are easy to identify in the report.
    """
    scenarios = []
    with open(DATA_DIR / "supplier_scenarios.csv", newline="") as f:
        for row in csv.DictReader(f):
            scenarios.append(
                pytest.param(
                    row,
                    id=f"{row['test_id']}: {row['description']}"
                )
            )
    return scenarios


def load_order_scenarios():
    """
    Read order_scenarios.json and return a list of pytest parameter sets.
    JSON is used here instead of CSV because order scenarios have nested
    structure (multiple lines per order) that doesn't flatten well to CSV.
    """
    with open(DATA_DIR / "order_scenarios.json") as f:
        scenarios = json.load(f)
    return [
        pytest.param(s, id=f"{s['test_id']}: {s['description']}")
        for s in scenarios
    ]


# ── Supplier validation tests ─────────────────────────────────────────────────

class TestSupplierDataDriven:
    @pytest.mark.parametrize("scenario", load_supplier_scenarios())
    def test_supplier_creation_scenarios(self, scenario, admin_headers):
        """
        One test function, twelve scenarios.

        For valid scenarios (expected_status=201), we verify the supplier
        was created and then clean it up. For invalid scenarios, we just
        verify the API rejected the input with the right status code.

        The use of uuid guarantees no name/email collisions between runs,
        which matters because the API enforces uniqueness.
        """
        # Append a short UUID to name and email so repeated runs don't
        # collide on unique constraints in the database
        suffix = uuid.uuid4().hex[:6]
        is_valid = int(scenario["expected_status"]) == 201
        payload = {
            "name":    (scenario["name"] + f"-{suffix}") if scenario["name"] and is_valid else scenario["name"],
            "email":   scenario["email"].replace("@", f"-{suffix}@") if "@" in scenario.get("email", "") and is_valid else scenario.get("email", ""),
            "country": scenario["country"],
        }

        # Remove empty string keys so we actually test "missing field" behavior
        # (sending an empty string is different from omitting the key entirely)
        payload = {k: v for k, v in payload.items() if v != ""}

        expected = int(scenario["expected_status"])
        resp = requests.post(f"{BASE_URL}/suppliers", json=payload, headers=admin_headers)

        assert resp.status_code == expected, (
            f"[{scenario['test_id']}] {scenario['description']}\n"
            f"  Payload:  {payload}\n"
            f"  Expected: {expected}\n"
            f"  Got:      {resp.status_code} — {resp.text}"
        )

        # Clean up any successfully created suppliers so tests stay isolated
        if resp.status_code == 201:
            requests.delete(
                f"{BASE_URL}/suppliers/{resp.json()['id']}",
                headers=admin_headers
            )


# ── Order calculation tests ───────────────────────────────────────────────────

class TestOrderCalculationDataDriven:
    @pytest.mark.parametrize("scenario", load_order_scenarios())
    def test_order_total_calculation(self, scenario, admin_headers):
        """
        One test function, eight order scenarios.

        Each scenario creates a fresh supplier and one item per order line,
        places the order, verifies the total matches our expected value,
        then cleans everything up. The expected_total is calculated manually
        in the JSON file so humans can verify the math independently.

        This directly mirrors ERP integration testing where you'd validate
        that a sync produced the correct calculated values on both sides.
        """
        # Create a supplier to own all items for this order
        supplier_resp = requests.post(
            f"{BASE_URL}/suppliers",
            json={
                "name":    f"DD-Supplier-{uuid.uuid4().hex[:8]}",
                "email":   f"dd-{uuid.uuid4().hex[:8]}@test.com",
                "country": "US",
            },
            headers=admin_headers,
        )
        assert supplier_resp.status_code == 201
        supplier_id = supplier_resp.json()["id"]

        # Create one item per order line, using the unit_price from the scenario
        item_ids = []
        for line in scenario["lines"]:
            item_resp = requests.post(
                f"{BASE_URL}/items",
                json={
                    "name":        f"DD-Item-{uuid.uuid4().hex[:6]}",
                    "sku":         f"DD-{uuid.uuid4().hex[:8].upper()}",
                    "unit_price":  line["unit_price"],
                    "supplier_id": supplier_id,
                },
                headers=admin_headers,
            )
            assert item_resp.status_code == 201
            item_ids.append(item_resp.json()["id"])

        # Build the order payload pairing each item_id with its quantity
        order_lines = [
            {"item_id": item_id, "quantity": line["quantity"]}
            for item_id, line in zip(item_ids, scenario["lines"])
        ]

        order_resp = requests.post(
            f"{BASE_URL}/orders",
            json={"supplier_id": supplier_id, "lines": order_lines},
            headers=admin_headers,
        )
        assert order_resp.status_code == 201
        order = order_resp.json()

        # The core assertion: does the API's calculated total match ours?
        assert order["total"] == pytest.approx(scenario["expected_total"], rel=1e-2), (
            f"[{scenario['test_id']}] {scenario['description']}\n"
            f"  Expected total: {scenario['expected_total']}\n"
            f"  API returned:   {order['total']}"
        )

        # Teardown — cancel and delete the order, then items, then supplier
        requests.patch(
            f"{BASE_URL}/orders/{order['id']}/status",
            json={"status": "cancelled"},
            headers=admin_headers,
        )
        requests.delete(f"{BASE_URL}/orders/{order['id']}", headers=admin_headers)
        for item_id in item_ids:
            requests.delete(f"{BASE_URL}/items/{item_id}", headers=admin_headers)
        requests.delete(f"{BASE_URL}/suppliers/{supplier_id}", headers=admin_headers)
