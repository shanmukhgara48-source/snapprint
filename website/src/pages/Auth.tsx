import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import type { ConfirmationResult } from 'firebase/auth'
import { api, getAuthToken } from '../services/api'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { ArrowRightIcon, ShieldCheckIcon } from '../components/Icons'
import { normalizeIndianPhone } from '../lib/validation'
import {
  getFirebaseAuth,
  resetRecaptchaVerifier,
  sendPhoneOtp,
} from '../lib/firebase'
import {
  DEMO_OTP,
  getDevCredentials,
  isDemoOtpEnabled,
  isDevBypassEnabled,
  isFirebaseConfigured,
} from '../config/env'
import { useToastOptional } from '../context/Toast'

const RESEND_COOLDOWN_S = 30

export function Auth() {
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [phone, setPhone] = useState('')
  const [otp, setOtp] = useState('')
  const [step, setStep] = useState<'phone' | 'otp'>('phone')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [confirmation, setConfirmation] =
    useState<ConfirmationResult | null>(null)
  const [cooldown, setCooldown] = useState(0)
  const [devMode, setDevMode] = useState(false)
  const cooldownTimer = useRef<ReturnType<typeof setInterval> | null>(null)

  const firebaseReady = isFirebaseConfigured()
  const devBypassAvailable = isDevBypassEnabled()
  // Owner-requested temporary demo mode (until real Firebase keys exist):
  // any valid number + the demo code signs in. Badged + must be removed pre-launch.
  const demoEnabled = isDemoOtpEnabled()

  // Already signed in? Go home.
  useEffect(() => {
    if (getAuthToken()) navigate('/', { replace: true })
  }, [navigate])

  useEffect(() => {
    getFirebaseAuth()
    return () => {
      if (cooldownTimer.current) clearInterval(cooldownTimer.current)
      resetRecaptchaVerifier()
    }
  }, [])

  function startCooldown() {
    setCooldown(RESEND_COOLDOWN_S)
    if (cooldownTimer.current) clearInterval(cooldownTimer.current)
    cooldownTimer.current = setInterval(() => {
      setCooldown((c) => {
        if (c <= 1) {
          if (cooldownTimer.current) clearInterval(cooldownTimer.current)
          return 0
        }
        return c - 1
      })
    }, 1000)
  }

  function e164(): string | null {
    // Indian numbers by default; full +<code> also accepted.
    const trimmed = phone.trim()
    if (trimmed.startsWith('+')) {
      return /^\+[1-9][0-9]{7,14}$/.test(trimmed) ? trimmed : null
    }
    return normalizeIndianPhone(trimmed)
  }

  async function handleSendOtp(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    const full = e164()
    if (!full) {
      setError(
        'Enter a valid 10-digit Indian mobile number, e.g. 98765 43210.',
      )
      return
    }
    // Demo path (temporary, owner-requested): no SMS is sent; any valid
    // number proceeds and the demo code is accepted on the verify step.
    if (demoEnabled) {
      setStep('otp')
      toast?.notify(
        `Demo mode: enter ${DEMO_OTP} as the OTP to continue.`,
        'info',
      )
      return
    }
    // Dev bypass path (development builds only): no SMS is sent; the
    // backend issues a session directly on the verify step.
    if (devMode && devBypassAvailable) {
      setStep('otp')
      toast?.notify(
        'Development mode: enter any 6-digit code to continue.',
        'info',
      )
      return
    }
    if (!firebaseReady) {
      setError(
        'Phone sign-in is not configured yet. Please try again later.',
      )
      return
    }
    setLoading(true)
    try {
      const result = await sendPhoneOtp(full)
      setConfirmation(result)
      setStep('otp')
      startCooldown()
    } catch (err: any) {
      const code = err?.code as string | undefined
      if (code === 'auth/invalid-phone-number') {
        setError('That phone number looks invalid. Please check it.')
      } else if (code === 'auth/too-many-requests') {
        setError(
          'Too many attempts from this device. Please wait a while and try again.',
        )
      } else if (code === 'auth/quota-exceeded') {
        setError(
          'SMS quota exceeded right now. Please wait a few minutes and retry.',
        )
      } else {
        setError(
          err?.message || 'Could not send the code. Please try again.',
        )
      }
      resetRecaptchaVerifier()
    } finally {
      setLoading(false)
    }
  }

  async function handleVerifyOtp(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    if (!/^\d{6}$/.test(otp)) {
      setError('Enter the 6-digit code sent to your phone.')
      return
    }
    const full = e164()
    if (!full) {
      setError('Phone number changed — please go back and re-enter it.')
      return
    }
    setLoading(true)
    try {
      if (demoEnabled) {
        if (otp !== DEMO_OTP) {
          setError('That code is incorrect. Demo mode accepts only the demo code.')
          return
        }
        const { secret } = getDevCredentials()
        if (!secret) {
          setError('Demo mode is missing its server secret. Set VITE_DEV_SECRET and rebuild.')
          return
        }
        await api.devLogin(full, secret)
        toast?.notifySuccess('Signed in (demo mode).')
        navigate('/')
        return
      }
      if (devMode && devBypassAvailable) {
        const { secret } = getDevCredentials()
        await api.devLogin(full, secret)
        toast?.notifySuccess('Signed in (development bypass).')
        navigate('/')
        return
      }
      if (!confirmation) {
        setError('No code request is active. Please resend the code.')
        return
      }
      let idToken: string
      try {
        const credential = await confirmation.confirm(otp)
        idToken = await credential.user.getIdToken()
      } catch (err: any) {
        const code = err?.code as string | undefined
        if (code === 'auth/invalid-verification-code') {
          setError('That code is incorrect. Please check and try again.')
        } else if (code === 'auth/code-expired') {
          setError('That code has expired. Please resend a new one.')
        } else {
          setError('Verification failed. Please try again.')
        }
        return
      }
      await api.verifyFirebase(idToken, full)
      toast?.notifySuccess('Signed in successfully.')
      navigate('/')
    } catch (err: any) {
      setError(err?.message || 'Sign-in failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  async function handleResend() {
    if (cooldown > 0 || loading) return
    if (demoEnabled) return
    if (devMode && devBypassAvailable) return
    setError('')
    const full = e164()
    if (!full || !firebaseReady) return
    setLoading(true)
    try {
      resetRecaptchaVerifier()
      const result = await sendPhoneOtp(full)
      setConfirmation(result)
      setOtp('')
      startCooldown()
      toast?.notify('A new code is on its way.', 'info')
    } catch {
      setError('Could not resend the code. Please try again shortly.')
      resetRecaptchaVerifier()
    } finally {
      setLoading(false)
    }
  }

  const displayPhone = (() => {
    const full = e164()
    return full ? `+${full.slice(1, 3)} ${full.slice(3)}` : phone.trim()
  })()

  return (
    <div className="auth-page wrap py-12">
      <Seo
        title="Sign in | SnapPrint"
        description="Sign in to SnapPrint with a one-time code sent to your phone."
        noindex
      />
      <Reveal>
        <div className="mx-auto max-w-md">
          <div className="mb-8 text-center">
            <h1 className="hero-title mb-2">
              {mode === 'login' ? 'Welcome back' : 'Create your account'}
            </h1>
            <p className="text-muted">
              {mode === 'login'
                ? 'Sign in to continue to SnapPrint'
                : 'Enter your phone number to get started'}
            </p>
          </div>

          {step === 'phone' ? (
            <form onSubmit={handleSendOtp} className="space-y-6">
              <div>
                <label
                  htmlFor="phone"
                  className="text-muted mb-1 block text-sm"
                >
                  Phone Number
                </label>
                <div className="relative">
                  <span className="text-muted absolute top-1/2 left-3 -translate-y-1/2">
                    +91
                  </span>
                  <input
                    id="phone"
                    type="tel"
                    autoComplete="tel"
                    value={phone}
                    onChange={(e) =>
                      setPhone(e.target.value.replace(/[^\d+ ]/g, ''))
                    }
                    placeholder="98765 43210"
                    className="bg-surface w-full rounded border border-border p-3 pl-12 outline-none focus:border-accent"
                    required
                    maxLength={15}
                  />
                </div>
                <p className="text-muted mt-1 text-xs">
                  {demoEnabled
                    ? 'Demo mode — no real SMS. Use the demo code on the next step.'
                    : 'We will SMS a 6-digit one-time code to this number.'}
                </p>
              </div>
              {error && (
                <p className="text-sm text-red-500" role="alert">
                  {error}
                </p>
              )}
              <button
                type="submit"
                className="shop-button w-full justify-center"
                disabled={loading}
              >
                {loading ? 'Sending…' : 'Send OTP'}
                <ArrowRightIcon />
              </button>
              {demoEnabled && (
                <p
                  role="status"
                  className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-center text-sm text-amber-800"
                >
                  Demo mode — enter <strong>{DEMO_OTP}</strong> as the OTP for
                  any number. Remove before launch.
                </p>
              )}
              {devBypassAvailable && (
                <label className="flex items-center justify-center gap-2 text-xs text-muted">
                  <input
                    type="checkbox"
                    checked={devMode}
                    onChange={(e) => setDevMode(e.target.checked)}
                  />
                  Use development bypass (local QA only, never in production)
                </label>
              )}
              <p className="text-muted text-center text-sm">
                By continuing, you agree to our{' '}
                <Link to="/terms" className="text-accent underline">
                  Terms
                </Link>{' '}
                and{' '}
                <Link to="/privacy" className="text-accent underline">
                  Privacy Policy
                </Link>
              </p>
            </form>
          ) : (
            <form onSubmit={handleVerifyOtp} className="space-y-6">
              <div>
                <label
                  htmlFor="otp"
                  className="text-muted mb-1 block text-sm"
                >
                  Enter OTP sent to {displayPhone}
                </label>
                <input
                  id="otp"
                  type="text"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  maxLength={6}
                  value={otp}
                  onChange={(e) => {
                    setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))
                  }}
                  className="bg-surface w-full rounded border border-border p-3 text-center text-xl tracking-[0.5em] outline-none focus:border-accent"
                  required
                />
              </div>
              {error && (
                <p className="text-sm text-red-500" role="alert">
                  {error}
                </p>
              )}
              <button
                type="submit"
                className="shop-button w-full justify-center"
                disabled={loading || otp.length !== 6}
              >
                {loading ? 'Verifying…' : 'Verify & Continue'}
                <ShieldCheckIcon />
              </button>
              <div className="flex items-center justify-between text-sm">
                <button
                  type="button"
                  onClick={() => {
                    setStep('phone')
                    setOtp('')
                    setError('')
                    setConfirmation(null)
                  }}
                  className="text-muted transition-colors hover:text-ink"
                >
                  Change phone number
                </button>
                {!(demoEnabled || (devMode && devBypassAvailable)) && (
                  <button
                    type="button"
                    onClick={handleResend}
                    disabled={cooldown > 0 || loading}
                    className="text-accent hover:underline disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {cooldown > 0 ? `Resend in ${cooldown}s` : 'Resend code'}
                  </button>
                )}
              </div>
            </form>
          )}

          <div className="mt-6 text-center">
            <button
              className="text-muted text-sm transition-colors hover:text-ink"
              onClick={() => {
                setMode(mode === 'login' ? 'signup' : 'login')
                setError('')
              }}
            >
              {mode === 'login'
                ? 'Need an account? Sign up'
                : 'Already have an account? Sign in'}
            </button>
          </div>

          <div className="mt-4 text-center">
            <Link to="/" className="text-accent text-sm hover:underline">
              ← Back to home
            </Link>
          </div>
        </div>
      </Reveal>
      {/* Invisible reCAPTCHA container for Firebase phone auth */}
      <div id="recaptcha-container" aria-hidden="true" />
    </div>
  )
}
