# 🛡️ Sentinel Journal

## 2026-05-18 - Hardcoded SQLCipher Fallback Encryption Key
**Vulnerability:** `lib/main.dart` used `'fajrak_default_key'` as a hardcoded fallback when neither Supabase JWT session nor SUPABASE_ANON_KEY env var was available. Since SQLCipher encrypts ALL local financial data (transactions, debts, accounts, budgets, goals, sync queue), a predictable key nullifies the encryption.

**Learning:** The `??` fallback chain was convenient but dangerous — the last resort was a static string embedded in the binary. The pattern was: session token > env key > static string. No one considered the offline-first cold-start scenario where neither session nor env might be present.

**Prevention:** Never use static/guessable strings as database encryption keys. For offline-first apps, generate a random 256-bit key per device using `Random.secure()` and persist in SharedPreferences. The fallback priority should be: session token > env key > device-unique persisted random key.
