import type { MouseEvent } from 'react'

/** Tracks pointer position over a `.spotlight` card so its gold glow follows the cursor. */
export function handleSpotlight(event: MouseEvent<HTMLElement>) {
  const rect = event.currentTarget.getBoundingClientRect()
  event.currentTarget.style.setProperty('--spot-x', `${event.clientX - rect.left}px`)
  event.currentTarget.style.setProperty('--spot-y', `${event.clientY - rect.top}px`)
}
