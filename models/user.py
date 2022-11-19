from sqlalchemy import Column, Integer, String
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    login_id = Column(String(120), unique=True, index=True)
    hashed_password = Column(String(120))

    def __str__(self):
        return f"{self.id}#{self.login_id}"
