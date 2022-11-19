from pydantic import BaseModel


class UserBase(BaseModel):
    login_id: str


class UserCreate(UserBase):
    password: str


class User(UserBase):
    id: int
    # organization: Organization

    class Config:
        orm_mode = True
