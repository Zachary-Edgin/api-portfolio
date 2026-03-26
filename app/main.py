from fastapi import FastAPI
from app.database import init_db
from app.routes import router

app = FastAPI(
    title="Procurement API",
    description="Portfolio demo API — suppliers, items, and purchase orders with JWT auth.",
    version="1.0.0",
)

@app.on_event("startup")
def on_startup():
    init_db()

app.include_router(router)
