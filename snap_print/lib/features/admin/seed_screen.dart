import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data definitions
// ---------------------------------------------------------------------------

class _SeedCategory {
  const _SeedCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.sortOrder,
  });
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int sortOrder;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'iconName': iconName,
        'sortOrder': sortOrder,
        'isActive': true,
      };
}

class _SeedSize {
  const _SeedSize({required this.label, required this.price});
  final String label;
  final double price;
  Map<String, dynamic> toMap() => {'label': label, 'price': price};
}

class _SeedProduct {
  const _SeedProduct({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.basePrice,
    required this.description,
    required this.material,
    required this.deliveryInfo,
    required this.sortOrder,
    this.sizes = const [],
  });
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double basePrice;
  final String description;
  final String material;
  final String deliveryInfo;
  final int sortOrder;
  final List<_SeedSize> sizes;

  Map<String, dynamic> toMap() => {
        'name': name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'basePrice': basePrice,
        'description': description,
        'material': material,
        'deliveryInfo': deliveryInfo,
        'sortOrder': sortOrder,
        'sizes': sizes.map((s) => s.toMap()).toList(),
        'imageUrl': '',
        'isActive': true,
      };
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
const _categories = [
  _SeedCategory(
    id: 'photo_prints',
    name: 'Photo Prints',
    description: 'Premium quality prints from your favourite photos',
    iconName: 'photo',
    sortOrder: 1,
  ),
  _SeedCategory(
    id: 'photo_books',
    name: 'Photo Books',
    description: 'Beautifully crafted photo books to relive your memories',
    iconName: 'photo_album',
    sortOrder: 2,
  ),
  _SeedCategory(
    id: 'frames_wall_decor',
    name: 'Frames & Wall Decor',
    description: 'Stylish frames and wall art to decorate your space',
    iconName: 'crop',
    sortOrder: 3,
  ),
  _SeedCategory(
    id: 'personalized_gifts',
    name: 'Personalised Gifts',
    description: 'Unique personalised gifts for every occasion',
    iconName: 'card_giftcard',
    sortOrder: 4,
  ),
];

// ---------------------------------------------------------------------------
// Products — Photo Prints
// ---------------------------------------------------------------------------
const _photosPrints = [
  _SeedProduct(
    id: 'pp_classic',
    name: 'Classic Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 337,
    description: 'Vibrant, true-to-life prints on premium glossy or matte paper. Perfect for framing or scrapbooking.',
    material: 'Premium glossy / matte paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 1,
    sizes: [
      _SeedSize(label: '4x6"', price: 337),
      _SeedSize(label: '5x7"', price: 499),
      _SeedSize(label: '8x10"', price: 749),
    ],
  ),
  _SeedProduct(
    id: 'pp_passport',
    name: 'Passport Size Photos',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 149,
    description: 'Official-quality passport and visa photos printed on premium paper. 12 copies per set.',
    material: 'Glossy photo paper',
    deliveryInfo: '1-2 business days',
    sortOrder: 2,
    sizes: [
      _SeedSize(label: '12 copies', price: 149),
      _SeedSize(label: '24 copies', price: 269),
    ],
  ),
  _SeedProduct(
    id: 'pp_square',
    name: 'Square Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 249,
    description: 'Instagram-style square prints that look stunning in collages and gallery walls.',
    material: 'Premium glossy paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 3,
    sizes: [
      _SeedSize(label: '4x4"', price: 249),
      _SeedSize(label: '6x6"', price: 449),
      _SeedSize(label: '8x8"', price: 699),
    ],
  ),
  _SeedProduct(
    id: 'pp_panoramic',
    name: 'Panoramic Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 599,
    description: 'Wide-format prints ideal for landscapes, cityscapes, and group photos that deserve more space.',
    material: 'Premium satin paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 4,
    sizes: [
      _SeedSize(label: '4x12"', price: 599),
      _SeedSize(label: '6x18"', price: 999),
    ],
  ),
  _SeedProduct(
    id: 'pp_matte',
    name: 'Matte Finish Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 399,
    description: 'Elegant matte-finish prints with no glare — perfect for display under lights or in bright rooms.',
    material: 'Matte photo paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 5,
    sizes: [
      _SeedSize(label: '4x6"', price: 399),
      _SeedSize(label: '5x7"', price: 599),
      _SeedSize(label: '8x10"', price: 849),
    ],
  ),
  _SeedProduct(
    id: 'pp_bulk',
    name: 'Bulk Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    basePrice: 1003,
    description: 'Great value bulk prints — perfect for events, parties, and sharing memories with the whole family.',
    material: 'Premium glossy paper',
    deliveryInfo: '4-6 business days',
    sortOrder: 6,
    sizes: [
      _SeedSize(label: '50 prints (4x6")', price: 1003),
      _SeedSize(label: '100 prints (4x6")', price: 1799),
      _SeedSize(label: '200 prints (4x6")', price: 3199),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Products — Photo Books
// ---------------------------------------------------------------------------
const _photoBooks = [
  _SeedProduct(
    id: 'pb_classic',
    name: 'Classic Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 1475,
    description: 'A timeless hardcover photo book with lay-flat pages. Relive your best moments in style.',
    material: 'Hardcover with premium lustre pages',
    deliveryInfo: '5-7 business days',
    sortOrder: 1,
    sizes: [
      _SeedSize(label: '5x5" (20 pages)', price: 1475),
      _SeedSize(label: '8x8" (20 pages)', price: 1999),
      _SeedSize(label: '10x10" (20 pages)', price: 2799),
    ],
  ),
  _SeedProduct(
    id: 'pb_layflat',
    name: 'Lay-Flat Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: 'Premium lay-flat binding lets your photos spread across both pages with zero gutter loss.',
    material: 'Hardcover, lay-flat binding, lustre paper',
    deliveryInfo: '5-7 business days',
    sortOrder: 2,
    sizes: [
      _SeedSize(label: '8x8" (20 pages)', price: 2360),
      _SeedSize(label: '10x10" (20 pages)', price: 3199),
      _SeedSize(label: '12x12" (20 pages)', price: 4299),
    ],
  ),
  _SeedProduct(
    id: 'pb_wedding',
    name: 'Wedding Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: 'Celebrate your big day with a stunning wedding album. Elegant cover options and premium paper.',
    material: 'Linen or leather hardcover, lustre pages',
    deliveryInfo: '7-10 business days',
    sortOrder: 3,
    sizes: [
      _SeedSize(label: '10x10" (30 pages)', price: 2360),
      _SeedSize(label: '12x12" (30 pages)', price: 3499),
      _SeedSize(label: '14x14" (30 pages)', price: 4999),
    ],
  ),
  _SeedProduct(
    id: 'pb_travel',
    name: 'Travel Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: 'Capture your adventures in a beautifully designed travel book with map layouts and journaling space.',
    material: 'Softcover or hardcover, matte pages',
    deliveryInfo: '5-7 business days',
    sortOrder: 4,
    sizes: [
      _SeedSize(label: '6x8" (24 pages)', price: 2360),
      _SeedSize(label: '8x10" (24 pages)', price: 2999),
    ],
  ),
  _SeedProduct(
    id: 'pb_baby',
    name: 'Baby Memory Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: "Document every precious moment of your little one's first year in a beautiful keepsake book.",
    material: 'Padded hardcover, acid-free pages',
    deliveryInfo: '5-7 business days',
    sortOrder: 5,
    sizes: [
      _SeedSize(label: '8x8" (24 pages)', price: 2360),
      _SeedSize(label: '10x10" (24 pages)', price: 3199),
    ],
  ),
  _SeedProduct(
    id: 'pb_mini',
    name: 'Mini Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: 'Pocket-sized photo books that make perfect gifts. Easy to carry and share with loved ones.',
    material: 'Hardcover, glossy pages',
    deliveryInfo: '4-6 business days',
    sortOrder: 6,
    sizes: [
      _SeedSize(label: '4x4" (20 pages)', price: 2360),
    ],
  ),
  _SeedProduct(
    id: 'pb_graduation',
    name: 'Graduation Photo Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: 'Mark this milestone with a special graduation album. A forever keepsake of your achievement.',
    material: 'Hardcover, lustre pages',
    deliveryInfo: '5-7 business days',
    sortOrder: 7,
    sizes: [
      _SeedSize(label: '8x8" (20 pages)', price: 2360),
      _SeedSize(label: '10x10" (20 pages)', price: 3199),
    ],
  ),
  _SeedProduct(
    id: 'pb_yearbook',
    name: 'Year in Review Book',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    basePrice: 2360,
    description: "Celebrate the year that was with a bespoke photo book that recaps life's greatest moments.",
    material: 'Hardcover, lustre pages',
    deliveryInfo: '5-7 business days',
    sortOrder: 8,
    sizes: [
      _SeedSize(label: '8x8" (24 pages)', price: 2360),
      _SeedSize(label: '10x10" (24 pages)', price: 3199),
      _SeedSize(label: '12x12" (24 pages)', price: 4299),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Products — Frames & Wall Decor
// ---------------------------------------------------------------------------
const _framesWallDecor = [
  _SeedProduct(
    id: 'fw_classic_frame',
    name: 'Classic Photo Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 413,
    description: 'Timeless wooden frames for your favourite photos. Ready to hang or stand on any surface.',
    material: 'Solid wood frame, anti-glare glass',
    deliveryInfo: '5-7 business days',
    sortOrder: 1,
    sizes: [
      _SeedSize(label: '4x6"', price: 413),
      _SeedSize(label: '5x7"', price: 599),
      _SeedSize(label: '8x10"', price: 849),
      _SeedSize(label: '12x16"', price: 1299),
    ],
  ),
  _SeedProduct(
    id: 'fw_canvas_print',
    name: 'Canvas Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 999,
    description: 'Museum-quality canvas prints stretched over a solid wooden frame. A statement piece for any wall.',
    material: 'Cotton canvas, kiln-dried pine frame',
    deliveryInfo: '5-7 business days',
    sortOrder: 2,
    sizes: [
      _SeedSize(label: '8x10"', price: 999),
      _SeedSize(label: '12x16"', price: 1499),
      _SeedSize(label: '16x20"', price: 2199),
      _SeedSize(label: '20x24"', price: 2999),
    ],
  ),
  _SeedProduct(
    id: 'fw_metal_print',
    name: 'Metal Photo Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1299,
    description: 'Vivid photos infused directly into aluminium for a sleek, modern finish with extraordinary depth.',
    material: 'Aluminium sheet, UV-resistant inks',
    deliveryInfo: '7-10 business days',
    sortOrder: 3,
    sizes: [
      _SeedSize(label: '8x10"', price: 1299),
      _SeedSize(label: '12x16"', price: 1999),
      _SeedSize(label: '16x20"', price: 2799),
    ],
  ),
  _SeedProduct(
    id: 'fw_acrylic_print',
    name: 'Acrylic Photo Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1499,
    description: 'Crystal-clear acrylic face mounts give your photos a gallery-quality, high-gloss look.',
    material: '5mm acrylic glass, HD printing',
    deliveryInfo: '7-10 business days',
    sortOrder: 4,
    sizes: [
      _SeedSize(label: '8x10"', price: 1499),
      _SeedSize(label: '12x16"', price: 2299),
      _SeedSize(label: '16x20"', price: 3299),
    ],
  ),
  _SeedProduct(
    id: 'fw_wooden_collage',
    name: 'Wooden Collage Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 799,
    description: 'Display multiple memories together in a beautifully crafted wooden multi-aperture frame.',
    material: 'MDF wood, real glass',
    deliveryInfo: '5-7 business days',
    sortOrder: 5,
    sizes: [
      _SeedSize(label: '3 photos', price: 799),
      _SeedSize(label: '4 photos', price: 999),
      _SeedSize(label: '6 photos', price: 1299),
    ],
  ),
  _SeedProduct(
    id: 'fw_poster_print',
    name: 'Poster Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 399,
    description: 'Large-format poster prints on premium matte paper. Great for bedrooms, offices, and studios.',
    material: 'Premium matte poster paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 6,
    sizes: [
      _SeedSize(label: '12x18"', price: 399),
      _SeedSize(label: '18x24"', price: 649),
      _SeedSize(label: '24x36"', price: 1099),
    ],
  ),
  _SeedProduct(
    id: 'fw_floating_frame',
    name: 'Floating Photo Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 649,
    description: 'Modern floating frames give your photos a suspended, gallery-like appearance on the wall.',
    material: 'Walnut wood, tempered glass',
    deliveryInfo: '5-7 business days',
    sortOrder: 7,
    sizes: [
      _SeedSize(label: '4x6"', price: 649),
      _SeedSize(label: '5x7"', price: 849),
      _SeedSize(label: '8x10"', price: 1199),
    ],
  ),
  _SeedProduct(
    id: 'fw_photo_tile',
    name: 'Photo Tiles',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 499,
    description: 'Frameless adhesive photo tiles that stick and re-stick without damaging your walls.',
    material: 'Lightweight foam board, removable adhesive',
    deliveryInfo: '3-5 business days',
    sortOrder: 8,
    sizes: [
      _SeedSize(label: '8x8" (set of 4)', price: 499),
      _SeedSize(label: '8x8" (set of 8)', price: 899),
    ],
  ),
  _SeedProduct(
    id: 'fw_family_tree',
    name: 'Family Tree Wall Art',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1199,
    description: 'A stunning family tree wall display combining multiple family photos in a tree-branch layout.',
    material: 'MDF wood with photo prints',
    deliveryInfo: '7-10 business days',
    sortOrder: 9,
    sizes: [
      _SeedSize(label: '7 photos', price: 1199),
      _SeedSize(label: '11 photos', price: 1699),
    ],
  ),
  _SeedProduct(
    id: 'fw_string_lights',
    name: 'Photo String Lights',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 699,
    description: 'Fairy lights with mini photo clips — a warm, whimsical way to display your favourite memories.',
    material: 'LED string lights, mini wooden pegs',
    deliveryInfo: '3-5 business days',
    sortOrder: 10,
    sizes: [
      _SeedSize(label: '10 photos (2m)', price: 699),
      _SeedSize(label: '20 photos (4m)', price: 1099),
    ],
  ),
  _SeedProduct(
    id: 'fw_map_print',
    name: 'Custom Map Art',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 849,
    description: 'Personalise a map of any location in the world — your hometown, where you met, or a special place.',
    material: 'Premium matte art paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 11,
    sizes: [
      _SeedSize(label: '12x16"', price: 849),
      _SeedSize(label: '16x20"', price: 1299),
      _SeedSize(label: '20x24"', price: 1799),
    ],
  ),
  _SeedProduct(
    id: 'fw_word_art',
    name: 'Word Art Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 599,
    description: 'Turn meaningful words, song lyrics, or a poem into beautiful typographic wall art.',
    material: 'Premium matte art paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 12,
    sizes: [
      _SeedSize(label: '8x10"', price: 599),
      _SeedSize(label: '12x16"', price: 899),
    ],
  ),
  _SeedProduct(
    id: 'fw_photo_collage_print',
    name: 'Photo Collage Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 499,
    description: 'Combine up to 30 photos into a stunning collage print. Choose from dozens of layout templates.',
    material: 'Premium glossy or matte paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 13,
    sizes: [
      _SeedSize(label: '8x10"', price: 499),
      _SeedSize(label: '12x16"', price: 799),
      _SeedSize(label: '16x20"', price: 1199),
    ],
  ),
  _SeedProduct(
    id: 'fw_led_frame',
    name: 'LED Light Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1499,
    description: 'Illuminate your memories with an LED-backlit photo frame that glows beautifully in any room.',
    material: 'Acrylic with LED edge lighting',
    deliveryInfo: '7-10 business days',
    sortOrder: 14,
    sizes: [
      _SeedSize(label: '5x7"', price: 1499),
      _SeedSize(label: '8x10"', price: 1999),
    ],
  ),
  _SeedProduct(
    id: 'fw_sketch_frame',
    name: 'Photo to Sketch Art',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 749,
    description: 'Transform your favourite photo into a hand-drawn style pencil sketch — a truly unique wall piece.',
    material: 'Premium matte art paper',
    deliveryInfo: '4-6 business days',
    sortOrder: 15,
    sizes: [
      _SeedSize(label: '8x10"', price: 749),
      _SeedSize(label: '12x16"', price: 1099),
    ],
  ),
  _SeedProduct(
    id: 'fw_watercolor_print',
    name: 'Watercolour Portrait',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 999,
    description: 'Your photo reimagined as a dreamy watercolour painting. A one-of-a-kind piece of art.',
    material: 'Fine art matte paper',
    deliveryInfo: '5-7 business days',
    sortOrder: 16,
    sizes: [
      _SeedSize(label: '8x10"', price: 999),
      _SeedSize(label: '12x16"', price: 1499),
    ],
  ),
  _SeedProduct(
    id: 'fw_shadow_box',
    name: 'Shadow Box Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1099,
    description: 'Deep-set shadow box frames perfect for displaying photos along with keepsakes and mementos.',
    material: 'Wood frame, UV-protective glass',
    deliveryInfo: '7-10 business days',
    sortOrder: 17,
    sizes: [
      _SeedSize(label: '8x8"', price: 1099),
      _SeedSize(label: '10x10"', price: 1399),
    ],
  ),
  _SeedProduct(
    id: 'fw_magnetic_frame',
    name: 'Magnetic Photo Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 349,
    description: 'Flexible magnetic frames — perfect for fridges and magnetic boards. Swap photos anytime.',
    material: 'Flexible magnetic material',
    deliveryInfo: '2-4 business days',
    sortOrder: 18,
    sizes: [
      _SeedSize(label: '4x6" (set of 4)', price: 349),
      _SeedSize(label: '4x6" (set of 8)', price: 599),
    ],
  ),
  _SeedProduct(
    id: 'fw_heart_collage',
    name: 'Heart Shape Collage',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 649,
    description: 'A heart-shaped photo collage print — the perfect romantic gift or anniversary keepsake.',
    material: 'Premium glossy paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 19,
    sizes: [
      _SeedSize(label: '12x12"', price: 649),
      _SeedSize(label: '16x16"', price: 999),
    ],
  ),
  _SeedProduct(
    id: 'fw_clock_frame',
    name: 'Photo Wall Clock',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1299,
    description: 'A functioning wall clock with your photo as the face — practical and personal.',
    material: 'MDF board, quartz movement',
    deliveryInfo: '5-7 business days',
    sortOrder: 20,
    sizes: [
      _SeedSize(label: '12" diameter', price: 1299),
    ],
  ),
  _SeedProduct(
    id: 'fw_tapestry',
    name: 'Photo Tapestry',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1499,
    description: 'A soft woven photo tapestry that turns your image into a boho-chic wall hanging.',
    material: 'Polyester fabric, vibrant dye-sublimation print',
    deliveryInfo: '5-7 business days',
    sortOrder: 21,
    sizes: [
      _SeedSize(label: '40x60"', price: 1499),
      _SeedSize(label: '60x80"', price: 1999),
    ],
  ),
  _SeedProduct(
    id: 'fw_glass_print',
    name: 'Glass Photo Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1799,
    description: 'Printed on high-clarity glass with UV inks for a striking, luminous effect.',
    material: 'Tempered float glass, UV printing',
    deliveryInfo: '7-10 business days',
    sortOrder: 22,
    sizes: [
      _SeedSize(label: '8x10"', price: 1799),
      _SeedSize(label: '12x16"', price: 2599),
    ],
  ),
  _SeedProduct(
    id: 'fw_foam_board',
    name: 'Foam Board Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 499,
    description: 'Lightweight foam board prints that can be mounted anywhere without frames or hooks.',
    material: 'Foam board, glossy photo paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 23,
    sizes: [
      _SeedSize(label: '8x10"', price: 499),
      _SeedSize(label: '12x16"', price: 799),
      _SeedSize(label: '16x20"', price: 1099),
    ],
  ),
  _SeedProduct(
    id: 'fw_neon_art',
    name: 'Custom Neon Art',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 3499,
    description: 'Eye-catching neon-effect wall art with your name, quote, or logo. Great for rooms and businesses.',
    material: 'LED neon flex on acrylic backing',
    deliveryInfo: '10-14 business days',
    sortOrder: 24,
    sizes: [
      _SeedSize(label: 'Small (30cm)', price: 3499),
      _SeedSize(label: 'Medium (50cm)', price: 4999),
      _SeedSize(label: 'Large (70cm)', price: 6999),
    ],
  ),
  _SeedProduct(
    id: 'fw_door_hanger',
    name: 'Photo Door Hanger',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 299,
    description: 'Personalised door hangers with your photo and name — fun for kids rooms and dorm rooms.',
    material: 'Foam board with glossy laminate',
    deliveryInfo: '2-4 business days',
    sortOrder: 25,
    sizes: [
      _SeedSize(label: 'Standard', price: 299),
    ],
  ),
  _SeedProduct(
    id: 'fw_bamboo_frame',
    name: 'Bamboo Eco Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 549,
    description: 'Sustainably sourced bamboo frames with a natural finish — stylish and eco-friendly.',
    material: 'Natural bamboo, glass front',
    deliveryInfo: '5-7 business days',
    sortOrder: 26,
    sizes: [
      _SeedSize(label: '4x6"', price: 549),
      _SeedSize(label: '5x7"', price: 749),
      _SeedSize(label: '8x10"', price: 999),
    ],
  ),
  _SeedProduct(
    id: 'fw_resin_art',
    name: 'Resin Photo Art',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 1999,
    description: 'Your photo encased in glossy, crystal-clear resin for a 3D depth effect that must be seen.',
    material: 'Epoxy resin, photo-quality print',
    deliveryInfo: '7-10 business days',
    sortOrder: 27,
    sizes: [
      _SeedSize(label: '5x5"', price: 1999),
      _SeedSize(label: '8x8"', price: 2799),
    ],
  ),
  _SeedProduct(
    id: 'fw_newspaper_print',
    name: 'Custom Newspaper Print',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 749,
    description: 'Your photos and messages designed as a vintage-style newspaper front page. A unique gift.',
    material: 'Newsprint-style premium paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 28,
    sizes: [
      _SeedSize(label: 'A3 Tabloid', price: 749),
      _SeedSize(label: 'A2 Broadsheet', price: 1099),
    ],
  ),
  _SeedProduct(
    id: 'fw_birth_poster',
    name: 'Birth Stats Poster',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 599,
    description: 'A beautiful birth announcement poster with your baby name, date, weight, and first photo.',
    material: 'Premium matte art paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 29,
    sizes: [
      _SeedSize(label: '8x10"', price: 599),
      _SeedSize(label: '12x16"', price: 899),
    ],
  ),
  _SeedProduct(
    id: 'fw_folded_card',
    name: 'Personalised Greeting Cards',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    basePrice: 299,
    description: 'Photo greeting cards for birthdays, anniversaries, holidays, and special moments.',
    material: 'Premium cardstock, glossy or matte finish',
    deliveryInfo: '2-4 business days',
    sortOrder: 30,
    sizes: [
      _SeedSize(label: 'Set of 5', price: 299),
      _SeedSize(label: 'Set of 10', price: 499),
      _SeedSize(label: 'Set of 20', price: 849),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Products — Personalised Gifts
// ---------------------------------------------------------------------------
const _personalisedGifts = [
  _SeedProduct(
    id: 'pg_poster_small',
    name: 'Mini Photo Poster',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 47,
    description: 'A compact personalised poster — great as a desk accessory or a heartfelt mini gift.',
    material: 'Glossy photo paper',
    deliveryInfo: '2-4 business days',
    sortOrder: 1,
    sizes: [
      _SeedSize(label: '4x6"', price: 47),
      _SeedSize(label: '5x7"', price: 79),
    ],
  ),
  _SeedProduct(
    id: 'pg_mug',
    name: 'Photo Mug',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 399,
    description: 'Start every morning with your favourite memory. Dishwasher-safe ceramic mug with full-colour print.',
    material: 'Ceramic, food-grade glaze',
    deliveryInfo: '3-5 business days',
    sortOrder: 2,
    sizes: [
      _SeedSize(label: '11oz', price: 399),
      _SeedSize(label: '15oz', price: 499),
    ],
  ),
  _SeedProduct(
    id: 'pg_cushion',
    name: 'Photo Cushion',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 649,
    description: 'Snuggle up with a cosy cushion featuring your favourite photo. Comes with an inner filling.',
    material: 'Satin fabric cover, polyester fill',
    deliveryInfo: '4-6 business days',
    sortOrder: 3,
    sizes: [
      _SeedSize(label: '12x12"', price: 649),
      _SeedSize(label: '16x16"', price: 849),
    ],
  ),
  _SeedProduct(
    id: 'pg_keychain',
    name: 'Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 199,
    description: 'A small keepsake to carry your favourite memory everywhere. Acrylic with a metal keyring.',
    material: 'Acrylic, stainless steel ring',
    deliveryInfo: '2-4 business days',
    sortOrder: 4,
    sizes: [
      _SeedSize(label: 'Round 35mm', price: 199),
      _SeedSize(label: 'Heart 40mm', price: 249),
      _SeedSize(label: 'Rectangle 35x50mm', price: 229),
    ],
  ),
  _SeedProduct(
    id: 'pg_tote_bag',
    name: 'Photo Tote Bag',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 499,
    description: 'A sturdy canvas tote bag with your photo or design. Eco-friendly and reusable.',
    material: 'Natural canvas, water-based inks',
    deliveryInfo: '4-6 business days',
    sortOrder: 5,
    sizes: [
      _SeedSize(label: 'Small (30x30cm)', price: 499),
      _SeedSize(label: 'Large (40x40cm)', price: 649),
    ],
  ),
  _SeedProduct(
    id: 'pg_fridge_magnet',
    name: 'Fridge Magnet',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 149,
    description: 'Mini personalised magnets — perfect for gifts, souvenirs, and decorating your fridge.',
    material: 'Glossy photo paper, magnetic backing',
    deliveryInfo: '2-4 business days',
    sortOrder: 6,
    sizes: [
      _SeedSize(label: 'Set of 4 (3x3")', price: 149),
      _SeedSize(label: 'Set of 8 (3x3")', price: 249),
    ],
  ),
  _SeedProduct(
    id: 'pg_phone_case',
    name: 'Custom Phone Case',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 499,
    description: 'Protect your phone in style with a custom-printed case featuring your photo or artwork.',
    material: 'Hard polycarbonate shell',
    deliveryInfo: '4-6 business days',
    sortOrder: 7,
    sizes: [
      _SeedSize(label: 'iPhone (various models)', price: 499),
      _SeedSize(label: 'Samsung (various models)', price: 499),
    ],
  ),
  _SeedProduct(
    id: 'pg_bottle',
    name: 'Photo Water Bottle',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 699,
    description: 'Stay hydrated with a personalised stainless steel bottle. Keeps drinks cold for 24 hours.',
    material: 'Stainless steel, BPA-free',
    deliveryInfo: '5-7 business days',
    sortOrder: 8,
    sizes: [
      _SeedSize(label: '500ml', price: 699),
      _SeedSize(label: '750ml', price: 849),
    ],
  ),
  _SeedProduct(
    id: 'pg_notebook',
    name: 'Photo Notebook',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 349,
    description: 'A custom-cover notebook for journaling, sketching, or gifting. 100 lined pages inside.',
    material: 'Soft-touch laminate cover, lined paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 9,
    sizes: [
      _SeedSize(label: 'A5 (100 pages)', price: 349),
      _SeedSize(label: 'A4 (100 pages)', price: 499),
    ],
  ),
  _SeedProduct(
    id: 'pg_calendar',
    name: 'Custom Photo Calendar',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 599,
    description: '12-month personalised wall calendar with a different photo for every month.',
    material: 'Glossy photo paper, metal binding',
    deliveryInfo: '5-7 business days',
    sortOrder: 10,
    sizes: [
      _SeedSize(label: 'A4 Wall Calendar', price: 599),
      _SeedSize(label: 'A3 Wall Calendar', price: 849),
    ],
  ),
  _SeedProduct(
    id: 'pg_puzzle',
    name: 'Photo Jigsaw Puzzle',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 549,
    description: 'Turn your favourite photo into a fun jigsaw puzzle. A perfect family activity and gift.',
    material: 'Cardboard, glossy finish',
    deliveryInfo: '4-6 business days',
    sortOrder: 11,
    sizes: [
      _SeedSize(label: '120 pieces (A4)', price: 549),
      _SeedSize(label: '252 pieces (A3)', price: 749),
      _SeedSize(label: '500 pieces', price: 999),
    ],
  ),
  _SeedProduct(
    id: 'pg_mouse_pad',
    name: 'Photo Mouse Pad',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 299,
    description: 'Upgrade your desk with a custom photo mouse pad. Non-slip rubber base for smooth tracking.',
    material: 'Cloth surface, rubber base',
    deliveryInfo: '3-5 business days',
    sortOrder: 12,
    sizes: [
      _SeedSize(label: 'Standard (22x18cm)', price: 299),
      _SeedSize(label: 'Extended (90x40cm)', price: 799),
    ],
  ),
  _SeedProduct(
    id: 'pg_coaster',
    name: 'Photo Coaster Set',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 399,
    description: 'Personalised ceramic coasters — a thoughtful housewarming or wedding gift.',
    material: 'Ceramic, cork base',
    deliveryInfo: '4-6 business days',
    sortOrder: 13,
    sizes: [
      _SeedSize(label: 'Set of 4', price: 399),
      _SeedSize(label: 'Set of 6', price: 549),
    ],
  ),
  _SeedProduct(
    id: 'pg_photo_lamp',
    name: 'Photo Night Lamp',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 1299,
    description: 'A warm LED night lamp with your photo or message etched on acrylic. USB-powered.',
    material: 'Acrylic, LED base',
    deliveryInfo: '5-7 business days',
    sortOrder: 14,
    sizes: [
      _SeedSize(label: '15cm (circular)', price: 1299),
      _SeedSize(label: '20cm (circular)', price: 1599),
    ],
  ),
  _SeedProduct(
    id: 'pg_badge',
    name: 'Custom Photo Badge',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 99,
    description: 'Fun personalised badges — great for birthday parties, events, and kids.',
    material: 'Tin with safety pin back',
    deliveryInfo: '2-4 business days',
    sortOrder: 15,
    sizes: [
      _SeedSize(label: '58mm (set of 5)', price: 99),
      _SeedSize(label: '58mm (set of 10)', price: 179),
    ],
  ),
  _SeedProduct(
    id: 'pg_apron',
    name: 'Custom Photo Apron',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 799,
    description: 'A fun, personalised apron for home chefs and bakers. Full-colour printing, adjustable strap.',
    material: '100% polyester canvas',
    deliveryInfo: '5-7 business days',
    sortOrder: 16,
    sizes: [
      _SeedSize(label: 'Adult (adjustable)', price: 799),
    ],
  ),
  _SeedProduct(
    id: 'pg_teddy',
    name: 'Personalised Teddy Bear',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 899,
    description: 'A super-soft personalised teddy bear with your message or name embroidered on the chest.',
    material: 'Plush polyester, hypoallergenic fill',
    deliveryInfo: '5-7 business days',
    sortOrder: 17,
    sizes: [
      _SeedSize(label: '25cm', price: 899),
      _SeedSize(label: '40cm', price: 1299),
    ],
  ),
  _SeedProduct(
    id: 'pg_photo_book_mini',
    name: 'Pocket Photo Album',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 249,
    description: 'A pocket-sized printed photo album — perfect for gifting and carrying your memories on the go.',
    material: 'Softcover, glossy pages',
    deliveryInfo: '3-5 business days',
    sortOrder: 18,
    sizes: [
      _SeedSize(label: '3.5x3.5" (12 pages)', price: 249),
    ],
  ),
  _SeedProduct(
    id: 'pg_wooden_keepsake',
    name: 'Wooden Keepsake Box',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 1099,
    description: 'A beautifully engraved wooden box to store precious mementos and memories.',
    material: 'Solid pine, laser engraving',
    deliveryInfo: '5-7 business days',
    sortOrder: 19,
    sizes: [
      _SeedSize(label: 'Small (15x10x7cm)', price: 1099),
      _SeedSize(label: 'Large (25x18x10cm)', price: 1499),
    ],
  ),
  _SeedProduct(
    id: 'pg_card_deck',
    name: 'Custom Playing Cards',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 699,
    description: 'A full deck of 54 playing cards with your photos on the back. A fun and unique gift.',
    material: 'Premium card stock, linen finish',
    deliveryInfo: '5-7 business days',
    sortOrder: 20,
    sizes: [
      _SeedSize(label: '54 cards (standard)', price: 699),
    ],
  ),
  _SeedProduct(
    id: 'pg_wine_label',
    name: 'Custom Wine Label',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 199,
    description: 'Turn a bottle of wine into a personalised gift with your own custom label design.',
    material: 'Self-adhesive premium paper',
    deliveryInfo: '2-4 business days',
    sortOrder: 21,
    sizes: [
      _SeedSize(label: 'Set of 2', price: 199),
      _SeedSize(label: 'Set of 6', price: 499),
    ],
  ),
  _SeedProduct(
    id: 'pg_kids_print',
    name: "Children's Room Art Print",
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 399,
    description: "Bright, playful prints with children's themes — alphabets, animals, and personalised names.",
    material: 'Premium matte art paper',
    deliveryInfo: '3-5 business days',
    sortOrder: 22,
    sizes: [
      _SeedSize(label: '8x10"', price: 399),
      _SeedSize(label: '12x16"', price: 599),
    ],
  ),
  _SeedProduct(
    id: 'pg_bookmark',
    name: 'Personalised Bookmark Set',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 149,
    description: 'Custom photo or text bookmarks — a lovely gift for book lovers of all ages.',
    material: 'Laminated card with ribbon',
    deliveryInfo: '2-4 business days',
    sortOrder: 23,
    sizes: [
      _SeedSize(label: 'Set of 5', price: 149),
      _SeedSize(label: 'Set of 10', price: 249),
    ],
  ),
  _SeedProduct(
    id: 'pg_sticker_sheet',
    name: 'Custom Photo Stickers',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 199,
    description: 'Kiss-cut sticker sheets with your photos or designs. Great for gifting, branding, and fun.',
    material: 'Vinyl, waterproof and UV resistant',
    deliveryInfo: '3-5 business days',
    sortOrder: 24,
    sizes: [
      _SeedSize(label: 'A5 sheet (8-12 stickers)', price: 199),
      _SeedSize(label: 'A4 sheet (15-25 stickers)', price: 299),
    ],
  ),
  _SeedProduct(
    id: 'pg_t_shirt',
    name: 'Custom Photo T-Shirt',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalised Gifts',
    basePrice: 599,
    description: 'Wear your memories with a custom photo or text printed on a premium cotton T-shirt.',
    material: '100% premium cotton',
    deliveryInfo: '5-7 business days',
    sortOrder: 25,
    sizes: [
      _SeedSize(label: 'S', price: 599),
      _SeedSize(label: 'M', price: 599),
      _SeedSize(label: 'L', price: 599),
      _SeedSize(label: 'XL', price: 649),
      _SeedSize(label: 'XXL', price: 699),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Seed Screen
// ---------------------------------------------------------------------------

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  bool _running = false;
  String _log = '';
  bool _done = false;

  void _append(String msg) {
    setState(() => _log += '$msg\n');
  }

  Future<void> _seed() async {
    setState(() {
      _running = true;
      _log = '';
      _done = false;
    });

    final db = FirebaseFirestore.instance;
    const batchSize = 400;

    try {
      // --- Categories ---
      _append('Seeding categories...');
      var batch = db.batch();
      for (final cat in _categories) {
        batch.set(
          db.collection('categories').doc(cat.id),
          cat.toMap(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      _append('  ✓ ${_categories.length} categories written');

      // --- Products ---
      final allProducts = [
        ..._photosPrints,
        ..._photoBooks,
        ..._framesWallDecor,
        ..._personalisedGifts,
      ];

      _append('Seeding ${allProducts.length} products...');
      int count = 0;
      batch = db.batch();
      for (final p in allProducts) {
        batch.set(
          db.collection('products').doc(p.id),
          p.toMap(),
          SetOptions(merge: true),
        );
        count++;
        if (count % batchSize == 0) {
          await batch.commit();
          _append('  ... committed $count products');
          batch = db.batch();
        }
      }
      if (count % batchSize != 0) {
        await batch.commit();
      }
      _append('  ✓ $count products written');
      _append('');
      _append('DONE! All data seeded successfully.');
      setState(() => _done = true);
    } catch (e) {
      _append('ERROR: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Firestore'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This will upload all categories and products to Firestore.\n'
              'Safe to run multiple times (uses merge).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _running ? null : _seed,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload),
              label: Text(_running ? 'Seeding...' : 'Seed All Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_done) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Done — Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _log.isEmpty ? 'Press the button above to start seeding.' : _log,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
