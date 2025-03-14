# Setting Up Two-Factor Authentication in Firebase

This document explains how to properly configure Firebase for SMS-based Two-Factor Authentication (2FA) in your Real Estate application.

## Prerequisites

1. A Firebase project with Authentication enabled
2. A Blaze (pay-as-you-go) plan activated (required for SMS verification)
3. Admin access to the Firebase console

## Step 1: Enable Phone Authentication

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** in the left sidebar
4. Click on the **Sign-in method** tab
5. Find **Phone** in the list of providers and click on it
6. Toggle the **Enable** switch to on
7. Click **Save**

## Step 2: Set Up SMS Configuration

Firebase uses Google Cloud Identity Platform to send SMS messages. You need to configure this:

1. Make sure you have upgraded to the Blaze plan (SMS verification is not available on the free Spark plan)
2. In the Firebase Console, navigate to **Authentication** > **Settings** > **SMS Configuration**
3. Click **Phone numbers for testing**
4. Add any phone numbers that you'll use for testing in development (these won't incur charges)
   - Format: +[country code][phone number] (e.g., +12025550123)
   - You can add up to 10 test numbers

## Step 3: Create Custom Claims for Admin Users

To identify admin users who require 2FA:

1. Go to the Firebase Console
2. Navigate to **Functions** in the left sidebar
3. Click **Get Started** if you haven't set up Functions before
4. Create a new function to set admin claims:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.addAdminRole = functions.https.onCall((data, context) => {
  // Check if request is made by an admin
  if (context.auth.token.admin !== true) {
    return { error: 'Only admins can add other admins' };
  }
  
  // Get user and add custom claim
  return admin.auth().getUserByEmail(data.email).then(user => {
    return admin.auth().setCustomUserClaims(user.uid, {
      admin: true
    });
  }).then(() => {
    return {
      message: `Success! ${data.email} has been made an admin.`
    };
  }).catch(err => {
    return { error: err.message };
  });
});
```

## Step 4: Configure SMS Message Content

You can customize the SMS message your users receive:

1. Go to the Firebase Console
2. Navigate to **Authentication** > **Templates** > **SMS Configuration**
3. Customize the message, but keep the `%CODE%` placeholder for the actual verification code

## Step 5: Monitor Usage and Costs

Phone authentication uses Firebase Authentication quotas:

1. Free tier: 10,000 phone authentications per month
2. Beyond that: $0.01 USD per verification
3. Monitor costs in the Firebase Console under **Usage and Billing**

## Testing in Development

When testing 2FA functionality:

1. Use test phone numbers when available
2. For emulators, use the default code `123456` which will work with test phone numbers
3. Enable App Check in your Firebase project to prevent abuse

## Production Considerations

Before deploying to production:

1. Configure App Check to prevent abuse of your SMS verification
2. Set up monitoring for SMS verification attempts
3. Consider rate limiting on authentication endpoints
4. Implement proper error handling for failed SMS delivery

## Troubleshooting Common Issues

- **SMS Not Received**: Check phone number format, verify the country is supported
- **Invalid Code Errors**: Ensure code is entered correctly, check for timeout
- **Quota Exceeded**: Monitor your usage in the Firebase Console
