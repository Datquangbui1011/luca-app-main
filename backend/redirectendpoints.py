# Password Reset Link Redirect Endpoints
# For Luca App - matches app branding

from fastapi import APIRouter, Query
from fastapi.responses import HTMLResponse
from typing import Optional

router = APIRouter(prefix="", tags=["redirects"])


@router.get("/reset")
async def reset_password_redirect(token: Optional[str] = Query(None)):
    """
    HTTP endpoint that redirects to the iOS app deep link
    This makes email links clickable in all email clients
    """
    if not token:
        # If no token, show an error page
        return HTMLResponse(content="""
        <html>
            <head>
                <title>Invalid Reset Link</title>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                        background: linear-gradient(135deg, #F5E8C7 0%, #D9B53E 100%);
                    }
                    .container {
                        background: white;
                        padding: 2rem;
                        border-radius: 10px;
                        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                        text-align: center;
                        max-width: 400px;
                    }
                    h1 { color: #333; }
                    p { color: #666; line-height: 1.6; }
                    .error { color: #e74c3c; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>❌ Invalid Reset Link</h1>
                    <p class="error">This password reset link is invalid or incomplete.</p>
                    <p>Please request a new password reset from the app.</p>
                </div>
            </body>
        </html>
        """, status_code=400)
    
    # Create the deep link for the app
    app_deep_link = f"lucaapp://reset-password?token={token}"
    
    # Create a fallback page with both automatic redirect and manual button
    html_content = f"""
    <html>
        <head>
            <title>Reset Your Password - Luca App</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <!-- Attempt to open the app immediately -->
            <meta http-equiv="refresh" content="0; url={app_deep_link}">
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #F5E8C7 0%, #D9B53E 100%);
                    padding: 20px;
                }}
                .container {{
                    background: white;
                    padding: 2rem;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    text-align: center;
                    max-width: 400px;
                    width: 100%;
                }}
                h1 {{
                    color: #333;
                    margin-bottom: 10px;
                }}
                p {{
                    color: #666;
                    line-height: 1.6;
                    margin: 10px 0;
                }}
                .button {{
                    display: inline-block;
                    padding: 12px 30px;
                    background: #D9B53E;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    margin-top: 20px;
                    font-weight: bold;
                    transition: background 0.3s;
                }}
                .button:hover {{
                    background: #c4a235;
                }}
                .token {{
                    background: #f4f4f4;
                    padding: 10px;
                    border-radius: 5px;
                    word-break: break-all;
                    font-family: monospace;
                    font-size: 12px;
                    margin-top: 20px;
                }}
                .instructions {{
                    margin-top: 30px;
                    padding-top: 20px;
                    border-top: 1px solid #e0e0e0;
                }}
                .small {{
                    font-size: 14px;
                    color: #999;
                }}
                .spinner {{
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #D9B53E;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 20px auto;
                }}
                @keyframes spin {{
                    0% {{ transform: rotate(0deg); }}
                    100% {{ transform: rotate(360deg); }}
                }}
            </style>
            <script>
                // Try to open the app
                window.onload = function() {{
                    // Try to open the app
                    window.location.href = "{app_deep_link}";
                    
                    // After 2 seconds, if still here, show instructions
                    setTimeout(function() {{
                        document.getElementById('manual-instructions').style.display = 'block';
                    }}, 2000);
                }}
            </script>
        </head>
        <body>
            <div class="container">
                <h1>🔐 Reset Your Password</h1>
                <div class="spinner"></div>
                <p>Opening the Luca app to reset your password...</p>
                
                <a href="{app_deep_link}" class="button">Open in Luca App</a>
                
                <div id="manual-instructions" style="display: none;" class="instructions">
                    <p class="small">If the app doesn't open automatically:</p>
                    <ol style="text-align: left; color: #666;">
                        <li>Make sure the Luca app is installed</li>
                        <li>Click the button above</li>
                        <li>Or copy this token and paste it in the app:</li>
                    </ol>
                    <div class="token">{token}</div>
                </div>
            </div>
        </body>
    </html>
    """
    
    return HTMLResponse(content=html_content)


