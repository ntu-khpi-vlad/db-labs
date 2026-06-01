from abc import ABC, abstractmethod
from typing import List, Optional

from product import Product


class BaseRepository(ABC):
    @abstractmethod
    def create(self, product: Product) -> Product:
        pass

    @abstractmethod
    def get_all(self, limit: int = 10, offset: int = 0) -> List[Product]:
        pass

    @abstractmethod
    def get_by_id(self, product_id: int) -> Optional[Product]:
        pass

    @abstractmethod
    def update(self, product_id: int, product: Product) -> Optional[Product]:
        pass

    @abstractmethod
    def delete(self, product_id: int) -> bool:
        pass
