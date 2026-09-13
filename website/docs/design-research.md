# SnapPrint: from catalog to meaningful creation

Research and implementation: 6 September 2026.

## Reference collection

Google search was used to discover photo-printing, framed-print, gifting, photo-book and print-on-demand examples. The strongest candidates were checked against their own product pages. Artifact Uprising and Framebridge were also inspected visually in the browser. These are observed design patterns and design hypotheses, not claims of measured conversion lifts.

| Reference | Useful pattern | Why it helps | SnapPrint adaptation |
| --- | --- | --- | --- |
| [Artifact Uprising — photo gifts](https://www.artifactuprising.com/photo-gifts) | Filters by occasion, recipient, photo count and starting price; use-case badges | Shoppers can begin with the person or memory instead of understanding a product taxonomy first. | A “shop the feeling” entry, curated occasion selections, a simple guide, and a starting-budget filter. |
| [Artifact Uprising — your life in print](https://www.artifactuprising.com/photo-products-for-you) | Distinct family, travel, prints and framed-photo stories | Gives an emotional reason to choose each format. | Home categories explain where products fit into everyday life. Original hero imagery shows tangible keepsakes. |
| [Framebridge — pricing](https://www.framebridge.com/pages/pricing) | Prominent size-led pricing and a clear explanation of what is included | Addresses cost uncertainty before customers invest time in customization. | Starting prices, minimum quantities, material details and delivery tiers appear close to the decision. Estimates stay explicitly provisional because SnapPrint lacks authoritative web variant totals. |
| [Framebridge — custom frames](https://www.framebridge.com/collections/custom-frames) | Begin with what the shopper is framing; a photo upload is a clear action | Makes customization feel like a concrete next step. | An upload-led entry to product pages, a private local preview and visible format controls. |
| [Mixbook — books by occasion](https://www.mixbook.com/photo-books-by-occasion) | Occasion-specific paths for weddings, travel, birthdays and milestones | Reduces the blank-page problem of designing a meaningful gift. | Curated love, travel, everyday and gifting collections use real SnapPrint product IDs and prices. |
| [Papier — photo books](https://www.papier.com/photos/photo-books/) | Personalization of layouts and captions, supported by a how-to guide | Shows that the product is something customers can author, with help available. | A short three-step journey and progressive product details; actual print layout editing stays in the existing app. |
| [Printful — custom canvas](https://www.printful.com/custom-canvas-prints) | Upload, position and preview before ordering | Seeing a personal image on a physical product builds confidence and attachment. | Photo previews with fill/fit options, a format-aware silhouette, and a basic low-resolution advisory. The preview is labeled illustrative, not a production proof. |
| [Printique — canvas prints](https://www.printique.com/products/canvas-print/) | Clear dimensions, construction, frame depth and installation detail | Turns “premium quality” into assessable product facts. | Existing material/finish data is exposed in expandable product details with delivery and refund information. No unsupported material or quality claims are added. |
| [Social Print Studio — mini prints](https://socialprintstudio.com/products/mini-prints) and [print sets](https://socialprintstudio.com/) | Tangible small-print photography, explicit pack quantities, display pairings | Helps people imagine how to use prints and makes a multi-item gift easier to assemble. | Tactile print compositions, minimum quantities, and optional related products in the saved plan. Pairings are separately priced; no invented bundle discount. |

## Audit of the previous site

- Home led with a catalog count, category count and price range rather than a memory or a finished product.
- Hero/category images included camera equipment and bookshelves, which did not demonstrate printed products.
- Occasion content was informational rather than a scoped shopping path.
- The collection was a dense specification grid; product cards did not open a detail or creation route.
- Category/search state was component-local, preventing useful deep links and reliable return to filtered collections.
- There was no product detail page, personal photo preview, saved selection or next-step summary on the website.
- Copy such as “server-verified totals,” “backend seed catalog” and “review-ready price list” addressed developers rather than customers.
- Ordering, authentication, photo submission and Razorpay payment existed in the Flutter app. The public React website had no checkout or configured app-store/deep link. Contact/business placeholders were also present.

## Implemented journey

1. **Imagine:** editorial cream and gold storefront, original still life, tactile product compositions, a memory-led headline and concrete photo-start CTA.
2. **Discover:** all four real categories, occasion links with scoped results, a guided occasion/budget selector, search, and price sorting. Query parameters preserve and share filters.
3. **Personalize:** every catalog product has a detail route. Choose a supported format, try a JPG/PNG/WebP locally, switch between fill and fit, and choose sets/copies. A single unambiguous dimension adjusts the preview proportions. Capacity and print-area measurements are not falsely offered as separate mug variants.
4. **Build confidence:** actual minimum quantities and materials, published delivery tiers, helpful FAQs, links to shipping/privacy/refund policies, and explicitly provisional prices. No fabricated reviews, scarcity or delivery guarantees.
5. **Keep momentum:** a device-local saved print plan, editable quantities/removal, separate shipping preference, optional gift pairings and downloadable instructions for continuing in the app. Quote-only and ambiguous bulk totals are excluded from known estimates.

The aperture mark, warm gold and editorial serif remain part of SnapPrint’s identity. Dark chrome is reserved for the footer and selected controls so photos and products carry the visual emphasis. Small-screen cards keep a visible action, category controls scroll horizontally, tap targets are generous, and product/plan layouts become a single column.

## Product boundaries and launch dependencies

- No web purchase or payment capability has been invented. Existing app/backend order functionality is unchanged.
- The print plan is **not a cart/order** and does not automatically transfer to the app. It saves product IDs, selected formats and quantities in localStorage on the current device. Photo previews use temporary object URLs and are not persisted or sent to a server.
- Configure `VITE_APP_URL` with a verified HTTPS app-store or app landing-page URL to enable the “Open SnapPrint” link. Without it, the site clearly explains that existing app users should open the app manually. A true transfer would require an app deep-link/import contract, which the repo did not provide.
- Product imagery is illustrative, not verified SKU photography. The new hero is generated; other compositions use the existing Unsplash photography source. Replace with owned product photography when available. Font/image requests to those third parties remain as in the existing site; preview files never accompany them.
- Size/finish-specific pricing is not available to the public website. Price summaries remain starting estimates, with taxes and final configuration confirmed in the app. Explicit per-piece bulk mug prices include the 50-piece minimum. Ambiguous multi-piece minima require price confirmation rather than an invented total.
- Existing support/legal placeholders remain on the contact page; they need business-provided values before a public launch. Policy routes and legacy route aliases are retained.
- Measure discovery-to-detail clicks, preview use, guide completion, plan saves and eventual app conversion after a real transfer is configured. No tracking was added in this redesign.

## Asset provenance

Built-in image generation was used for `public/images/memories-still-life.jpg` (1536 × 1024, optimized JPEG). The original generated PNG remains in the tool’s generated-images directory. Prompt:

> Use case: product-mockup. Create a premium editorial ecommerce photograph for SnapPrint, an Indian photo printing brand. Asset: homepage hero image, landscape 3:2, no UI or overlay text. Warm natural afternoon sunlight on an ivory linen tabletop, soft long shadows. Beautiful considered arrangement of tangible personal photo products: one medium natural oak frame standing at the back right displaying a candid South Asian young couple on a seaside holiday, a small closed sand-colored linen photo album with a square inset travel photo at back left, and 4 overlapping white-bordered retro photo prints in the foreground depicting sunny coastal travel, laughing South Asian friends, a dog, and a family. Small dried blossom at top right; restrained styling, plenty of tactile paper texture, photojournalistic photos within the prints, accurate realistic geometry, elevated independent design shop product photography. Warm cream, honey, terracotta, muted blue sea; genuine rich color in printed images. Camera looking down at 40 degrees, products fill composition, leave breathing space near edges. No camera equipment, no logos, no readable words, no sale stickers, no watermark. This is an illustrative product scene, not a specific manufactured SKU.
