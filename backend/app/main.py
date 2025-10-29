
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List as TList
import random

from . import models, schemas
from .database import Base, engine, SessionLocal

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Random Choice API", version="1.0.0")

# CORS (adjust in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Health check
@app.get("/health")
def health():
    return {"status": "ok"}

# Lists endpoints
@app.get("/lists", response_model=TList[schemas.ListOut])
def get_lists(db: Session = Depends(get_db)):
    return db.query(models.List).order_by(models.List.id.desc()).all()

@app.post("/lists", response_model=schemas.ListOut)
def create_list(payload: schemas.ListCreate, db: Session = Depends(get_db)):
    existing = db.query(models.List).filter(models.List.name == payload.name).first()
    if existing:
        raise HTTPException(status_code=409, detail="List with this name already exists")
    item = models.List(name=payload.name)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item

@app.get("/lists/{list_id}", response_model=schemas.ListWithChoices)
def get_list(list_id: int, db: Session = Depends(get_db)):
    item = db.query(models.List).filter(models.List.id == list_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="List not found")
    return item

@app.delete("/lists/{list_id}")
def delete_list(list_id: int, db: Session = Depends(get_db)):
    item = db.query(models.List).filter(models.List.id == list_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="List not found")
    db.delete(item)
    db.commit()
    return {"ok": True}

# Choices endpoints
@app.get("/lists/{list_id}/choices", response_model=TList[schemas.ChoiceOut])
def get_choices(list_id: int, db: Session = Depends(get_db)):
    parent = db.query(models.List).filter(models.List.id == list_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="List not found")
    return parent.choices

@app.post("/lists/{list_id}/choices", response_model=schemas.ChoiceOut)
def add_choice(list_id: int, payload: schemas.ChoiceCreate, db: Session = Depends(get_db)):
    parent = db.query(models.List).filter(models.List.id == list_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="List not found")
    choice = models.Choice(list_id=list_id, text=payload.text)
    db.add(choice)
    db.commit()
    db.refresh(choice)
    return choice

@app.delete("/choices/{choice_id}")
def delete_choice(choice_id: int, db: Session = Depends(get_db)):
    choice = db.query(models.Choice).filter(models.Choice.id == choice_id).first()
    if not choice:
        raise HTTPException(status_code=404, detail="Choice not found")
    db.delete(choice)
    db.commit()
    return {"ok": True}

# Random pick
@app.post("/lists/{list_id}/pick", response_model=schemas.ChoiceOut)
def pick_random(list_id: int, db: Session = Depends(get_db)):
    parent = db.query(models.List).filter(models.List.id == list_id).first()
    if not parent:
        raise HTTPException(status_code=404, detail="List not found")
    items = parent.choices
    if not items:
        raise HTTPException(status_code=400, detail="List has no choices")
    return random.choice(items)
