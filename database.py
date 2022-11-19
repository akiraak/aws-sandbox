import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# SQLALCHEMY_DATABASE_URL = "sqlite:///./cabo_app.db"
SQLALCHEMY_DATABASE_URL = os.environ.get("SQLALCHEMY_DATABASE_URI")
# SQLALCHEMY_DATABASE_URL = "postgresql://user:password@postgresserver/db"

engine = None
if os.environ.get("SQLALCHEMY_CHECK_SAME_THREAD") == "True":
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={})
else:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
        # connect_args={"check_same_thread": False} is need only for SQLite
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
