# Authentication routes: register, login, logout, password reset

from fastapi import APIRouter, HTTPException, Depends, status
from datetime import datetime, timedelta
import secrets
import binascii

from models import (
    AccountCreate, AccountLogin, LoginResponse, 
    ForgotPasswordRequest, PasswordResetRequest, TokenRequest
)
from database import supabase
from security import (
    hash_password, verify_password, generate_token, generate_expiry,
    save_session, delete_session, check_rate_limit, increment_login_attempts, 
    reset_login_attempts, get_lockout_time_remaining, LOCKOUT_SECONDS
)
from emailservice import send_reset_email, send_welcome_email
from dependencies import get_current_account

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=LoginResponse, status_code=201)
async def register(account: AccountCreate):
    print(f"\n📝 Registration attempt for: {account.email}")
    
    response = supabase.table("userAccount").select("id").eq("email", account.email).execute()
    if response.data:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
        
    password_hash = hash_password(account.password)
    password_hash_str = binascii.hexlify(password_hash).decode()
    
    insert_data = {
        "name": account.name,
        "email": account.email,
        "phone": account.phone,
        "date_of_birth": account.date_of_birth,
        "password": password_hash_str
    }
    
    resp = supabase.table("userAccount").insert(insert_data).execute()
    account_id = resp.data[0]["id"]
    print(f"✅ Account created with ID: {account_id}")
    
    token = generate_token()
    expires_at = generate_expiry()
    save_session(account_id, token, expires_at)
    
    resp = supabase.table("userAccount").select("id, name, email, phone, date_of_birth").eq("id", account_id).execute()
    created_account = resp.data[0]
    
    # Optionally send welcome email (non-blocking)
    try:
        send_welcome_email(account.email, account.name)
    except Exception as e:
        print(f"Warning: Could not send welcome email: {e}")
    
    return {
        "message": "Account created successfully",
        "token": token,
        "account": created_account
    }

@router.post("/login", response_model=LoginResponse)
async def login(credentials: AccountLogin):
    print(f"\n🔑 Login attempt for: {credentials.email}")
    
    # Check rate limiting
    if check_rate_limit(credentials.email):
        lockout_remaining = get_lockout_time_remaining(credentials.email)
        lockout_minutes = (lockout_remaining + 59) // 60  # Round up to next minute
        raise HTTPException(
            status_code=429,
            detail=f"Too many failed login attempts. Try again in {lockout_minutes} minute(s)."
        )
    
    response = supabase.table("userAccount").select("id, name, email, phone, password, date_of_birth").eq("email", credentials.email).execute()
    
    if not response.data:
        print(f"❌ No account found for: {credentials.email}")
        increment_login_attempts(credentials.email)
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )
        
    account = response.data[0]
    print(f"✓ Account found - ID: {account['id']}")
    
    stored_password = account['password']
    print(f"Stored password (first 20 chars): {stored_password[:20] if len(stored_password) > 20 else stored_password}...")
    print(f"Stored password length: {len(stored_password)}")
    
    # Check if password is stored as plain text (legacy) or hashed (proper)
    password_valid = False
    
    if len(stored_password) == 120:
        # Proper bcrypt hash (hex-encoded, 120 characters)
        print("Detected hashed password (120 chars)")
        try:
            stored_hash = binascii.unhexlify(stored_password)
            password_valid = verify_password(credentials.password, stored_hash)
            print(f"Hash verification result: {password_valid}")
        except binascii.Error as e:
            print(f"Error decoding hex hash: {e}")
            password_valid = False
    else:
        # Legacy plain text password (should be upgraded)
        password_valid = (credentials.password == stored_password)
        
        # If login succeeds with plain text password, automatically upgrade to hashed
        if password_valid:
            print("⚠️ Upgrading plain text password to bcrypt hash")
            new_hash = hash_password(credentials.password)
            new_hash_str = binascii.hexlify(new_hash).decode()
            supabase.table("userAccount").update({
                'password': new_hash_str
            }).eq("id", account['id']).execute()
            print("✅ Password upgraded to bcrypt hash")
    
    if not password_valid:
        print(f"❌ Password verification failed for: {credentials.email}")
        increment_login_attempts(credentials.email)
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )
    
    print(f"✅ Login successful for: {credentials.email}")
    
    # Reset rate limiting on successful login
    reset_login_attempts(credentials.email)
    
    # Update last login timestamp (if table has this column)
    try:
        supabase.table("userAccount").update({
            'last_login': datetime.now().isoformat()
        }).eq("id", account['id']).execute()
    except Exception:
        pass  # Column may not exist in the database
    
    token = generate_token()
    expires_at = generate_expiry()
    save_session(account['id'], token, expires_at)
    
    account_dict = {k: v for k, v in account.items() if k != 'password'}
    
    return {
        "message": "Login successful",
        "token": token,
        "account": account_dict
    }

