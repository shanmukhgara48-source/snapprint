// Run with: dart run seed_firestore.dart
// Requires: dart pub global activate flutterfire_cli (or run inside snap_print project)
// Usage: cd snap_print && dart run ../seed_firestore.dart
//
// This script seeds Firestore with all 67 products from the Printo catalog
// across 4 categories: Photo Prints, Photo Books, Frames & Wall Decor, Personalized Gifts.
// It is idempotent — running it twice will NOT create duplicates (uses fixed doc IDs).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _Size {
  const _Size(this.label, this.price);
  final String label;
  final double price;
  Map<String, dynamic> toMap() => {'label': label, 'price': price};
}

class _Product {
  const _Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.basePrice,
    required this.description,
    this.sizes = const [],
    this.material = '',
    this.deliveryInfo = '3–5 business days',
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final String description;
  final List<_Size> sizes;
  final String material;
  final String deliveryInfo;
  final int sortOrder;

  Map<String, dynamic> toMap() => {
        'name': name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'basePrice': basePrice,
        'description': description,
        'sizes': sizes.map((s) => s.toMap()).toList(),
        'material': material,
        'deliveryInfo': deliveryInfo,
        'imageUrl': '',
        'isActive': true,
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ─── Categories ───────────────────────────────────────────────────────────────

final _categories = [
  {
    'id': 'photo_prints',
    'name': 'Photo Prints',
    'sortOrder': 1,
    'isActive': true,
  },
  {
    'id': 'photo_books',
    'name': 'Photo Books',
    'sortOrder': 2,
    'isActive': true,
  },
  {
    'id': 'frames_wall_decor',
    'name': 'Frames & Wall Decor',
    'sortOrder': 3,
    'isActive': true,
  },
  {
    'id': 'personalized_gifts',
    'name': 'Personalized Gifts',
    'sortOrder': 4,
    'isActive': true,
  },
];

// ─── Products ─────────────────────────────────────────────────────────────────

const _photoPrints = 'photo_prints';
const _photoBooks = 'photo_books';
const _framesDecor = 'frames_wall_decor';
const _gifts = 'personalized_gifts';

const _photoCategory = 'Photo Prints';
const _booksCategory = 'Photo Books';
const _framesCategory = 'Frames & Wall Decor';
const _giftsCategory = 'Personalized Gifts';

final List<_Product> _products = [
  // ── PHOTO PRINTS (6) ──────────────────────────────────────────────────────
  _Product(
    id: 'pp_classic',
    name: 'Classic Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 337,
    description:
        'Vibrant, true-to-life colour prints on premium glossy or matte paper. '
        'Perfect for everyday memories, gifting, or building a photo wall.',
    sizes: const [
      _Size('4×6 in (10×15 cm)', 337),
      _Size('5×7 in (13×18 cm)', 459),
      _Size('6×8 in (15×20 cm)', 589),
      _Size('8×10 in (20×25 cm)', 749),
      _Size('8×12 in (20×30 cm)', 849),
    ],
    material: 'Fujifilm Lustre / Glossy paper, 260 gsm',
    deliveryInfo: '3–5 business days',
    sortOrder: 1,
  ),
  _Product(
    id: 'pp_square',
    name: 'Square Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 284,
    description:
        'Instagram-style square prints that look stunning framed or in a scrapbook. '
        'Available in two popular sizes with a borderless finish.',
    sizes: const [
      _Size('4×4 in (10×10 cm)', 284),
      _Size('6×6 in (15×15 cm)', 399),
      _Size('8×8 in (20×20 cm)', 549),
    ],
    material: 'Fujifilm Glossy / Matte paper, 260 gsm',
    deliveryInfo: '3–5 business days',
    sortOrder: 2,
  ),
  _Product(
    id: 'pp_retro_polaroid',
    name: 'Retro Polaroid Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 478,
    description:
        'Vintage-style Polaroid prints with a wide white border at the bottom. '
        'Add a caption to make each print truly personal.',
    sizes: const [
      _Size('3.5×4.2 in (Polaroid)', 478),
    ],
    material: 'Premium glossy photo paper, 260 gsm',
    deliveryInfo: '3–5 business days',
    sortOrder: 3,
  ),
  _Product(
    id: 'pp_passport',
    name: 'Passport & Stamp Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 213,
    description:
        'Government-compliant passport photos and custom rubber-stamp-style prints. '
        'Ideal for official documentation or novelty gifting.',
    sizes: const [
      _Size('Passport (35×45 mm) — sheet of 8', 213),
      _Size('Stamp size — sheet of 12', 249),
    ],
    material: 'Matte photo paper, 240 gsm',
    deliveryInfo: '2–3 business days',
    sortOrder: 4,
  ),
  _Product(
    id: 'pp_instant',
    name: 'Instant Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 443,
    description:
        'Mini instant-camera–style prints that are ready to peel and stick or slip into your wallet.',
    sizes: const [
      _Size('Instax Mini (54×86 mm) — pack of 5', 443),
      _Size('Instax Mini (54×86 mm) — pack of 10', 799),
    ],
    material: 'Instax-style glossy photo paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 5,
  ),
  _Product(
    id: 'pp_bulk',
    name: 'Bulk Prints',
    categoryId: _photoPrints,
    categoryName: _photoCategory,
    basePrice: 1003,
    description:
        'Best value for events, weddings, and parties. Order 50+ prints and save big. '
        'Choose a single size or mix sizes in the same order.',
    sizes: const [
      _Size('Pack of 50 (4×6 in)', 1003),
      _Size('Pack of 100 (4×6 in)', 1799),
      _Size('Pack of 200 (4×6 in)', 3299),
    ],
    material: 'Fujifilm Lustre paper, 260 gsm',
    deliveryInfo: '5–7 business days',
    sortOrder: 6,
  ),

  // ── PHOTO BOOKS (8) ───────────────────────────────────────────────────────
  _Product(
    id: 'pb_classic',
    name: 'Classic Photo Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 1475,
    description:
        'A timeless hardcover photo album with lay-flat pages and vibrant printing. '
        'Available in landscape and portrait orientations.',
    sizes: const [
      _Size('8×6 in — 20 pages', 1475),
      _Size('8×6 in — 40 pages', 2199),
      _Size('11×8.5 in — 20 pages', 1899),
      _Size('11×8.5 in — 40 pages', 2799),
      _Size('12×12 in — 20 pages', 2299),
    ],
    material: 'Hardcover with lay-flat pages, 170 gsm satin paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 7,
  ),
  _Product(
    id: 'pb_pre_wedding',
    name: 'Pre-Wedding Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Celebrate your love story before the big day with a beautifully designed '
        'pre-wedding album featuring elegant layouts and premium paper.',
    sizes: const [
      _Size('12×12 in — 30 pages', 2360),
      _Size('12×12 in — 50 pages', 3499),
    ],
    material: 'Hardcover, lay-flat pages, 200 gsm matte paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 8,
  ),
  _Product(
    id: 'pb_baby_shower',
    name: 'Baby Shower Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Capture the joy of your baby shower in a keepsake album with pastel '
        'designs, guest-note pages, and milestone moments.',
    sizes: const [
      _Size('10×10 in — 30 pages', 2360),
      _Size('10×10 in — 50 pages', 3299),
    ],
    material: 'Hardcover, lay-flat pages, 200 gsm satin paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 9,
  ),
  _Product(
    id: 'pb_baby',
    name: 'Baby Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Document every precious moment of your little one's first year in a '
        'charming, dedicated baby photo book.',
    sizes: const [
      _Size('10×10 in — 30 pages', 2360),
      _Size('10×10 in — 50 pages', 3299),
    ],
    material: 'Hardcover, lay-flat pages, 200 gsm satin paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 10,
  ),
  _Product(
    id: 'pb_anniversary',
    name: 'Anniversary Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Relive your most cherished memories with a romantic anniversary album — '
        'the perfect gift for any milestone year.',
    sizes: const [
      _Size('12×12 in — 30 pages', 2360),
      _Size('12×12 in — 50 pages', 3499),
    ],
    material: 'Hardcover, lay-flat pages, 200 gsm matte paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 11,
  ),
  _Product(
    id: 'pb_travel',
    name: 'Travel Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Turn your adventure photos into a beautiful travel journal. '
        'Map-inspired layouts and ample space for captions and stories.',
    sizes: const [
      _Size('11×8.5 in — 30 pages', 2360),
      _Size('11×8.5 in — 50 pages', 3299),
    ],
    material: 'Hardcover, lay-flat pages, 170 gsm satin paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 12,
  ),
  _Product(
    id: 'pb_milestone_birthday',
    name: 'Milestone Birthday Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Celebrate a landmark birthday — 1st, 18th, 30th, 50th and beyond — '
        'with a bespoke photo book that recaps life's greatest moments.',
    sizes: const [
      _Size('10×10 in — 30 pages', 2360),
      _Size('10×10 in — 50 pages', 3299),
    ],
    material: 'Hardcover, lay-flat pages, 200 gsm satin paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 13,
  ),
  _Product(
    id: 'pb_graduation',
    name: 'Graduation Year Album',
    categoryId: _photoBooks,
    categoryName: _booksCategory,
    basePrice: 2360,
    description:
        'Commemorate the hard work and late nights with a graduation album '
        'that captures campus life, friendships, and convocation.',
    sizes: const [
      _Size('11×8.5 in — 30 pages', 2360),
      _Size('11×8.5 in — 50 pages', 3299),
    ],
    material: 'Hardcover, lay-flat pages, 170 gsm matte paper',
    deliveryInfo: '5–7 business days',
    sortOrder: 14,
  ),

  // ── FRAMES & WALL DECOR (30) ──────────────────────────────────────────────
  _Product(
    id: 'fw_classic_frame',
    name: 'Classic Photo Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 413,
    description:
        'A sleek, lightweight photo frame in black, white, or natural wood finish. '
        'Ready to hang or display on a shelf.',
    sizes: const [
      _Size('5×7 in', 413),
      _Size('8×10 in', 549),
      _Size('10×12 in', 699),
      _Size('12×15 in', 899),
    ],
    material: 'MDF with acrylic cover',
    deliveryInfo: '4–6 business days',
    sortOrder: 15,
  ),
  _Product(
    id: 'fw_collage_frame_2',
    name: '2-Photo Collage Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 649,
    description:
        'Display two of your favourite photos side-by-side in one elegant frame.',
    sizes: const [
      _Size('2-up (A4 size)', 649),
      _Size('2-up (A3 size)', 899),
    ],
    material: 'MDF with acrylic cover',
    deliveryInfo: '4–6 business days',
    sortOrder: 16,
  ),
  _Product(
    id: 'fw_collage_frame_4',
    name: '4-Photo Collage Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 799,
    description:
        'A four-window collage frame — ideal for family portraits, friend groups, '
        'or a series of travel memories.',
    sizes: const [
      _Size('4-up (A3 size)', 799),
      _Size('4-up (A2 size)', 1099),
    ],
    material: 'MDF with acrylic cover',
    deliveryInfo: '4–6 business days',
    sortOrder: 17,
  ),
  _Product(
    id: 'fw_collage_frame_6',
    name: '6-Photo Collage Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 999,
    description:
        'Six custom-cut windows in one stylish frame. '
        'Great for showcasing a year of memories on a single wall.',
    sizes: const [
      _Size('6-up (A2 size)', 999),
      _Size('6-up (A1 size)', 1399),
    ],
    material: 'MDF with acrylic cover',
    deliveryInfo: '4–6 business days',
    sortOrder: 18,
  ),
  _Product(
    id: 'fw_canvas_print',
    name: 'Canvas Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 899,
    description:
        'Gallery-quality canvas print stretched over a solid pine frame. '
        'UV-resistant inks ensure lasting vibrancy.',
    sizes: const [
      _Size('8×10 in', 899),
      _Size('12×16 in', 1299),
      _Size('16×20 in', 1699),
      _Size('20×24 in', 2199),
      _Size('24×36 in', 2999),
    ],
    material: '300 gsm artist canvas, pine stretcher bars',
    deliveryInfo: '5–7 business days',
    sortOrder: 19,
  ),
  _Product(
    id: 'fw_canvas_wrap',
    name: 'Canvas Wrap',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1099,
    description:
        'Canvas printed to the edges and wrapped tightly around the frame — '
        'no additional framing needed.',
    sizes: const [
      _Size('12×12 in', 1099),
      _Size('16×16 in', 1499),
      _Size('20×20 in', 1899),
      _Size('24×24 in', 2299),
    ],
    material: '300 gsm canvas, solid pine bars',
    deliveryInfo: '5–7 business days',
    sortOrder: 20,
  ),
  _Product(
    id: 'fw_canvas_wrap_2split',
    name: '2-Split Canvas Wrap',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 2199,
    description:
        'Your photo split across two gallery-wrapped canvas panels for a '
        'dramatic wall display.',
    sizes: const [
      _Size('2-panel 24×16 in total', 2199),
      _Size('2-panel 36×24 in total', 3099),
    ],
    material: '300 gsm canvas, solid pine bars',
    deliveryInfo: '5–7 business days',
    sortOrder: 21,
  ),
  _Product(
    id: 'fw_canvas_wrap_3split',
    name: '3-Split Canvas Wrap',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 2999,
    description:
        'A triptych canvas set that creates a stunning panoramic effect across '
        'three equal-width panels.',
    sizes: const [
      _Size('3-panel 36×12 in total', 2999),
      _Size('3-panel 48×16 in total', 3999),
    ],
    material: '300 gsm canvas, solid pine bars',
    deliveryInfo: '5–7 business days',
    sortOrder: 22,
  ),
  _Product(
    id: 'fw_canvas_wrap_5split',
    name: '5-Split Canvas Wrap',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 5299,
    description:
        'Five-panel canvas split for the ultimate gallery wall centrepiece. '
        'Available in portrait or landscape orientation.',
    sizes: const [
      _Size('5-panel 60×20 in total', 5299),
    ],
    material: '300 gsm canvas, solid pine bars',
    deliveryInfo: '7–10 business days',
    sortOrder: 23,
  ),
  _Product(
    id: 'fw_acrylic_print',
    name: 'Acrylic Photo Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1599,
    description:
        'Face-mounted acrylic print for museum-quality depth and richness. '
        'A sleek, modern look with incredible colour depth.',
    sizes: const [
      _Size('8×10 in', 1599),
      _Size('12×16 in', 2199),
      _Size('16×20 in', 2999),
      _Size('20×24 in', 3799),
    ],
    material: '5 mm acrylic, C-print face mounted',
    deliveryInfo: '6–8 business days',
    sortOrder: 24,
  ),
  _Product(
    id: 'fw_metal_print',
    name: 'Metal Photo Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1799,
    description:
        'High-gloss aluminium print with vivid colour reproduction and a '
        'contemporary metallic sheen. Waterproof and scratch-resistant.',
    sizes: const [
      _Size('8×10 in', 1799),
      _Size('12×16 in', 2499),
      _Size('16×20 in', 3199),
    ],
    material: 'Aluminium sheet, dye-sublimation print',
    deliveryInfo: '6–8 business days',
    sortOrder: 25,
  ),
  _Product(
    id: 'fw_photo_tile',
    name: 'Photo Tile',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 599,
    description:
        'Peel-and-stick square photo tiles that can be rearranged as many times '
        'as you like without damaging your walls.',
    sizes: const [
      _Size('8×8 in', 599),
      _Size('10×10 in', 799),
      _Size('12×12 in', 999),
    ],
    material: 'Foam board with repositionable adhesive',
    deliveryInfo: '4–6 business days',
    sortOrder: 26,
  ),
  _Product(
    id: 'fw_poster_frame',
    name: 'Poster Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 849,
    description:
        'A minimalist snap-frame for displaying your printed poster with a premium finish.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 849),
      _Size('A2 (42×59.4 cm)', 1099),
      _Size('A1 (59.4×84.1 cm)', 1499),
    ],
    material: 'Aluminium snap-frame, acrylic cover',
    deliveryInfo: '4–6 business days',
    sortOrder: 27,
  ),
  _Product(
    id: 'fw_wall_cluster_4',
    name: '4-Piece Wall Cluster',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1299,
    description:
        'A curated set of four mismatched-size frames designed to hang together '
        'as a cohesive gallery wall cluster.',
    sizes: const [
      _Size('Set of 4 (mix sizes)', 1299),
    ],
    material: 'MDF with acrylic covers',
    deliveryInfo: '5–7 business days',
    sortOrder: 28,
  ),
  _Product(
    id: 'fw_wall_cluster_6',
    name: '6-Piece Wall Cluster',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1799,
    description:
        'Six frames of varied sizes that create a stunning, Instagram-worthy '
        'gallery wall right out of the box.',
    sizes: const [
      _Size('Set of 6 (mix sizes)', 1799),
    ],
    material: 'MDF with acrylic covers',
    deliveryInfo: '5–7 business days',
    sortOrder: 29,
  ),
  _Product(
    id: 'fw_table_top_frame',
    name: 'Table Top Photo Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 349,
    description:
        'A compact desk or shelf frame for your favourite portrait or landscape photo.',
    sizes: const [
      _Size('4×6 in', 349),
      _Size('5×7 in', 449),
    ],
    material: 'MDF with easel back',
    deliveryInfo: '3–5 business days',
    sortOrder: 30,
  ),
  _Product(
    id: 'fw_shadow_box',
    name: 'Photo Shadow Box',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1199,
    description:
        'Deep-set shadow-box frame to display photos alongside mementos, '
        'tickets, or pressed flowers.',
    sizes: const [
      _Size('10×12 in deep box', 1199),
      _Size('12×15 in deep box', 1599),
    ],
    material: 'MDF, deep profile, glass front',
    deliveryInfo: '5–7 business days',
    sortOrder: 31,
  ),
  _Product(
    id: 'fw_string_lights_frame',
    name: 'String Lights Photo Display',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 899,
    description:
        'Copper fairy lights with mini clothespins to hang 10 of your favourite '
        'prints. Warm, ambient décor for any room.',
    sizes: const [
      _Size('Set of 10 prints + 2 m string lights', 899),
      _Size('Set of 20 prints + 4 m string lights', 1499),
    ],
    material: 'Copper wire LED lights + 4×6 in prints',
    deliveryInfo: '4–6 business days',
    sortOrder: 32,
  ),
  _Product(
    id: 'fw_heart_collage',
    name: 'Heart-Shaped Collage Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 699,
    description:
        'Your favourite photos arranged in a heart shape on a single print — '
        'a timeless gift for loved ones.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 699),
      _Size('A2 (42×59.4 cm)', 999),
    ],
    material: '200 gsm satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 33,
  ),
  _Product(
    id: 'fw_round_collage',
    name: 'Round/Circle Collage Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 699,
    description:
        'Photos arranged in concentric circles for a modern, artistic wall piece.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 699),
      _Size('A2 (42×59.4 cm)', 999),
    ],
    material: '200 gsm satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 34,
  ),
  _Product(
    id: 'fw_map_print',
    name: 'Custom Map Art Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 849,
    description:
        'A beautifully styled map of any city or location in the world, '
        'with a custom title and coordinates.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 849),
      _Size('A2 (42×59.4 cm)', 1149),
      _Size('A1 (59.4×84.1 cm)', 1599),
    ],
    material: '200 gsm premium satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 35,
  ),
  _Product(
    id: 'fw_birth_poster',
    name: 'Birth Stats Poster',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 799,
    description:
        'A beautiful birth announcement poster with your baby's name, date, '
        'time, weight, and height.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 799),
      _Size('A2 (42×59.4 cm)', 1099),
    ],
    material: '200 gsm premium satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 36,
  ),
  _Product(
    id: 'fw_canvas_collage',
    name: 'Canvas Collage Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1299,
    description:
        'Multiple photos arranged in a custom grid on a single stretched canvas.',
    sizes: const [
      _Size('12×16 in', 1299),
      _Size('16×20 in', 1699),
      _Size('20×24 in', 2199),
    ],
    material: '300 gsm canvas, pine stretcher bars',
    deliveryInfo: '5–7 business days',
    sortOrder: 37,
  ),
  _Product(
    id: 'fw_wood_print',
    name: 'Wooden Photo Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1499,
    description:
        'Photo printed directly onto natural wood, preserving the grain texture '
        'for a rustic, organic look.',
    sizes: const [
      _Size('8×10 in', 1499),
      _Size('12×16 in', 1999),
    ],
    material: 'Natural pine wood plank',
    deliveryInfo: '6–8 business days',
    sortOrder: 38,
  ),
  _Product(
    id: 'fw_glass_frame',
    name: 'Floating Glass Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1099,
    description:
        'A borderless, frameless glass panel that appears to float on the wall, '
        'making your photo the sole focus.',
    sizes: const [
      _Size('8×10 in', 1099),
      _Size('12×16 in', 1499),
      _Size('16×20 in', 1999),
    ],
    material: '5 mm tempered glass, standoff hardware',
    deliveryInfo: '6–8 business days',
    sortOrder: 39,
  ),
  _Product(
    id: 'fw_panoramic_print',
    name: 'Panoramic Wall Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1199,
    description:
        'Wide-format print for sweeping landscapes, cityscapes, or wedding panoramas.',
    sizes: const [
      _Size('30×10 in', 1199),
      _Size('40×13 in', 1599),
      _Size('60×20 in', 2499),
    ],
    material: '200 gsm satin paper / canvas (selectable)',
    deliveryInfo: '5–7 business days',
    sortOrder: 40,
  ),
  _Product(
    id: 'fw_led_frame',
    name: 'LED Backlit Photo Frame',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 1899,
    description:
        'A frame with built-in LED edge lighting that makes your photo glow. '
        'USB-powered with a touch dimmer.',
    sizes: const [
      _Size('A4 LED frame', 1899),
      _Size('A3 LED frame', 2499),
    ],
    material: 'Acrylic LED panel, aluminium border',
    deliveryInfo: '6–8 business days',
    sortOrder: 41,
  ),
  _Product(
    id: 'fw_kids_room_print',
    name: 'Kids Room Wall Art',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 599,
    description:
        'Bright, playful prints with children's themes — alphabets, animals, '
        'or custom photos — to brighten any nursery or playroom.',
    sizes: const [
      _Size('A3 (29.7×42 cm)', 599),
      _Size('A2 (42×59.4 cm)', 849),
    ],
    material: '200 gsm premium satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 42,
  ),
  _Product(
    id: 'fw_minimalist_poster',
    name: 'Minimalist Quote Poster',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 449,
    description:
        'Stylish typographic posters with your favourite quote, lyrics, or '
        'meaningful words in a clean, modern layout.',
    sizes: const [
      _Size('A4 (21×29.7 cm)', 449),
      _Size('A3 (29.7×42 cm)', 599),
      _Size('A2 (42×59.4 cm)', 849),
    ],
    material: '200 gsm satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 43,
  ),
  _Product(
    id: 'fw_photo_strip',
    name: 'Photo Strip Print',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 349,
    description:
        'Vintage photo-booth–style strip with 4 photos stacked vertically. '
        'Great for gifting and scrapbooks.',
    sizes: const [
      _Size('2×6 in strip', 349),
      _Size('4×12 in strip', 499),
    ],
    material: '260 gsm lustre photo paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 44,
  ),
  _Product(
    id: 'fw_folded_card',
    name: 'Photo Folded Card',
    categoryId: _framesDecor,
    categoryName: _framesCategory,
    basePrice: 299,
    description:
        'Personalised greeting cards with your photo on the front and a '
        'custom message inside. Includes envelope.',
    sizes: const [
      _Size('A5 folded (pack of 5)', 299),
      _Size('A5 folded (pack of 10)', 549),
      _Size('A4 folded (pack of 5)', 449),
    ],
    material: '300 gsm card stock, glossy laminate',
    deliveryInfo: '3–5 business days',
    sortOrder: 45,
  ),

  // ── PERSONALIZED GIFTS (25) ───────────────────────────────────────────────
  _Product(
    id: 'pg_poster_small',
    name: 'Photo Poster (Small)',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 47,
    description:
        'Affordable, vibrant posters to decorate your room, locker, or office. '
        'Available in multiple paper finishes.',
    sizes: const [
      _Size('A4 (21×29.7 cm)', 47),
      _Size('A3 (29.7×42 cm)', 89),
    ],
    material: '170 gsm satin paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 46,
  ),
  _Product(
    id: 'pg_poster_large',
    name: 'Photo Poster (Large)',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 149,
    description:
        'Large-format posters for a dramatic visual impact — perfect for events '
        'or permanent wall décor.',
    sizes: const [
      _Size('A2 (42×59.4 cm)', 149),
      _Size('A1 (59.4×84.1 cm)', 249),
      _Size('A0 (84.1×118.9 cm)', 399),
    ],
    material: '170 gsm satin paper',
    deliveryInfo: '4–6 business days',
    sortOrder: 47,
  ),
  _Product(
    id: 'pg_fridge_magnet',
    name: 'Photo Fridge Magnet',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 149,
    description:
        'Sturdy fridge magnets printed with your photo — a fun keepsake for '
        'friends and family.',
    sizes: const [
      _Size('2×3 in (single)', 149),
      _Size('2×3 in (pack of 5)', 599),
      _Size('3×4 in (single)', 199),
    ],
    material: 'Flexible magnetic sheet, glossy laminate',
    deliveryInfo: '3–5 business days',
    sortOrder: 48,
  ),
  _Product(
    id: 'pg_mug_white',
    name: 'White Photo Mug',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 225,
    description:
        'Classic white ceramic mug with your photo or custom design. '
        'Dishwasher-safe and microwave-safe.',
    sizes: const [
      _Size('11 oz standard', 225),
      _Size('15 oz large', 299),
    ],
    material: 'Ceramic, dye-sublimation print',
    deliveryInfo: '4–6 business days',
    sortOrder: 49,
  ),
  _Product(
    id: 'pg_mug_colour',
    name: 'Colour-Changing Photo Mug',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 349,
    description:
        'Reveal your photo as the mug heats up! Black exterior transforms '
        'to reveal a vibrant image when hot liquid is added.',
    sizes: const [
      _Size('11 oz magic mug', 349),
    ],
    material: 'Ceramic with heat-reactive coating',
    deliveryInfo: '4–6 business days',
    sortOrder: 50,
  ),
  _Product(
    id: 'pg_mug_latte',
    name: 'Latte Photo Mug',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 399,
    description:
        'A wide, rounded latte mug with your custom photo. '
        'Taller and more spacious than a standard mug.',
    sizes: const [
      _Size('17 oz latte mug', 399),
    ],
    material: 'Ceramic, dye-sublimation print',
    deliveryInfo: '4–6 business days',
    sortOrder: 51,
  ),
  _Product(
    id: 'pg_mug_travel',
    name: 'Travel Photo Mug',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 699,
    description:
        'Stainless steel travel mug with your photo printed on the outer sleeve. '
        'Double-walled for temperature retention.',
    sizes: const [
      _Size('14 oz travel mug', 699),
    ],
    material: 'Stainless steel, printed sleeve',
    deliveryInfo: '5–7 business days',
    sortOrder: 52,
  ),
  _Product(
    id: 'pg_mug_premium',
    name: 'Premium Photo Mug Set',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 955,
    description:
        'A gift box set of two matching white mugs with complementary photos — '
        'perfect for couples or best friends.',
    sizes: const [
      _Size('Set of 2 × 11 oz mugs', 955),
    ],
    material: 'Ceramic, dye-sublimation, gift box',
    deliveryInfo: '5–7 business days',
    sortOrder: 53,
  ),
  _Product(
    id: 'pg_calendar_wall',
    name: 'Wall Calendar',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 472,
    description:
        'A 12-month wall calendar with your photos — one per month. '
        'Spiral-bound with a hanger loop.',
    sizes: const [
      _Size('A3 wall calendar', 472),
      _Size('A2 wall calendar', 699),
    ],
    material: '200 gsm satin cover, 170 gsm inner pages',
    deliveryInfo: '5–7 business days',
    sortOrder: 54,
  ),
  _Product(
    id: 'pg_calendar_desk',
    name: 'Desk Calendar',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 295,
    description:
        'A compact 12-month desk calendar that stands upright. '
        'Keep your favourite photo visible all year round.',
    sizes: const [
      _Size('5×7 in desktop', 295),
    ],
    material: '250 gsm card stock, spiral-bound',
    deliveryInfo: '4–6 business days',
    sortOrder: 55,
  ),
  _Product(
    id: 'pg_keychain_round',
    name: 'Round Photo Keychain',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 378,
    description:
        'Carry your memories wherever you go with a durable metal keychain '
        'featuring your favourite photo.',
    sizes: const [
      _Size('Round 38 mm metal keychain', 378),
      _Size('Rectangle 28×50 mm metal keychain', 399),
    ],
    material: 'Metal, epoxy-coated print',
    deliveryInfo: '3–5 business days',
    sortOrder: 56,
  ),
  _Product(
    id: 'pg_pop_socket',
    name: 'Photo Pop Socket',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 143,
    description:
        'A customised phone grip and stand featuring your photo. '
        'Universal adhesive — works on most phone cases.',
    sizes: const [
      _Size('Standard pop socket (40 mm)', 143),
    ],
    material: 'Plastic, custom-printed top',
    deliveryInfo: '3–5 business days',
    sortOrder: 57,
  ),
  _Product(
    id: 'pg_tote_bag',
    name: 'Photo Tote Bag',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 499,
    description:
        'Eco-friendly cotton tote bag with your photo or artwork printed in '
        'full colour. Reusable and washable.',
    sizes: const [
      _Size('Standard tote 38×42 cm', 499),
    ],
    material: '100% cotton canvas, screen print',
    deliveryInfo: '5–7 business days',
    sortOrder: 58,
  ),
  _Product(
    id: 'pg_coaster_set',
    name: 'Photo Coaster Set',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 612,
    description:
        'A set of four hardboard coasters each printed with a different photo. '
        'Cork-backed to protect surfaces.',
    sizes: const [
      _Size('Set of 4 round coasters (90 mm)', 612),
      _Size('Set of 4 square coasters (90×90 mm)', 612),
    ],
    material: 'Hardboard, cork back, gloss laminate',
    deliveryInfo: '4–6 business days',
    sortOrder: 59,
  ),
  _Product(
    id: 'pg_selfie_booth',
    name: 'Selfie Photo Booth Kit',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 763,
    description:
        'Everything you need for a DIY photo booth: a custom backdrop print, '
        'props, and 20 instant prints. Perfect for parties and events.',
    sizes: const [
      _Size('Kit with A1 backdrop + 20 prints', 763),
      _Size('Kit with A0 backdrop + 40 prints', 1299),
    ],
    material: 'Fabric backdrop, 260 gsm prints',
    deliveryInfo: '5–7 business days',
    sortOrder: 60,
  ),
  _Product(
    id: 'pg_phone_case',
    name: 'Custom Phone Case',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 449,
    description:
        'A tough, slim phone case with your design or photo printed directly '
        'on the back. Available for most popular phone models.',
    sizes: const [
      _Size('Slim hard case', 449),
      _Size('Tough (dual-layer) case', 549),
    ],
    material: 'Polycarbonate, UV-printed',
    deliveryInfo: '5–7 business days',
    sortOrder: 61,
  ),
  _Product(
    id: 'pg_cushion',
    name: 'Photo Cushion Cover',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 599,
    description:
        'Soft polyester cushion cover with your photo printed in vibrant colours. '
        'Inner cushion insert included.',
    sizes: const [
      _Size('12×12 in with insert', 599),
      _Size('16×16 in with insert', 799),
    ],
    material: 'Polyester, dye-sublimation print',
    deliveryInfo: '5–7 business days',
    sortOrder: 62,
  ),
  _Product(
    id: 'pg_jigsaw',
    name: 'Photo Jigsaw Puzzle',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 699,
    description:
        'A fun and unique gift — your photo turned into a jigsaw puzzle. '
        'Comes in a custom gift box.',
    sizes: const [
      _Size('120-piece puzzle (A4 size)', 699),
      _Size('252-piece puzzle (A3 size)', 899),
      _Size('500-piece puzzle (A2 size)', 1199),
    ],
    material: 'Cardboard, glossy laminate, gift box',
    deliveryInfo: '5–7 business days',
    sortOrder: 63,
  ),
  _Product(
    id: 'pg_notebook',
    name: 'Custom Photo Notebook',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 349,
    description:
        'A lined or blank A5 notebook with your photo or design on the cover. '
        'Great for journalling, sketching, or gifting.',
    sizes: const [
      _Size('A5, 80 pages lined', 349),
      _Size('A5, 80 pages blank', 349),
    ],
    material: 'Paperback cover, 80 gsm inner pages',
    deliveryInfo: '4–6 business days',
    sortOrder: 64,
  ),
  _Product(
    id: 'pg_gift_wrap',
    name: 'Personalised Gift Wrap',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 199,
    description:
        'Wrapping paper printed with your photo, pattern, or a custom message. '
        'Makes every gift extra special.',
    sizes: const [
      _Size('Sheet 50×70 cm', 199),
      _Size('Roll 60×200 cm', 499),
    ],
    material: '90 gsm gloss coated paper',
    deliveryInfo: '3–5 business days',
    sortOrder: 65,
  ),
  _Product(
    id: 'pg_fridge_board',
    name: 'Photo Fridge Board',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 499,
    description:
        'A magnetic whiteboard for your fridge with your photo printed in one '
        'corner. Includes dry-erase marker.',
    sizes: const [
      _Size('A4 fridge board', 499),
    ],
    material: 'Magnetic board, dry-erase surface',
    deliveryInfo: '4–6 business days',
    sortOrder: 66,
  ),
  _Product(
    id: 'pg_t_shirt',
    name: 'Custom Photo T-Shirt',
    categoryId: _gifts,
    categoryName: _giftsCategory,
    basePrice: 599,
    description:
        'Premium cotton T-shirt with your photo or design printed with durable '
        'DTG ink. Available in multiple colours and sizes.',
    sizes: const [
      _Size('S', 599),
      _Size('M', 599),
      _Size('L', 599),
      _Size('XL', 599),
      _Size('XXL', 649),
    ],
    material: '180 gsm 100% cotton, DTG print',
    deliveryInfo: '5–7 business days',
    sortOrder: 67,
  ),
];