@router.get("/reset/success")
async def reset_success():
    """
    Success page after password reset
    """
    return HTMLResponse(content="""
    <html>
        <head>
            <title>Password Reset Successful - Luca App</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #F5E8C7 0%, #D9B53E 100%);
                }
                .container {
                    background: white;
                    padding: 2rem;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    text-align: center;
                    max-width: 400px;
                }
                h1 { color: #333; }
                p { color: #666; line-height: 1.6; }
                .success { color: #27ae60; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>✅ Password Reset!</h1>
                <p class="success">Your password has been successfully reset.</p>
                <p>You can now log in with your new password.</p>
            </div>
        </body>
    </html>
    """)


# Optional: Add an endpoint to handle the reset directly via web
@router.get("/reset/form")
async def reset_form(token: str = Query(...)):
    """
    Web form for resetting password (backup option)
    """
    return HTMLResponse(content=f"""
    <html>
        <head>
            <title>Reset Password - Luca App</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #F5E8C7 0%, #D9B53E 100%);
                    padding: 20px;
                }}
                .container {{
                    background: white;
                    padding: 2rem;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                    width: 100%;
                    max-width: 400px;
                }}
                h1 {{
                    color: #333;
                    text-align: center;
                }}
                input {{
                    width: 100%;
                    padding: 10px;
                    margin: 10px 0;
                    border: 1px solid #ddd;
                    border-radius: 5px;
                    font-size: 16px;
                    box-sizing: border-box;
                }}
                button {{
                    width: 100%;
                    padding: 12px;
                    background: #D9B53E;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    font-size: 16px;
                    font-weight: bold;
                    cursor: pointer;
                    transition: background 0.3s;
                }}
                button:hover {{
                    background: #c4a235;
                }}
                .error {{
                    color: #e74c3c;
                    text-align: center;
                    margin: 10px 0;
                }}
                .or-divider {{
                    text-align: center;
                    margin: 20px 0;
                    color: #999;
                }}
                .app-link {{
                    display: block;
                    text-align: center;
                    padding: 12px;
                    background: #f4f4f4;
                    color: #333;
                    text-decoration: none;
                    border-radius: 5px;
                    margin-top: 10px;
                }}
                .app-link:hover {{
                    background: #e0e0e0;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔐 Reset Your Password</h1>
                <form onsubmit="resetPassword(event)">
                    <input type="password" id="password" placeholder="New Password" required minlength="6">
                    <input type="password" id="confirmPassword" placeholder="Confirm Password" required minlength="6">
                    <div id="error" class="error"></div>
                    <button type="submit">Reset Password</button>
                </form>
                
                <div class="or-divider">— OR —</div>
                
                <a href="lucaapp://reset-password?token={token}" class="app-link">
                    Open in Luca App
                </a>
            </div>
            
            <script>
                async function resetPassword(event) {{
                    event.preventDefault();
                    
                    const password = document.getElementById('password').value;
                    const confirmPassword = document.getElementById('confirmPassword').value;
                    const errorDiv = document.getElementById('error');
                    
                    if (password !== confirmPassword) {{
                        errorDiv.textContent = 'Passwords do not match';
                        return;
                    }}
                    
                    try {{
                        const response = await fetch('/auth/password/reset', {{
                            method: 'POST',
                            headers: {{
                                'Content-Type': 'application/json',
                            }},
                            body: JSON.stringify({{
                                token: '{token}',
                                new_password: password
                            }})
                        }});
                        
                        if (response.ok) {{
                            window.location.href = '/reset/success';
                        }} else {{
                            const data = await response.json();
                            errorDiv.textContent = data.detail || 'Failed to reset password';
                        }}
                    }} catch (error) {{
                        errorDiv.textContent = 'Network error. Please try again.';
                    }}
                }}
            </script>
        </body>
    </html>
    """)