import { useEffect } from 'react'
import { APP_URL, IS_WP_EMBED } from '../config/env'
import { appAsset } from '../lib/assets'

interface SeoProps {
  title: string
  description: string
  path?: string
  image?: string
  /** Checkout, payment, account & order pages must never be indexed. */
  noindex?: boolean
  type?: 'website' | 'product'
  /** JSON-LD structured data (Organization, Product, BreadcrumbList…). */
  jsonLd?: Record<string, unknown> | Record<string, unknown>[]
}

/**
 * Minimal per-page SEO without extra dependencies. Updates document head on
 * mount; public pages get canonical + OG/Twitter tags, private flows get
 * noindex.
 */
export function Seo({
  title,
  description,
  path = '/',
  image = appAsset('og.jpg'),
  noindex = false,
  type = 'website',
  jsonLd,
}: SeoProps) {
  useEffect(() => {
    // Inside WordPress the SEO plugin owns <head> — stay out of the way.
    if (IS_WP_EMBED) return
    document.title = title

    const upsert = (selector: string, create: () => HTMLElement) => {
      let el = document.head.querySelector(selector) as HTMLElement | null
      if (!el) {
        el = create()
        document.head.appendChild(el)
      }
      return el
    }

    const setMeta = (attr: string, value: string, content: string) => {
      const el = upsert(`meta[${attr}="${value}"]`, () => {
        const m = document.createElement('meta')
        m.setAttribute(attr, value)
        return m
      }) as HTMLMetaElement
      el.content = content
    }

    setMeta('name', 'description', description)
    setMeta(
      'name',
      'robots',
      noindex ? 'noindex, nofollow' : 'index, follow',
    )
    setMeta('property', 'og:title', title)
    setMeta('property', 'og:description', description)
    setMeta('property', 'og:type', type === 'product' ? 'product' : 'website')
    const canonical = `${APP_URL.replace(/\/$/, '')}${path}`
    setMeta('property', 'og:url', canonical)
    setMeta('property', 'og:image', image)
    setMeta('name', 'twitter:card', 'summary_large_image')
    setMeta('name', 'twitter:title', title)
    setMeta('name', 'twitter:description', description)
    setMeta('name', 'twitter:image', image)

    let link = document.head.querySelector(
      'link[rel="canonical"]',
    ) as HTMLLinkElement | null
    if (!link) {
      link = document.createElement('link')
      link.rel = 'canonical'
      document.head.appendChild(link)
    }
    link.href = canonical

    // Structured data: exactly one managed script tag per page.
    const LD_ID = 'snapprint-jsonld'
    document.getElementById(LD_ID)?.remove()
    if (jsonLd) {
      const script = document.createElement('script')
      script.id = LD_ID
      script.type = 'application/ld+json'
      script.text = JSON.stringify(jsonLd)
      document.head.appendChild(script)
    }
  }, [title, description, path, image, noindex, type])

  return null
}
