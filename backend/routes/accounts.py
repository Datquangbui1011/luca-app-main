# Account management routes: get, update, delete accounts

from fastapi import APIRouter, HTTPException, Depends
from typing import Optional

from models import AccountResponse
from database import supabase
from dependencies import get_current_account

router = APIRouter(prefix="/accounts", tags=["Accounts"])

@router.get("/me", response_model=AccountResponse)
async def get_my_account(account_id: int = Depends(get_current_account)):
    response = supabase.table("userAccount").select("id, name, email, phone, date_of_birth").eq("id", account_id).execute()
    
    if not response.data:
        raise HTTPException(status_code=404, detail="Account not found")
    
    account = response.data[0]
    return account

@router.put("/me")
async def update_my_account(
    name: Optional[str] = None, 
    phone: Optional[str] = None,
    account_id: int = Depends(get_current_account)):
    
    if not name and not phone:
        raise HTTPException(
            status_code=400,
            detail="Provide at least one field to update (name or phone)"
        )
    
    updates = {}
    if name:
        updates["name"] = name
    if phone:
        updates["phone"] = phone
    
    supabase.table("userAccount").update(updates).eq("id", account_id).execute()
    
    response = supabase.table("userAccount").select("id, name, email, phone, date_of_birth").eq("id", account_id).execute()
    updated_account = response.data[0]
    
    return {
        "message": "Account updated successfully",
        "account": updated_account
    }

@router.get("/{account_id}", response_model=AccountResponse)
async def get_account(account_id: int, current_account_id: int = Depends(get_current_account)):
    if account_id != current_account_id:
        raise HTTPException(
            status_code=403,
            detail="You can only view your own account"
        )
    
    response = supabase.table("userAccount").select("id, name, email, phone, date_of_birth").eq("id", account_id).execute()
    
    if not response.data:
        raise HTTPException(status_code=404, detail="Account not found")
    
    account = response.data[0]
    return account

@router.delete("/{account_id}")
async def delete_account(
    account_id: int,
    current_account_id: int = Depends(get_current_account)):
    if account_id != current_account_id:
        raise HTTPException(
            status_code=403,
            detail="You can only delete your own account"
        )
    
    resp = supabase.table("userAccount").select("id").eq("id", account_id).execute()
    if not resp.data:
        raise HTTPException(status_code=404, detail="Account not found")
    
    supabase.table("sessions").delete().eq("account_id", account_id).execute()
    supabase.table("userAccount").delete().eq("id", account_id).execute()
    
    return {"message": "Account deleted successfully"}