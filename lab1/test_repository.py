from datetime import datetime

import pytest

from memory_repository import MemoryRepository
from product import Product


@pytest.fixture
def repo() -> MemoryRepository:
    return MemoryRepository()


def _make_product(name: str, sku: str) -> Product:
    return Product(
        id=None,
        name=name,
        sku=sku,
        price=10.0,
        quantity=1,
        created_at=datetime(2026, 1, 1, 12, 0, 0),
    )


def test_create_assigns_id_and_stores(repo: MemoryRepository) -> None:
    created = repo.create(_make_product("Молоко", "SKU-001"))
    assert created.id == 1
    assert created.name == "Молоко"
    assert created.sku == "SKU-001"
    assert repo.get_by_id(1) == created


def test_get_all_pagination(repo: MemoryRepository) -> None:
    for i in range(15):
        repo.create(_make_product(f"Товар {i}", f"SKU-{i:03d}"))

    page1 = repo.get_all(limit=10, offset=0)
    page2 = repo.get_all(limit=10, offset=10)

    assert len(page1) == 10
    assert len(page2) == 5
    assert page1[0].id == 1
    assert page1[-1].id == 10
    assert page2[0].id == 11
    assert page2[-1].id == 15


def test_update_changes_fields(repo: MemoryRepository) -> None:
    created = repo.create(_make_product("Хліб", "SKU-BREAD"))
    updated = repo.update(
        created.id,
        Product(
            id=created.id,
            name="Бородинський",
            sku="SKU-BREAD-2",
            price=25.5,
            quantity=3,
            created_at=created.created_at,
        ),
    )
    assert updated is not None
    assert updated.name == "Бородинський"
    assert updated.price == 25.5
    assert updated.quantity == 3
    assert updated.created_at == created.created_at


def test_update_missing_returns_none(repo: MemoryRepository) -> None:
    result = repo.update(
        999,
        Product(
            id=999,
            name="X",
            sku="X",
            price=1.0,
            quantity=1,
            created_at=datetime.now(),
        ),
    )
    assert result is None


def test_delete_removes_product(repo: MemoryRepository) -> None:
    created = repo.create(_make_product("Сир", "SKU-CHEESE"))
    assert repo.delete(created.id) is True
    assert repo.get_by_id(created.id) is None
    assert repo.delete(created.id) is False


def test_get_all_empty_repo(repo: MemoryRepository) -> None:
    assert repo.get_all(limit=10, offset=0) == []
