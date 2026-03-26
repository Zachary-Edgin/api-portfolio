from sqlalchemy import create_engine, Column, Integer, String, Float, ForeignKey, Enum
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
import enum

DATABASE_URL = "sqlite:///./procurement.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class OrderStatus(str, enum.Enum):
    pending   = "pending"
    approved  = "approved"
    shipped   = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"


class Supplier(Base):
    __tablename__ = "suppliers"

    id       = Column(Integer, primary_key=True, index=True)
    name     = Column(String, unique=True, nullable=False)
    email    = Column(String, unique=True, nullable=False)
    country  = Column(String, nullable=False)
    active   = Column(Integer, default=1)   # 1 = active, 0 = inactive

    items  = relationship("Item", back_populates="supplier")
    orders = relationship("PurchaseOrder", back_populates="supplier")


class Item(Base):
    __tablename__ = "items"

    id          = Column(Integer, primary_key=True, index=True)
    name        = Column(String, nullable=False)
    sku         = Column(String, unique=True, nullable=False)
    unit_price  = Column(Float, nullable=False)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"), nullable=False)

    supplier       = relationship("Supplier", back_populates="items")
    order_lines    = relationship("OrderLine", back_populates="item")


class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"

    id          = Column(Integer, primary_key=True, index=True)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"), nullable=False)
    status      = Column(Enum(OrderStatus), default=OrderStatus.pending)
    total       = Column(Float, default=0.0)

    supplier = relationship("Supplier", back_populates="orders")
    lines    = relationship("OrderLine", back_populates="order", cascade="all, delete-orphan")


class OrderLine(Base):
    __tablename__ = "order_lines"

    id       = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("purchase_orders.id"), nullable=False)
    item_id  = Column(Integer, ForeignKey("items.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    subtotal = Column(Float, nullable=False)

    order = relationship("PurchaseOrder", back_populates="lines")
    item  = relationship("Item", back_populates="order_lines")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    Base.metadata.create_all(bind=engine)
