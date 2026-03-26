# Procurement API — SDET Portfolio Project

[![tests](https://github.com/Zachary-Edgin/api-portfolio/actions/workflows/tests.yml/badge.svg)](https://github.com/Zachary-Edgin/api-portfolio/actions/workflows/tests.yml)

A portfolio-grade API test automation project demonstrating real-world QA engineering skills:
JWT auth testing, full CRUD validation, business rule enforcement, chained workflow tests,
environment configuration, and CI/CD integration.

---

## What's Inside

### The App
A procurement-themed FastAPI service with:
- **JWT Authentication** with role-based access (admin / viewer)
- **Suppliers, Items, and Purchase Orders** as resources
- **Business logic**: order total auto-calculation, status transition enforcement,
  cross-supplier item validation, deletion guards on active orders

### The Test Suite
| File | What it tests |
|------|--------------|
| `tests/test_auth.py` | Login, bad credentials, missing/invalid tokens, role enforcement |
| `tests/test_suppliers.py` | Full CRUD, duplicate detection, deletion guards |
| `tests/test_items.py` | Full CRUD, price validation, SKU uniqueness, supplier FK checks |
| `tests/test_orders.py` | CRUD, order total accuracy, all valid/invalid status transitions |
| `tests/test_workflows.py` | End-to-end chained workflows across all resources |

### Key Design Decisions
- **pytest fixtures with teardown** — every test cleans up after itself, no shared state pollution
- **Factory fixtures** (`make_supplier`, `make_item`, `make_order`) — reusable resource creation keeps tests concise
- **Environment config** — swap `ENV=staging` to run the full suite against a staging server
- **Docker Compose parity** — app and test runner behave identically locally and in CI
- **Chained workflow tests** — output of one API call feeds directly into the next, mirroring real integration testing

---

## Running Locally

### Prerequisites
- Docker + Docker Compose

### Start the app
```bash
docker compose up -d --build app
```

### Run the full test suite
```bash
docker compose run --rm tests pytest tests/ -v
```

### Run against staging
```bash
docker compose run --rm -e ENV=staging tests pytest tests/ -v
```

### Run a specific test file
```bash
docker compose run --rm tests pytest tests/test_workflows.py -v
```

### Run tests by marker
```bash
docker compose run --rm tests pytest -m auth -v
docker compose run --rm tests pytest -m workflow -v
```

---

## CI / CD

Every push to `main` and every pull request triggers the full test suite via GitHub Actions.

- ✅ Passing CI badge at the top of this README
- 📦 Downloadable HTML report + JUnit XML in Actions → Artifacts
- 🌐 Latest HTML report published to GitHub Pages

---

## Environment Configuration

Edit `config/settings.py` to add environments:

```python
ENVIRONMENTS = {
    "local":   "http://localhost:8000",
    "staging": "http://staging.your-app.com",
}
```

Set the target environment with the `ENV` variable:
```bash
ENV=staging pytest tests/ -v
```
