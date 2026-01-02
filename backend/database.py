# Database connection and initialization for Luca App API

from supabase import create_client
from config import SUPABASE_URL, SUPABASE_KEY

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def init_database():
    # No automatic schema creation/migration - create tables manually in Supabase dashboard
    # Tables needed:
    # - userAccount (id serial PRIMARY KEY, name text NOT NULL, email text UNIQUE NOT NULL, phone text NOT NULL, date_of_birth text NOT NULL, password text NOT NULL)
    # - sessions (id serial PRIMARY KEY, account_id int REFERENCES "userAccount"(id), token text UNIQUE NOT NULL, expires_at timestamp NOT NULL)
    # - password_reset_tokens (id serial PRIMARY KEY, account_id int REFERENCES "userAccount"(id), token text UNIQUE NOT NULL, expires_at timestamp NOT NULL, used boolean DEFAULT false)
    # Create indexes as needed (e.g., on email, token)
    print("Connected to Supabase database")