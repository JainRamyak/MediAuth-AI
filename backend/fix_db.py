import socket
# Force IPv4
old_getaddrinfo = socket.getaddrinfo
def new_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    return old_getaddrinfo(host, port, socket.AF_INET, type, proto, flags)
socket.getaddrinfo = new_getaddrinfo

from sqlalchemy import text
from models.database import engine, Base
from models.user import User

with engine.connect() as conn:
    print("Executing raw SQL to forcefully drop and fix `users` table...")
    conn.execute(text("DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;"))
    conn.execute(text("DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;"))
    conn.execute(text("DROP FUNCTION IF EXISTS public.handle_user_sync();"))
    conn.execute(text("DROP TABLE IF EXISTS public.users CASCADE;"))
    conn.commit()
    
print("Creating tables using SQLAlchemy...")
Base.metadata.create_all(bind=engine)
print("Done!")
