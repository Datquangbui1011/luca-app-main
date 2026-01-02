"""
Email service for sending password reset emails using SendGrid
"""

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content
from config import SENDGRID_API_KEY, EMAIL_FROM_ADDRESS, EMAIL_FROM_NAME, WEB_URL


def send_reset_email(to_email: str, to_name: str, reset_link: str):
    """
    Send password reset email using SendGrid API.
    Uses HTTPS web link that redirects to app deep link.
    Works reliably on any hosting platform including Render.
    """
    # Extract token from deep link and create web URL
    # Input: lucaapp://reset-password?token=xxx
    # Output: https://your-domain.com/reset?token=xxx
    if "token=" in reset_link:
        token = reset_link.split("token=")[1]
        web_reset_link = f"{WEB_URL}/reset?token={token}"
    else:
        # Fallback if format is unexpected
        web_reset_link = reset_link
    
    # Check if SendGrid is configured
    if not SENDGRID_API_KEY:
        print("⚠️  SendGrid not configured - check .env file")
        print(f"   SENDGRID_API_KEY: {'✓ Set' if SENDGRID_API_KEY else '✗ Missing'}")
        print(f"\n   Web reset link (for manual testing): {web_reset_link}\n")
        print(f"   App deep link (for manual testing): {reset_link}\n")
        return
    
    try:
        print(f"\n📧 Sending password reset email via SendGrid...")
        print(f"   From: {EMAIL_FROM_NAME} <{EMAIL_FROM_ADDRESS}>")
        print(f"   To: {to_name} <{to_email}>")
        print(f"   Web Link: {web_reset_link}")
        
        # Create HTML content
        html_content = f'''
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .button {{ 
                    display: inline-block; 
                    padding: 12px 24px; 
                    background-color: #D9B53E; 
                    color: white !important; 
                    text-decoration: none; 
                    border-radius: 5px; 
                    margin: 20px 0;
                }}
                .footer {{ margin-top: 30px; font-size: 12px; color: #666; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Hi {to_name},</h2>
                <p>You requested to reset your password for your Luca App account.</p>
                <p>Click the button below to reset your password:</p>
                <a href="{web_reset_link}" class="button">Reset Password</a>
                <p>Or copy and paste this link:</p>
                <p style="word-break: break-all; color: #666; font-size: 12px;">{web_reset_link}</p>
                <p><strong>This link will expire in 1 hour.</strong></p>
                <p>If you didn't request this reset, please ignore this email.</p>
                <div class="footer">
                    <p>Thanks,<br>The Luca App Team</p>
                </div>
            </div>
        </body>
        </html>
        '''
        
        # Create plain text fallback
        text_content = f'''
        Hi {to_name},
        
        You requested to reset your password for your Luca App account.
        
        Click this link to reset your password:
        {web_reset_link}
        
        This link will expire in 1 hour.
        
        If you didn't request this reset, please ignore this email.
        
        Thanks,
        The Luca App Team
        '''
        
        # Create the email message
        message = Mail(
            from_email=Email(EMAIL_FROM_ADDRESS, EMAIL_FROM_NAME),
            to_emails=To(to_email, to_name),
            subject='Reset Your Luca App Password',
            plain_text_content=Content("text/plain", text_content),
            html_content=Content("text/html", html_content)
        )
        
        # Send email via SendGrid API
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"✅ Email sent successfully via SendGrid!")
        print(f"   Status Code: {response.status_code}")
        print(f"   Response: {response.body}\n")
        
    except Exception as e:
        print(f"❌ Error sending email via SendGrid: {str(e)}")
        print(f"   Type: {type(e).__name__}")
        print(f"\n   Web reset link (for manual testing): {web_reset_link}")
        print(f"   App deep link: {reset_link}\n")
        raise  # Re-raise to let the API endpoint handle it appropriately


def send_welcome_email(to_email: str, to_name: str):
    """
    Send welcome email to new users using SendGrid API.
    """
    # Check if SendGrid is configured
    if not SENDGRID_API_KEY:
        print("⚠️  SendGrid not configured - check .env file")
        print(f"   SENDGRID_API_KEY: {'✓ Set' if SENDGRID_API_KEY else '✗ Missing'}")
        print(f"\n   Welcome email not sent to {to_email}\n")
        return
    
    try:
        print(f"\n📧 Sending welcome email via SendGrid...")
        print(f"   From: {EMAIL_FROM_NAME} <{EMAIL_FROM_ADDRESS}>")
        print(f"   To: {to_name} <{to_email}>")
        
        # Create HTML content
        html_content = f'''
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #D9B53E; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }}
                .content {{ background-color: #f9f9f9; padding: 20px; }}
                .footer {{ margin-top: 30px; font-size: 12px; color: #666; text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to Luca App!</h1>
                </div>
                <div class="content">
                    <h2>Hi {to_name},</h2>
                    <p>Thank you for joining Luca App! We're excited to have you on board.</p>
                    <p>Your account has been successfully created and you can now:</p>
                    <ul>
                        <li>Track your finances</li>
                        <li>Manage your budget</li>
                        <li>View detailed analytics</li>
                    </ul>
                    <p>If you have any questions or need assistance, feel free to reach out to our support team.</p>
                </div>
                <div class="footer">
                    <p>Thanks,<br>The Luca App Team</p>
                </div>
            </div>
        </body>
        </html>
        '''
        
        # Create plain text fallback
        text_content = f'''
        Welcome to Luca App!
        
        Hi {to_name},
        
        Thank you for joining Luca App! We're excited to have you on board.
        
        Your account has been successfully created and you can now:
        - Track your finances
        - Manage your budget
        - View detailed analytics
        
        If you have any questions or need assistance, feel free to reach out to our support team.
        
        Thanks,
        The Luca App Team
        '''
        
        # Create the email message
        message = Mail(
            from_email=Email(EMAIL_FROM_ADDRESS, EMAIL_FROM_NAME),
            to_emails=To(to_email, to_name),
            subject='Welcome to Luca App!',
            plain_text_content=Content("text/plain", text_content),
            html_content=Content("text/html", html_content)
        )
        
        # Send email via SendGrid API
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        response = sg.send(message)
        
        print(f"✅ Welcome email sent successfully via SendGrid!")
        print(f"   Status Code: {response.status_code}")
        print(f"   Response: {response.body}\n")
        
    except Exception as e:
        print(f"❌ Error sending welcome email via SendGrid: {str(e)}")
        print(f"   Type: {type(e).__name__}\n")
        # Don't raise - welcome email is nice-to-have, not critical