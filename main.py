from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Test App", version="1.0.0")


class Item(BaseModel):
    name: str
    description: str | None = None
    price: float


@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI test app!"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}


@app.post("/items")
def create_item(item: Item):
    return {"message": "Item created", "item": item}
