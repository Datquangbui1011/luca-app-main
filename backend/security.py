# Security functions for password hashing, token generation, validation, and rate limiting

import bcrypt
import secrets
import time
from datetime import datetime, timedelta
from typing import Optional
from config import TOKEN_EXPIRY_DAYS
from database import supabase

# Rate limiting constants
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_SECONDS = 300  # 5 minutes

# In-memory storage for login attempts (in production, use Redis or database)
login_attempts = {}

def hash_password(password: str) -> bytes:
    """Hash a password using bcrypt with salt rounds of 12"""
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password_bytes, salt)

def verify_password(password: str, password_hash: bytes) -> bool:
    """Verify a password against a bcrypt hash"""
    password_bytes = password.encode('utf-8')
    return bcrypt.checkpw(password_bytes, password_hash)

def generate_token() -> str:
    """Generate a secure random token"""
    return secrets.token_urlsafe(32)

def generate_expiry(days: int = TOKEN_EXPIRY_DAYS) -> str:
    """Generate token expiration timestamp"""
    expiry = datetime.now() + timedelta(days=days)
    return expiry.isoformat()

def save_session(account_id: int, token: str, expires_at: str):
    """Save a session token to database"""
    supabase.table("sessions").insert({
        "account_id": account_id,
        "token": token,
        "expires_at": expires_at
    }).execute()

def validate_token(token: str) -> Optional[int]:
    """Validate a token and return account_id if valid, None if invalid or expired"""
    response = supabase.table("sessions").select("account_id").eq("token", token).gt("expires_at", datetime.now().isoformat()).execute()
    if response.data:
        return response.data[0]["account_id"]
    return None

def delete_session(token: str):
    """Delete a session (for logout)"""
    supabase.table("sessions").delete().eq("token", token).execute()

# Rate limiting functions
def check_rate_limit(identifier: str) -> bool:
    """
    Check if identifier has exceeded rate limit.
    Returns True if rate limit exceeded, False otherwise.
    """
    current_time = time.time()
    
    if identifier in login_attempts:
        attempts, last_attempt = login_attempts[identifier]
        
        # Reset if lockout period has passed
        if current_time - last_attempt > LOCKOUT_SECONDS:
            login_attempts[identifier] = (0, current_time)
            return False
        
        # Check if max attempts exceeded
        if attempts >= MAX_LOGIN_ATTEMPTS:
            return True
    
    return False

def increment_login_attempts(identifier: str):
    """Increment login attempt counter for an identifier"""
    current_time = time.time()
    
    if identifier in login_attempts:
        attempts, _ = login_attempts[identifier]
        login_attempts[identifier] = (attempts + 1, current_time)
    else:
        login_attempts[identifier] = (1, current_time)

def reset_login_attempts(identifier: str):
    """Reset login attempts on successful login"""
    if identifier in login_attempts:
        del login_attempts[identifier]

def get_lockout_time_remaining(identifier: str) -> int:
    """Get remaining lockout time in seconds"""
    if identifier in login_attempts:
        attempts, last_attempt = login_attempts[identifier]
        if attempts >= MAX_LOGIN_ATTEMPTS:
            elapsed = time.time() - last_attempt
            remaining = LOCKOUT_SECONDS - elapsed
            if remaining > 0:
                return int(remaining)
    return 0