# Pydantic models for request/response validation

from pydantic import BaseModel, EmailStr, validator
from typing import Optional
from datetime import datetime, date

class AccountCreate(BaseModel):
    name: str  # Full name (first and last combined)
    email: EmailStr
    phone: str
    date_of_birth: str  # Format: YYYY-MM-DD
    password: str
    
    @validator('name')
    def validate_name(cls, v):
        v = v.strip()
        if len(v) < 2:
            raise ValueError('Name must be at least 2 characters long')
        if len(v) > 100:
            raise ValueError('Name must be less than 100 characters')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one number')
        if not any(c.isalpha() for c in v):
            raise ValueError('Password must contain at least one letter')
        return v
    
    @validator('phone')
    def validate_phone(cls, v):
        cleaned = ''.join(c for c in v if c.isdigit())
        if len(cleaned) < 10:
            raise ValueError('Phone number must be at least 10 digits')
        return v
    
    @validator('date_of_birth')
    def validate_dob(cls, v):
        try:
            dob = datetime.strptime(v, '%Y-%m-%d').date()
            today = date.today()
            age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
            if age < 20:
                raise ValueError('You must be at least 20 years old to register')
            return v
        except ValueError as e:
            if 'does not match format' in str(e):
                raise ValueError('Date of birth must be in YYYY-MM-DD format')
            raise e

class AccountResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    date_of_birth: str

class AccountLogin(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    message: str
    token: str
    account: AccountResponse

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class TokenRequest(BaseModel):
    token: str

class PasswordResetRequest(BaseModel):
    token: str
    new_password: str
    
    @validator('new_password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one number')
        if not any(c.isalpha() for c in v):
            raise ValueError('Password must contain at least one letter')
        return v