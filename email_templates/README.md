# Firebase Custom Email Templates

This directory contains HTML templates for customizing your Firebase Authentication emails.

## Email Verification Template

To use the custom email verification template:

1. Log in to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`realestate-cd6fb`)
3. Go to Authentication → Templates
4. Select the "Email verification" template
5. Enable "Customize email template"
6. Fill in the following information:
   - **Email subject**: Verify Your Email for Heaven Properties
   - **Custom redirect URL** (optional): Your app URL or website
   - **Email body**: Copy and paste the entire HTML content from `verification_email_template.html`
   
7. **IMPORTANT**: Before saving the template:
   - Upload your logo to a publicly accessible URL (you can use Firebase Storage for this)
   - Replace the placeholder `YOUR_LOGO_URL_HERE` in the HTML with your actual logo URL
   - Make sure the `%LINK%` placeholder remains in the HTML as Firebase will replace it with the actual verification link

8. Click "Save" to apply your custom template

## Hosting Your Logo

To host your logo in Firebase Storage:

1. Go to Storage in the Firebase Console
2. Create a folder called "email_assets" 
3. Upload your logo
4. Set the file access to public
5. Copy the public URL and use it in your email template

## Testing the Email Template

After saving your custom template, you can test it by:

1. Going to Authentication → Templates → Email verification
2. Click "Send test email" and enter your email address

## Other Email Templates

You can also customize other Firebase Authentication emails using the same approach:
- Password reset
- Email address change
- Email link for sign-in

Remember to use email-friendly HTML and inline CSS for best compatibility across email clients. 