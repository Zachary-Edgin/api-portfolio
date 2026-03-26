from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db, Supplier, Item, PurchaseOrder, OrderLine, OrderStatus
from app.schemas import (
    TokenResponse, SupplierCreate, SupplierUpdate, SupplierResponse,
    ItemCreate, ItemUpdate, ItemResponse,
    OrderCreate, OrderStatusUpdate, OrderResponse,
)
from app.auth import verify_password, create_access_token, get_current_user, require_admin, USERS

router = APIRouter()


# ── Auth ──────────────────────────────────────────────────────────────────────

@router.post("/auth/login", response_model=TokenResponse, tags=["auth"])
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = USERS.get(form_data.username)
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token({"sub": user["username"]})
    return {"access_token": token, "token_type": "bearer"}


@router.get("/auth/me", tags=["auth"])
def me(current_user: dict = Depends(get_current_user)):
    return {"username": current_user["username"], "role": current_user["role"]}


# ── Suppliers ─────────────────────────────────────────────────────────────────

@router.get("/suppliers", response_model=list[SupplierResponse], tags=["suppliers"])
def list_suppliers(db: Session = Depends(get_db), _=Depends(get_current_user)):
    return db.query(Supplier).all()


@router.post("/suppliers", response_model=SupplierResponse, status_code=201, tags=["suppliers"])
def create_supplier(payload: SupplierCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if db.query(Supplier).filter(Supplier.email == payload.email).first():
        raise HTTPException(status_code=409, detail="Supplier with this email already exists")
    supplier = Supplier(**payload.model_dump())
    db.add(supplier)
    db.commit()
    db.refresh(supplier)
    return supplier


@router.get("/suppliers/{supplier_id}", response_model=SupplierResponse, tags=["suppliers"])
def get_supplier(supplier_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier


@router.patch("/suppliers/{supplier_id}", response_model=SupplierResponse, tags=["suppliers"])
def update_supplier(supplier_id: int, payload: SupplierUpdate, db: Session = Depends(get_db), _=Depends(require_admin)):
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(supplier, field, value)
    db.commit()
    db.refresh(supplier)
    return supplier


@router.delete("/suppliers/{supplier_id}", status_code=204, tags=["suppliers"])
def delete_supplier(supplier_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    supplier = db.get(Supplier, supplier_id)
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    active_orders = db.query(PurchaseOrder).filter(
        PurchaseOrder.supplier_id == supplier_id,
        PurchaseOrder.status.notin_([OrderStatus.delivered, OrderStatus.cancelled])
    ).count()
    if active_orders:
        raise HTTPException(status_code=409, detail="Cannot delete supplier with active orders")
    db.delete(supplier)
    db.commit()


# ── Items ─────────────────────────────────────────────────────────────────────

@router.get("/items", response_model=list[ItemResponse], tags=["items"])
def list_items(db: Session = Depends(get_db), _=Depends(get_current_user)):
    return db.query(Item).all()


@router.post("/items", response_model=ItemResponse, status_code=201, tags=["items"])
def create_item(payload: ItemCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if not db.get(Supplier, payload.supplier_id):
        raise HTTPException(status_code=404, detail="Supplier not found")
    if db.query(Item).filter(Item.sku == payload.sku).first():
        raise HTTPException(status_code=409, detail="SKU already exists")
    item = Item(**payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/items/{item_id}", response_model=ItemResponse, tags=["items"])
def get_item(item_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    item = db.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.patch("/items/{item_id}", response_model=ItemResponse, tags=["items"])
def update_item(item_id: int, payload: ItemUpdate, db: Session = Depends(get_db), _=Depends(require_admin)):
    item = db.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/items/{item_id}", status_code=204, tags=["items"])
def delete_item(item_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    item = db.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()


# ── Purchase Orders ───────────────────────────────────────────────────────────

@router.get("/orders", response_model=list[OrderResponse], tags=["orders"])
def list_orders(db: Session = Depends(get_db), _=Depends(get_current_user)):
    return db.query(PurchaseOrder).all()


@router.post("/orders", response_model=OrderResponse, status_code=201, tags=["orders"])
def create_order(payload: OrderCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if not db.get(Supplier, payload.supplier_id):
        raise HTTPException(status_code=404, detail="Supplier not found")

    order = PurchaseOrder(supplier_id=payload.supplier_id)
    db.add(order)
    db.flush()

    total = 0.0
    for line in payload.lines:
        item = db.get(Item, line.item_id)
        if not item:
            raise HTTPException(status_code=404, detail=f"Item {line.item_id} not found")
        if item.supplier_id != payload.supplier_id:
            raise HTTPException(status_code=422, detail=f"Item {line.item_id} does not belong to this supplier")
        subtotal = round(item.unit_price * line.quantity, 2)
        total += subtotal
        db.add(OrderLine(order_id=order.id, item_id=item.id, quantity=line.quantity, subtotal=subtotal))

    order.total = round(total, 2)
    db.commit()
    db.refresh(order)
    return order


@router.get("/orders/{order_id}", response_model=OrderResponse, tags=["orders"])
def get_order(order_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    order = db.get(PurchaseOrder, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


# Valid status transitions
TRANSITIONS = {
    OrderStatus.pending:   [OrderStatus.approved, OrderStatus.cancelled],
    OrderStatus.approved:  [OrderStatus.shipped,  OrderStatus.cancelled],
    OrderStatus.shipped:   [OrderStatus.delivered],
    OrderStatus.delivered: [],
    OrderStatus.cancelled: [],
}

@router.patch("/orders/{order_id}/status", response_model=OrderResponse, tags=["orders"])
def update_order_status(order_id: int, payload: OrderStatusUpdate, db: Session = Depends(get_db), _=Depends(require_admin)):
    order = db.get(PurchaseOrder, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if payload.status not in TRANSITIONS[order.status]:
        raise HTTPException(
            status_code=422,
            detail=f"Cannot transition from '{order.status}' to '{payload.status}'"
        )
    order.status = payload.status
    db.commit()
    db.refresh(order)
    return order


@router.delete("/orders/{order_id}", status_code=204, tags=["orders"])
def delete_order(order_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    order = db.get(PurchaseOrder, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.status not in [OrderStatus.pending, OrderStatus.cancelled]:
        raise HTTPException(status_code=409, detail="Only pending or cancelled orders can be deleted")
    db.delete(order)
    db.commit()
