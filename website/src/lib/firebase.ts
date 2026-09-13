import { initializeApp, getApps, type FirebaseApp } from 'firebase/app'
import {
  getAuth,
  RecaptchaVerifier,
  signInWithPhoneNumber,
  signOut,
  type Auth,
  type ConfirmationResult,
} from 'firebase/auth'
import { FIREBASE_CONFIG, isFirebaseConfigured } from '../config/env'

let _app: FirebaseApp | null = null
let _auth: Auth | null = null
let _verifier: RecaptchaVerifier | null = null

/** Initialise Firebase web app lazily. Returns null when not configured. */
export function getFirebaseAuth(): Auth | null {
  if (!isFirebaseConfigured()) return null
  if (_auth) return _auth
  _app =
    getApps().length > 0
      ? getApps()[0]!
      : initializeApp({
          apiKey: FIREBASE_CONFIG.apiKey,
          authDomain: FIREBASE_CONFIG.authDomain,
          projectId: FIREBASE_CONFIG.projectId,
          storageBucket: FIREBASE_CONFIG.storageBucket || undefined,
          messagingSenderId: FIREBASE_CONFIG.messagingSenderId || undefined,
          appId: FIREBASE_CONFIG.appId,
        })
  _auth = getAuth(_app)
  return _auth
}

/**
 * Get (or create) the invisible reCAPTCHA verifier bound to the given
 * container element id. Must be called from a user gesture at least once
 * before sendPhoneOtp().
 */
export function getRecaptchaVerifier(containerId: string): RecaptchaVerifier | null {
  const auth = getFirebaseAuth()
  if (!auth) return null
  if (_verifier) return _verifier
  _verifier = new RecaptchaVerifier(auth, containerId, { size: 'invisible' })
  return _verifier
}

export function resetRecaptchaVerifier(): void {
  try {
    _verifier?.clear()
  } catch {
    /* ignore */
  }
  _verifier = null
}

/** Send an SMS OTP to a full E.164 phone number. Returns the confirmation handle. */
export async function sendPhoneOtp(
  phoneE164: string,
  containerId = 'recaptcha-container',
): Promise<ConfirmationResult> {
  const auth = getFirebaseAuth()
  if (!auth) throw new Error('Phone sign-in is not configured yet.')
  const verifier = getRecaptchaVerifier(containerId)
  if (!verifier) throw new Error('Phone sign-in is not configured yet.')
  return signInWithPhoneNumber(auth, phoneE164, verifier)
}

/** Sign out the Firebase web session (app JWT is cleared separately). */
export async function firebaseSignOut(): Promise<void> {
  if (_auth) {
    await signOut(_auth)
  }
}
