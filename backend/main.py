# Main application file that brings together all modules.

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import API_TITLE, API_VERSION, SENDGRID_API_KEY, EMAIL_FROM_ADDRESS
from database import init_database

# Import routers
from routes import auth, accounts, admin
import redirectendpoints

# Create FastAPI app
app = FastAPI(title=API_TITLE, version=API_VERSION)

# CORS middleware to allow iOS app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(accounts.router)
app.include_router(admin.router)
app.include_router(redirectendpoints.router)  # Web redirects for email links

@app.get("/")
async def root():
    return {
        "message": "Welcome to Luca App API",
        "version": API_VERSION,
        "status": "running",
        "security": "enabled",
        "email_configured": bool(SENDGRID_API_KEY),
    }

@app.get("/health")
def health_check():
    """Health check endpoint for monitoring"""    
    return {
        "status": "healthy",
        "email_service": "sendgrid" if SENDGRID_API_KEY else "not_configured"
    }

@app.on_event("startup")
async def startup_event():
    """Initialize database and check configuration on startup"""
    init_database()
    print("\n" + "="*60)
    print("🚀 Luca App API Starting...")
    print("="*60)
    print(f"📦 Version: {API_VERSION}")
    print(f"🔐 Security: Enabled")
    
    # Check SendGrid configuration
    if SENDGRID_API_KEY:
        print(f"📧 Email Service: SendGrid ✅")
        print(f"   From: {EMAIL_FROM_ADDRESS}")
    else:
        print(f"⚠️  Email Service: NOT CONFIGURED")
        print(f"   Set SENDGRID_API_KEY in your .env file")
        print(f"   See SENDGRID_SETUP_GUIDE.md for instructions")
    
    print("="*60)
    print("✅ Luca App API started successfully")
    print("📚 API docs available at: http://localhost:6769/docs")
    print("="*60 + "\n")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print("\n👋 Luca App API shutting down...")

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 6769))
    uvicorn.run(app, host="0.0.0.0", port=port)