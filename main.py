from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import SessionLocal
import crud, schemas


app = FastAPI()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
async def root():
    return {"message": "Hello World!desuyo!！！！"}


@app.get("/user")
async def get_users(db: Session = Depends(get_db)):
    user = crud.get_user(db=db, user_id=1)
    return {"message": str(user)}
