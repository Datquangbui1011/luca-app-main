# Admin routes for administrative tasks (debugging/testing)

from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from models import AccountResponse
from database import supabase
from dependencies import get_current_account

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/accounts", response_model=List[AccountResponse])
async def get_all_accounts(account_id: int = Depends(get_current_account)):
    # Retrieve all accounts (for debugging/testing).
    response = supabase.table("userAccount").select("id, name, email, phone, date_of_birth").execute()
    
    if not response.data:
        return []
    
    return [AccountResponse(**account) for account in response.data]