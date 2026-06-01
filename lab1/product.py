from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Product:
    id: Optional[int]
    name: str
    sku: str
    price: float
    quantity: int
    created_at: datetime
