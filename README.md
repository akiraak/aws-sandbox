# aws-sandbox

# How to use db migtation
```
$ alembic revision --autogenerate -m "create tables"
$ alembic upgrade head
$ alembic current
$ alembic history
```