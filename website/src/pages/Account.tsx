import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { api, clearAuthToken } from '../services/api'
import { firebaseSignOut } from '../lib/firebase'
import { Reveal } from '../components/Reveal'
import { Seo } from '../components/Seo'
import { ArrowRightIcon } from '../components/Icons'
import { useToastOptional } from '../context/Toast'

export function Account() {
  const navigate = useNavigate()
  const toast = useToastOptional()
  const [profile, setProfile] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [deleteArmed, setDeleteArmed] = useState(false)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    let cancelled = false
    async function load() {
      try {
        const data = await api.getMe()
        if (!cancelled) setProfile(data)
      } catch (err: any) {
        if (!cancelled) setError(err?.message || 'Could not load your account.')
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    load()
    return () => {
      cancelled = true
    }
  }, [])

  async function handleLogout() {
    clearAuthToken()
    try {
      await firebaseSignOut()
    } catch {
      /* non-fatal */
    }
    navigate('/auth')
  }

  async function handleDelete() {
    setDeleting(true)
    try {
      await api.deleteAccount()
      clearAuthToken()
      try {
        await firebaseSignOut()
      } catch {
        /* non-fatal */
      }
      toast?.notifySuccess('Your account has been deleted.')
      navigate('/', { replace: true })
    } catch (err: any) {
      toast?.notifyError(
        err?.message || 'Could not delete your account. Please try again.',
      )
      setConfirmingDelete(false)
      setDeleteArmed(false)
    } finally {
      setDeleting(false)
    }
  }

  if (loading) {
    return (
      <div className="wrap py-12 text-center">
        <p className="text-muted" role="status">
          Loading your account…
        </p>
      </div>
    )
  }

  return (
    <div className="wrap py-12">
      <Seo
        title="My Account | SnapPrint"
        description="Manage your SnapPrint account."
        path="/account"
        noindex
      />
      <Reveal>
        <div className="mx-auto max-w-2xl">
          <h1 className="hero-title mb-2">My Account</h1>
          <p className="text-muted mb-8">
            Signed in{profile?.phone ? ` as ${profile.phone}` : ''}.
          </p>

          {error && (
            <div
              className="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800"
              role="alert"
            >
              {error}
            </div>
          )}

          <div className="glass space-y-3 rounded-xl border border-border p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold">My Orders</p>
                <p className="text-muted text-sm">
                  Track and review your photo orders.
                </p>
              </div>
              <Link to="/orders" className="text-accent text-sm hover:underline">
                View <ArrowRightIcon />
              </Link>
            </div>
            <hr className="border-border" />
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold">Sign out</p>
                <p className="text-muted text-sm">
                  Ends this session on this device.
                </p>
              </div>
              <button
                onClick={handleLogout}
                className="rounded border border-border px-4 py-2 text-sm"
              >
                Logout
              </button>
            </div>
          </div>

          <div className="mt-8 rounded-xl border border-red-200 bg-red-50/50 p-6">
            <h2 className="font-display text-lg font-semibold text-red-900">
              Danger zone
            </h2>
            {!confirmingDelete ? (
              <>
                <p className="mt-2 text-sm leading-6 text-red-800">
                  Permanently delete your account and personal data. Orders that
                  are still active must be completed or cancelled first.
                </p>
                <button
                  onClick={() => setConfirmingDelete(true)}
                  className="mt-4 rounded border border-red-300 px-4 py-2 text-sm text-red-800"
                >
                  Delete my account…
                </button>
              </>
            ) : (
              <>
                <p className="mt-2 text-sm leading-6 text-red-800" role="alert">
                  <strong>This cannot be undone.</strong> Your profile,
                  addresses and personal data will be permanently removed. Paid
                  order records are anonymised for accounts.
                </p>
                <label className="mt-3 flex items-center gap-2 text-sm text-red-800">
                  <input
                    type="checkbox"
                    checked={deleteArmed}
                    onChange={(e) => setDeleteArmed(e.target.checked)}
                  />
                  I understand my account will be permanently deleted
                </label>
                <div className="mt-4 flex gap-3">
                  <button
                    onClick={handleDelete}
                    disabled={!deleteArmed || deleting}
                    className="rounded bg-red-600 px-4 py-2 text-sm text-white disabled:opacity-50"
                  >
                    {deleting ? 'Deleting…' : 'Yes, delete my account'}
                  </button>
                  <button
                    onClick={() => {
                      setConfirmingDelete(false)
                      setDeleteArmed(false)
                    }}
                    className="rounded border border-border px-4 py-2 text-sm"
                  >
                    Cancel
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </Reveal>
    </div>
  )
}
