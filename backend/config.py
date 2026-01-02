# Configuration settings for Luca App API

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add Supabase config
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://ykgltkxpnhqpncidqont.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrZ2x0a3hwbmhxcG5jaWRxb250Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYyMjMwNiwiZXhwIjoyMDc2MTk4MzA2fQ.DGd6D13A5IRgGjYE_L0tPhBZGz7fftqspxJeskj49Xc')

# SendGrid Configuration
SENDGRID_API_KEY = os.environ.get('SENDGRID_API_KEY')
EMAIL_FROM_ADDRESS = os.environ.get('EMAIL_FROM_ADDRESS', 'lucaapp12@gmail.com')
EMAIL_FROM_NAME = os.environ.get('EMAIL_FROM_NAME', 'Luca App Team')

# Web URL for email links (your Render URL or custom domain)
# This creates HTTPS links that work in email clients
# Examples: 
#   - Render: https://your-app.onrender.com
#   - Custom domain: https://lucaapp.com
WEB_URL = os.environ.get('WEB_URL', 'https://luca-app-dev.onrender.com')

# Deep link scheme for your iOS app
APP_SCHEME = 'lucaapp'

# API Configuration
API_TITLE = "Luca App API"
API_VERSION = "2.0.0"

# Security Constants
TOKEN_EXPIRY_DAYS = 30