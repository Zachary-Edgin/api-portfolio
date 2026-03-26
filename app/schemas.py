from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List
from app.database import OrderStatus


# ── Auth ──────────────────────────────────────────────────────────────────────

class TokenResponse(BaseModel):
    access_token: str
    token_type: str


# ── Supplier ──────────────────────────────────────────────────────────────────

class SupplierCreate(BaseModel):
    name: str
    email: EmailStr
    country: str

class SupplierUpdate(BaseModel):
    name:    Optional[str]   = None
    email:   Optional[EmailStr] = None
    country: Optional[str]  = None
    active:  Optional[int]  = None

class SupplierResponse(BaseModel):
    id:      int
    name:    str
    email:   str
    country: str
    active:  int

    model_config = {"from_attributes": True}


# ── Item ──────────────────────────────────────────────────────────────────────

class ItemCreate(BaseModel):
    name:        str
    sku:         str
    unit_price:  float
    supplier_id: int

    @field_validator("unit_price")
    @classmethod
    def price_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("unit_price must be greater than 0")
        return v

class ItemUpdate(BaseModel):
    name:       Optional[str]   = None
    unit_price: Optional[float] = None

class ItemResponse(BaseModel):
    id:          int
    name:        str
    sku:         str
    unit_price:  float
    supplier_id: int

    model_config = {"from_attributes": True}


# ── Order ─────────────────────────────────────────────────────────────────────

class OrderLineCreate(BaseModel):
    item_id:  int
    quantity: int

    @field_validator("quantity")
    @classmethod
    def qty_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("quantity must be greater than 0")
        return v

class OrderLineResponse(BaseModel):
    id:       int
    item_id:  int
    quantity: int
    subtotal: float

    model_config = {"from_attributes": True}

class OrderCreate(BaseModel):
    supplier_id: int
    lines:       List[OrderLineCreate]

class OrderStatusUpdate(BaseModel):
    status: OrderStatus

class OrderResponse(BaseModel):
    id:          int
    supplier_id: int
    status:      OrderStatus
    total:       float
    lines:       List[OrderLineResponse] = []

    model_config = {"from_attributes": True}