// ─── Seed function ─────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;
  int categoriesUpserted = 0;
  int productsUpserted = 0;

  print('\n📦 SnapPrint Firestore Seeder');
  print('═══════════════════════════════════════');

  // ── 1. Upsert categories ───────────────────────────────────────────────────
  print('\n[1/2] Seeding categories...');
  for (final cat in _categories) {
    await db.collection('categories').doc(cat['id'] as String).set(
          cat,
          SetOptions(merge: true),
        );
    categoriesUpserted++;
    print('  ✔ ${cat['name']}');
  }

  // ── 2. Upsert products in batches of 400 ─────────────────────────────────
  print('\n[2/2] Seeding products (${_products.length} total)...');

  const batchSize = 400;
  for (int i = 0; i < _products.length; i += batchSize) {
    final batch = db.batch();
    final chunk = _products.skip(i).take(batchSize).toList();

    for (final product in chunk) {
      final ref = db.collection('products').doc(product.id);
      batch.set(ref, product.toMap(), SetOptions(merge: true));
    }

    await batch.commit();

    for (final p in chunk) {
      print('  ✔ [${p.categoryId}] ${p.name}  ₹${p.basePrice.toStringAsFixed(0)}');
      productsUpserted++;
    }
  }

  // ── 3. Summary ─────────────────────────────────────────────────────────────
  print('\n═══════════════════════════════════════');
  print('✅ Seeding complete!');
  print('   Categories : $categoriesUpserted');
  print('   Products   : $productsUpserted');
  print('\nFirestore collections created:');
  print('  /categories  (${_categories.length} documents)');
  print('  /products    (${_products.length} documents)');
  print('\nVerification checklist:');
  print('  □ Photo Prints   → ${_products.where((p) => p.categoryId == _photoPrints).length} products');
  print('  □ Photo Books    → ${_products.where((p) => p.categoryId == _photoBooks).length} products');
  print('  □ Frames & Decor → ${_products.where((p) => p.categoryId == _framesDecor).length} products');
  print('  □ Personalized   → ${_products.where((p) => p.categoryId == _gifts).length} products');
}
