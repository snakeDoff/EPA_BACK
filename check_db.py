import re
import psycopg2

from app.core.config import settings

url = settings.sqlalchemy_database_uri.replace("postgresql+psycopg2://", "")
m = re.match(r"([^:]+):([^@]+)@([^:]+):(\d+)/(.+)", url)

if not m:
    raise ValueError(f"Не смог разобрать DATABASE_URL: {settings.sqlalchemy_database_uri}")

user, password, host, port, db = m.groups()

conn = psycopg2.connect(
    host=host,
    port=port,
    dbname=db,
    user=user,
    password=password,
)

cur = conn.cursor()
cur.execute("select current_database(), current_schema(), current_user;")
print("DB/Schema/User:", cur.fetchone())

cur.execute("""
select schemaname, tablename
from pg_tables
where schemaname not in ('pg_catalog', 'information_schema')
order by schemaname, tablename
""")
print("Tables:")
for row in cur.fetchall():
    print(row)

conn.close()