@router.post("/logout")
async def logout(account_id: int = Depends(get_current_account)):
    """
    Logout current user by invalidating their token.
    Requires: Authorization header with Bearer token
    """
    return {"message": "Logout successful"}

@router.post("/logout/token")
async def logout_with_token(request: TokenRequest):
    """
    Alternative logout endpoint that accepts token in request body.
    Use this if you prefer sending token in body instead of header.
    """
    delete_session(request.token)
    return {"message": "Logout successful"}

@router.post("/password/forgot")
async def forgot_password(request: ForgotPasswordRequest):
    """
    Request password reset. Generates token, stores in database, and sends email.
    """
    response = supabase.table("userAccount").select("id, email, name").eq("email", request.email).execute()
    
    if response.data:
        account = response.data[0]
        
        # Delete any old unused tokens for this account
        supabase.table("password_reset_tokens").delete().eq("account_id", account['id']).eq("used", False).execute()
        
        # Generate secure reset token
        reset_token = secrets.token_urlsafe(32)
        expires_at = (datetime.now() + timedelta(hours=1)).isoformat()
        
        # Save new token to database
        supabase.table("password_reset_tokens").insert({
            "account_id": account['id'],
            "token": reset_token,
            "expires_at": expires_at
        }).execute()
        
        # Build reset link (can be configured for deep link or HTTPS redirect)
        reset_link = f"lucaapp://reset-password?token={reset_token}"
        
        print(f"\n🔐 Password Reset Requested")
        print(f"   Email: {account['email']}")
        print(f"   Name: {account['name']}")
        print(f"   Reset Token: {reset_token}")
        print(f"   Reset Link: {reset_link}")
        print(f"   Expires: {datetime.now() + timedelta(hours=1)}")
        
        # Send email with reset link
        send_reset_email(
            to_email=account['email'],
            to_name=account['name'],
            reset_link=reset_link
        )
    else:
        print(f"\n⚠️ Password reset requested for non-existent email: {request.email}")
    
    # Always return same message (security best practice)
    return {
        "message": "If this email exists, a reset link has been sent."
    }

@router.post("/password/reset")
async def reset_password(request: PasswordResetRequest):
    """
    Reset password using a valid reset token.
    Token must be unused and not expired.
    """
    print(f"\n🔑 Password reset attempt with token: {request.token[:10]}...")
    
    resp = supabase.table("password_reset_tokens").select("id, account_id, expires_at, used").eq("token", request.token).execute()
    
    if not resp.data:
        print(f"❌ Invalid token")
        raise HTTPException(
            status_code=400,
            detail="Invalid reset token"
        )
    
    token_record = resp.data[0]
    
    # Check if token already used
    if token_record['used']:
        print(f"❌ Token already used")
        raise HTTPException(
            status_code=400,
            detail="Reset token has already been used"
        )
    
    # Check token expiration
    expires_at = datetime.fromisoformat(token_record['expires_at'])
    if datetime.now() > expires_at:
        print(f"❌ Token expired at {expires_at}")
        raise HTTPException(
            status_code=400,
            detail="Reset token has expired. Please request a new reset link."
        )
    
    # Get account info for logging
    resp_a = supabase.table("userAccount").select("email, name").eq("id", token_record['account_id']).execute()
    if not resp_a.data:
        raise HTTPException(status_code=400, detail="Invalid reset token")
    account = resp_a.data[0]
    
    print(f"✓ Valid token for: {account['email']}")
    
    # Hash the new password
    new_password_hash = hash_password(request.new_password)
    new_password_hash_str = binascii.hexlify(new_password_hash).decode()
    
    # Update the password
    supabase.table("userAccount").update({'password': new_password_hash_str}).eq("id", token_record['account_id']).execute()
    
    # Mark token as used
    supabase.table("password_reset_tokens").update({'used': True}).eq("id", token_record['id']).execute()
    
    # Delete all active sessions for this account (force re-login everywhere)
    supabase.table("sessions").delete().eq("account_id", token_record['account_id']).execute()
    
    print(f"✅ Password reset successful for: {account['email']}")
    print(f"   All sessions deleted (user must re-login)")
    
    return {
        "message": "Password reset successfully. Please log in with your new password."
    }