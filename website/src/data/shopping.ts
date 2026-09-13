import { catalogProducts, type CatalogProduct } from './products'

export type ShoppingMoment = {
  id: string
  label: string
  short: string
  description: string
  image: string
  ids: string[]
}

export const moments: ShoppingMoment[] = [
  {
    id: 'everyday',
    label: 'The everyday magic',
    short: 'Everyday',
    description: 'Little moments. Very big feelings.',
    image: 'photo-1476514525535-07fb3b4ae5f1',
    ids: [
      'retro-polaroid-prints',
      'classic-photo-prints',
      'square-photo-prints',
      'photo-fridge-magnet-combo-set-of-4',
    ],
  },
  {
    id: 'love',
    label: 'Your kind of forever',
    short: 'Love & weddings',
    description: 'For the two of you. And all your chapters.',
    image: 'photo-1519741497674-611481863552',
    ids: [
      'pre-wedding-photo-albums',
      'anniversary-photo-albums',
      'classic-photo-frames',
      'retro-polaroid-prints',
    ],
  },
  {
    id: 'travel',
    label: 'The trips that stay',
    short: 'Travel',
    description: 'Bring a little of that holiday home.',
    image: 'photo-1476514525535-07fb3b4ae5f1',
    ids: [
      'travel-photo-albums',
      'canvas-gallery-wraps',
      'square-photo-prints',
      'classic-photo-prints',
    ],
  },
  {
    id: 'gift',
    label: 'A very personal present',
    short: 'Gifting',
    description: 'For your favourite person. Just because.',
    image: 'photo-1519689680058-324335c77eba',
    ids: [
      'personalised-white-photo-mug',
      'photo-fridge-magnet-combo-set-of-4',
      'classic-photo-frames',
      'milestone-birthday-photo-albums',
    ],
  },
]
export const curatedIds = [
  'retro-polaroid-prints',
  'classic-photo-albums',
  'classic-photo-frames',
  'personalised-white-photo-mug',
]
export const curatedProducts = curatedIds.map((id) =>
  catalogProducts.find((p) => p.id === id)!,
)
export const categoryStories: Record<
  string,
  { title: string; description: string; type: string; image: string }
> = {
  'photo-prints': {
    title: 'Little prints. Big feelings.',
    description: 'For pinning, passing around, and keeping close.',
    type: 'prints',
    image: 'photo-1476514525535-07fb3b4ae5f1',
  },
  'photo-books': {
    title: 'A whole chapter, bound.',
    description: 'Give your favourite stories a place on the shelf.',
    type: 'book',
    image: 'photo-1519741497674-611481863552',
  },
  'frames-wall-decor': {
    title: 'Make room for memories.',
    description: 'Turn a bare corner into your favourite corner.',
    type: 'frame',
    image: 'photo-1476514525535-07fb3b4ae5f1',
  },
  'personalized-gifts': {
    title: 'Something only you could give.',
    description: 'Everyday things, with a very personal touch.',
    type: 'mug',
    image: 'photo-1495567720989-cebdbdd97913',
  },
}
export const photoUrl = (id: string, width = 700) =>
  `https://images.unsplash.com/${id}?auto=format&fit=crop&w=${width}&q=80`
export function productStory(product: CatalogProduct) {
  const stories: Record<string, string> = {
    'retro-polaroid-prints': 'The little moments, with a little nostalgia.',
    'classic-photo-prints': 'Your camera roll deserves a life off-screen.',
    'classic-photo-albums': 'All your favourite chapters, in one place.',
    'classic-photo-frames': 'That one photo you could look at forever.',
    'personalised-white-photo-mug':
      'Make their everyday coffee a little more personal.',
    'canvas-gallery-wraps': 'A favourite view. A whole new point of view.',
  }
  return stories[product.id] ?? categoryStories[product.categoryId].description
}
