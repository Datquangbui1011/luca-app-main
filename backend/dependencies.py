# FastAPI dependencies for authentication and authorization

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from security import validate_token
from typing import Optional

security = HTTPBearer()

async def get_current_account(credentials: HTTPAuthorizationCredentials = Depends(security)) -> int:
    
    # Dependency to require authentication.
    # Use this in protected endpoints: account_id: int = Depends(get_current_account)
    # Validates the provided token and returns the associated account ID.
    
    token = credentials.credentials
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No authentication token provided",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    account_id: Optional[int] = validate_token(token)
    
    if not account_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    return account_id