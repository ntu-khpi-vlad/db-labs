from datetime import datetime

from memory_repository import MemoryRepository
from product import Product


def _read_float(prompt: str) -> float:
    while True:
        value = input(prompt).strip().replace(",", ".")
        try:
            return float(value)
        except ValueError:
            print("Введіть коректне число.")


def _read_int(prompt: str) -> int:
    while True:
        value = input(prompt).strip()
        try:
            return int(value)
        except ValueError:
            print("Введіть ціле число.")


def _print_product(product: Product) -> None:
    print(
        f"  id={product.id}, name={product.name!r}, sku={product.sku!r}, "
        f"price={product.price}, quantity={product.quantity}, "
        f"created_at={product.created_at.isoformat(sep=' ', timespec='seconds')}"
    )


def _create_product(repo: MemoryRepository) -> None:
    name = input("Назва: ").strip()
    sku = input("SKU: ").strip()
    price = _read_float("Ціна: ")
    quantity = _read_int("Кількість: ")
    draft = Product(
        id=None,
        name=name,
        sku=sku,
        price=price,
        quantity=quantity,
        created_at=datetime.now(),
    )
    created = repo.create(draft)
    print("Створено:")
    _print_product(created)


def _list_products(repo: MemoryRepository) -> None:
    offset = _read_int("Offset (зміщення): ")
    limit_input = input("Limit (Enter — 10): ").strip()
    limit = int(limit_input) if limit_input else 10
    products = repo.get_all(limit=limit, offset=offset)
    if not products:
        print("Записів не знайдено.")
        return
    print(f"Показано {len(products)} запис(ів) (offset={offset}, limit={limit}):")
    for product in products:
        _print_product(product)


def _update_product(repo: MemoryRepository) -> None:
    product_id = _read_int("ID товару: ")
    existing = repo.get_by_id(product_id)
    if existing is None:
        print("Товар не знайдено.")
        return
    print("Поточні дані:")
    _print_product(existing)
    name = input(f"Назва [{existing.name}]: ").strip() or existing.name
    sku = input(f"SKU [{existing.sku}]: ").strip() or existing.sku
    price_raw = input(f"Ціна [{existing.price}]: ").strip()
    price = float(price_raw.replace(",", ".")) if price_raw else existing.price
    qty_raw = input(f"Кількість [{existing.quantity}]: ").strip()
    quantity = int(qty_raw) if qty_raw else existing.quantity
    updated = repo.update(
        product_id,
        Product(
            id=product_id,
            name=name,
            sku=sku,
            price=price,
            quantity=quantity,
            created_at=existing.created_at,
        ),
    )
    print("Оновлено:")
    _print_product(updated)


def _delete_product(repo: MemoryRepository) -> None:
    product_id = _read_int("ID товару для видалення: ")
    if repo.delete(product_id):
        print("Видалено.")
    else:
        print("Товар не знайдено.")


def main() -> None:
    repo = MemoryRepository()
    actions = {
        "1": ("Створити товар", _create_product),
        "2": ("Список товарів (пагінація)", _list_products),
        "3": ("Оновити товар", _update_product),
        "4": ("Видалити товар", _delete_product),
    }

    print("=== Каталог товарів (Lab 1) ===")
    while True:
        print("\nМеню:")
        for key, (title, _) in actions.items():
            print(f"  {key}. {title}")
        print("  0. Вихід")
        choice = input("Оберіть дію: ").strip()
        if choice == "0":
            print("До побачення.")
            break
        action = actions.get(choice)
        if action is None:
            print("Невідома дія.")
            continue
        _, handler = action
        handler(repo)


if __name__ == "__main__":
    main()
