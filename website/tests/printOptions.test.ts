import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  startingAmount,
  productFormats,
  formatRatio,
} from '../src/lib/printOptions.ts'
import { catalogProducts } from '../src/data/products.ts'
const product = (id: string) => catalogProducts.find((p) => p.id === id)!
test('priced products scale by groups; a frame with two copies starts at 826', () => {
  assert.equal(startingAmount(product('classic-photo-frames'), 2), 826)
})
test('quote-only products never contribute zero as a purchasable price', () => {
  assert.equal(startingAmount(product('photo-magic-mug')), null)
})
test('bulk per-piece prices include the minimum quantity', () => {
  assert.equal(startingAmount(product('bulk-mugs')), 11250)
})
test('ambiguous MOQ pricing requires confirmation', () => {
  assert.equal(startingAmount(product('custom-premium-frame')), null)
  assert.equal(startingAmount(product('standard-paper-posters')), null)
})
test('mug physical dimensions and print areas are not format variants', () => {
  assert.deepEqual(productFormats(product('photo-mini-mug')), ['175 ml'])
})
test('all products retain at least one usable format', () => {
  for (const p of catalogProducts) assert.ok(productFormats(p).length > 0, p.id)
})
test('preview ratio handles square, landscape, portrait and descriptive sizes', () => {
  assert.equal(formatRatio('6x4'), 1.5)
  assert.equal(formatRatio('4x4'), 1)
  assert.equal(formatRatio('A4 (8.3x11.7)'), 8.3 / 11.7)
  assert.equal(formatRatio('A4 Landscape & 12x12 in Square'), undefined)
  assert.equal(formatRatio('18x25 in x1 + 12x12 in x2'), undefined)
  assert.equal(formatRatio('325 ml'), undefined)
})
