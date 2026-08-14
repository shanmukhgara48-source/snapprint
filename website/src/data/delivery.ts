// Mirrors _DEFAULT_DELIVERY_SETTINGS in backend/main.py.

export interface DeliveryOption {
  type: 'free' | 'standard' | 'express'
  label: string
  price: number
  daysLabel: string
}

export const deliveryOptions: DeliveryOption[] = [
  { type: 'free', label: 'Free Delivery', price: 0, daysLabel: '5-7 business days' },
  { type: 'standard', label: 'Standard Delivery', price: 49, daysLabel: '3-4 business days' },
  { type: 'express', label: 'Express Delivery', price: 99, daysLabel: '1-2 business days' },
]

export const sameDayDeliveryNote =
  'Same-day delivery (4-6 hours) is listed for select products in Bengaluru, Hyderabad, NCR, and Chennai when ordered before 4:30 PM.'

export function formatDeliveryPrice(price: number) {
  return price === 0 ? '₹0' : `₹${price.toLocaleString('en-IN')}`
}
