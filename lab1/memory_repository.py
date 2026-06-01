from datetime import datetime
from typing import Dict, List, Optional

from base_repository import BaseRepository
from product import Product


class MemoryRepository(BaseRepository):
    def __init__(self) -> None:
        self._storage: Dict[int, Product] = {}
        self._next_id: int = 1

    def create(self, product: Product) -> Product:
        product_id = self._next_id
        self._next_id += 1
        created = Product(
            id=product_id,
            name=product.name,
            sku=product.sku,
            price=product.price,
            quantity=product.quantity,
            created_at=product.created_at or datetime.now(),
        )
        self._storage[product_id] = created
        return created

    def get_all(self, limit: int = 10, offset: int = 0) -> List[Product]:
        items = sorted(self._storage.values(), key=lambda p: p.id or 0)
        return items[offset : offset + limit]

    def get_by_id(self, product_id: int) -> Optional[Product]:
        return self._storage.get(product_id)

    def update(self, product_id: int, product: Product) -> Optional[Product]:
        if product_id not in self._storage:
            return None
        existing = self._storage[product_id]
        updated = Product(
            id=product_id,
            name=product.name,
            sku=product.sku,
            price=product.price,
            quantity=product.quantity,
            created_at=existing.created_at,
        )
        self._storage[product_id] = updated
        return updated

    def delete(self, product_id: int) -> bool:
        if product_id not in self._storage:
            return False
        del self._storage[product_id]
        return True
