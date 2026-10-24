# Sign in

Mollygram signs in the same way as the official Telegram apps. You need an existing Telegram account: the app cannot register a new one.

## With a QR code

1. Open Telegram on your phone.
2. Go to **Settings → Devices → Link Desktop Device**.
3. Point the phone at the QR code on the Mollygram screen and confirm.

## With a phone number

1. Choose **Log in by phone number**.
2. Pick your country, enter the number and select **Next**.
3. Enter the code. Telegram sends it to the Telegram app on your other device, or by SMS or a phone call.

If the QR code cannot load, for example without a network, the app opens the phone form instead.

## Two-step verification

If the account has a cloud password, the app asks for it after the code. The hint you set in Telegram appears under the field.

## Errors

| Message | What to do |
|---|---|
| Invalid phone number | Check the country and the digits. |
| The code has expired, request a new one | Go back and request a new code. |
| Invalid code | Re-enter the code. |
| Wrong password | Re-enter the two-step password. |
| Too many attempts, try again later | Wait, then try again. Telegram sets the delay. |

Where Telegram is blocked, use the proxy button on the sign-in screen.

## Several accounts

Mollygram holds up to three accounts. Switch with ⌃⌘1 to ⌃⌘3 or from the command palette.

## Where the session lives

Everything sits in the macOS Application Support folder of the app, one folder per account (`accounts/<n>`): the TDLib database and files, the encrypted store for saved messages, and the window layout.

The keys for the TDLib database and the encrypted store are random 32-byte values kept in the macOS Keychain. If a store key is lost, that store cannot be opened.

## Log out

Open **Settings → Account** and choose **Log out…**. The app logs the session out on Telegram's side and deletes the account's folder on this computer, including its Keychain keys. Your chats and media stay in the Telegram cloud.
