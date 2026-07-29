// Run with: dart run scripts/seed_printo_catalog.dart
// Seeds 92 Printo catalog products from Printo_Photo_Products_Catalog_FULL.xlsx.
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snap_print/firebase_options.dart';

class _CategorySeed {
  const _CategorySeed({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'isActive': true,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class _ProductSeed {
  const _ProductSeed({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.startingPrice,
    required this.minConfig,
    required this.sizeDetails,
    required this.material,
    required this.quantity,
    required this.deliveryInfo,
    required this.description,
    required this.sourceUrl,
    required this.priceSource,
    required this.confidenceScore,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final int? startingPrice;
  final String minConfig;
  final String sizeDetails;
  final String material;
  final String quantity;
  final String deliveryInfo;
  final String description;
  final String sourceUrl;
  final String priceSource;
  final String confidenceScore;
  final int sortOrder;

  double get _basePrice => (startingPrice ?? 0).toDouble();

  Map<String, dynamic> toMap() => {
    'name': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'category': categoryName,
    'basePrice': _basePrice,
    'startingPrice': startingPrice,
    'minConfig': minConfig,
    'sizes': startingPrice == null
        ? <Map<String, dynamic>>[]
        : [
            {'label': minConfig, 'price': _basePrice},
          ],
    'sizeDetails': sizeDetails,
    'material': material,
    'quantity': quantity,
    'deliveryInfo': deliveryInfo,
    'delivery': deliveryInfo,
    'description': description,
    'sourceUrl': sourceUrl,
    'priceSource': priceSource,
    'confidenceScore': confidenceScore,
    'imageUrl': '',
    'images': <String>[],
    'isActive': true,
    'sortOrder': sortOrder,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

const _categories = [
  _CategorySeed(id: 'photo_prints', name: 'Photo Prints', sortOrder: 1),
  _CategorySeed(id: 'photo_books', name: 'Photo Books', sortOrder: 2),
  _CategorySeed(
    id: 'frames_wall_decor',
    name: 'Frames & Wall Decor',
    sortOrder: 3,
  ),
  _CategorySeed(
    id: 'personalized_gifts',
    name: 'Personalized Gifts',
    sortOrder: 4,
  ),
];

const _products = [
  _ProductSeed(
    id: 'pp_classic_photo_prints',
    name: 'Classic Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 337,
    minConfig: '15 prints',
    sizeDetails: '6x4, 7x5, 8x6, 10x8, A4 (8.3x11.7), 12x9 in',
    material: 'Photo paper (glossy/matte)',
    quantity: 'Min 15 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Classic everyday photo prints in 6 standard sizes for albums, framing, or gifting.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/classic-photo-print',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 1,
  ),
  _ProductSeed(
    id: 'pp_square_photo_prints',
    name: 'Square Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 284,
    minConfig: '15 prints',
    sizeDetails: '4x4, 5x5, 8x8 in',
    material: 'Photo paper (glossy/matte)',
    quantity: 'Min 15 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Square-format photo prints popular for Instagram-style collections and scrapbooking.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/square-photo-print',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 2,
  ),
  _ProductSeed(
    id: 'pp_retro_polaroid_prints',
    name: 'Retro Polaroid Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 478,
    minConfig: '15 prints',
    sizeDetails: '3.5x4.25 in',
    material: 'Photo paper with white polaroid-style border',
    quantity: 'Min 15 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Vintage polaroid-style photo prints with classic white borders.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/retro-photo-print',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 3,
  ),
  _ProductSeed(
    id: 'pp_passport_and_stamp_prints',
    name: 'Passport & Stamp Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 213,
    minConfig: '20 prints (minimum order)',
    sizeDetails: '35x45 mm, 20x25 mm',
    material: 'Photo paper',
    quantity: 'Min 20 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Standard passport and stamp-size photo prints for official documents.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/passport-photo-print',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 4,
  ),
  _ProductSeed(
    id: 'pp_instant_photo_prints',
    name: 'Instant Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 443,
    minConfig: '15 prints',
    sizeDetails: '4x6, 6x8 in',
    material: 'Photo paper',
    quantity: 'Min 15 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Quick-turnaround photo prints in popular standard sizes.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/instant-photos',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 5,
  ),
  _ProductSeed(
    id: 'pp_bulk_photo_prints',
    name: 'Bulk Photo Prints',
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    startingPrice: 1003,
    minConfig: '50 prints (minimum order)',
    sizeDetails: '6x4, 7x5, 8x6 in',
    material: 'Photo paper',
    quantity: 'Min 50 prints',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Bulk photo printing at discounted per-print rates for events and studios.',
    sourceUrl:
        'https://printo.in/categories/photo-prints/customizable-products/photos-bulk-printing',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 6,
  ),
  _ProductSeed(
    id: 'pb_classic_photo_albums',
    name: 'Classic Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 1475,
    minConfig: '1 piece',
    sizeDetails: 'A4 Landscape & 12x12 in Square',
    material: 'Premium matte hardcover, window-cut design; 300gsm glossy paper',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru only; standard nationwide delivery otherwise',
    description:
        'Hardcover photo album with window-cut cover. A4: Black/RedWine/Camel Tan; Square: Black/Camel Tan. Spine 5/7/9mm = 20/25/30 sheets.',
    sourceUrl:
        'https://printo.in/categories/classic-photo-albums/customizable-products/classic-photo-albums',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 7,
  ),
  _ProductSeed(
    id: 'pb_pre_wedding_photo_albums',
    name: 'Pre Wedding Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover pre-wedding album. Also lists 3 unpriced \'Pro\' tiers (Acroluxe leather, Custom Cover, Encanto jute/wood) in 12x18 and 12x12 sizes.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/capture-the-moments-photo-books',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 8,
  ),
  _ProductSeed(
    id: 'pb_baby_shower_photo_albums',
    name: 'Baby Shower Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover baby shower album with 3 unpriced Pro upgrade tiers.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/golden-joy-baby-photo-book',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 9,
  ),
  _ProductSeed(
    id: 'pb_baby_album_photo_albums',
    name: 'Baby Album Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover baby memories album with 3 unpriced Pro upgrade tiers.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/baby-photo-books-premium',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 10,
  ),
  _ProductSeed(
    id: 'pb_anniversary_photo_albums',
    name: 'Anniversary Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover anniversary album with 3 unpriced Pro upgrade tiers.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/wedding-memories-photo-books-premium',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 11,
  ),
  _ProductSeed(
    id: 'pb_travel_photo_albums',
    name: 'Travel Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover travel album. Also lists Acroluxe (leather), Custom Cover, and Encanto (jute/wood) Pro tiers at 12x18 and 12x12 with no separate listed price.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/travel-photo-books-premium',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 12,
  ),
  _ProductSeed(
    id: 'pb_milestone_birthday_photo_albums',
    name: 'Milestone Birthday Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover milestone birthday album with 3 unpriced Pro upgrade tiers.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/birthday-memories-photo-books',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 13,
  ),
  _ProductSeed(
    id: 'pb_graduation_year_photo_albums',
    name: 'Graduation Year Photo Albums',
    categoryId: 'photo_books',
    categoryName: 'Photo Books',
    startingPrice: 2360,
    minConfig: '1 piece (base tier)',
    sizeDetails: '10x10 in and A4; Pro tiers: 12x18 in and 12x12 in',
    material:
        'Hardcover, Matte/Glossy/Velvet; Pro: leather / jute+wood / full-custom covers',
    quantity: '20-60 pages (Premium)',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium hardcover graduation album with 3 unpriced Pro upgrade tiers.',
    sourceUrl:
        'https://printo.in/categories/photobook/customizable-products/graduation-year-photo-books',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 14,
  ),
  _ProductSeed(
    id: 'fw_classic_photo_frames',
    name: 'Classic Photo Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 413,
    minConfig: '1 piece',
    sizeDetails: '4x6, 6x8, A4 (8.3x11.7), 12x18 in',
    material:
        'MDF base + clear acrylic; textured canvas or matte-coated paper; 9 frame styles',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Classic MDF-framed photo display in 9 styles (Plain Black/Brown, Stripes, Maze, Gold, etc.).',
    sourceUrl:
        'https://printo.in/categories/photo-frames/customizable-products/classic-photo-frames',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 15,
  ),
  _ProductSeed(
    id: 'fw_wall_photo_frames_large_photo_frames',
    name: 'Wall Photo Frames (Large Photo Frames)',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 1116,
    minConfig: '1 piece',
    sizeDetails: '9x12, 12x12, 12x18, 14x18, 18x24, 27x36 in',
    material:
        'Synthetic frame (0.68in thick) + MDF base; Premium Vinyl or 300gsm Canvas; no acrylic',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Large wall-mounted frames without acrylic in 9 styles, delivered with wall-hanging hook.',
    sourceUrl:
        'https://printo.in/categories/photo-frames/customizable-products/large-photo-frames',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 16,
  ),
  _ProductSeed(
    id: 'fw_canvas_photo_frames_framed_canvas',
    name: 'Canvas Photo Frames (Framed Canvas)',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 1208,
    minConfig: '1 piece',
    sizeDetails: '9x12, 12x12, 12x18, 14x18, 18x24, 27x36 in',
    material:
        'Synthetic frame + MDF base; 300gsm Premium Textured Canvas only (no acrylic/glass)',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Wall-mounted frame printed exclusively on premium textured canvas in 9 frame styles.',
    sourceUrl:
        'https://printo.in/categories/photo-frames/customizable-products/framed-canvas',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 17,
  ),
  _ProductSeed(
    id: 'fw_desktop_collage_foldable_frames',
    name: 'Desktop Collage Foldable Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: null,
    minConfig: '1 piece',
    sizeDetails: '1-Fold: 2x 4x6 in; 2-Fold: 2x 4x6 in + 1x 6x10 in',
    material:
        'Synthetic frame in Black or Brown; desktop stand; includes complimentary photo prints',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru only; standard nationwide delivery otherwise',
    description:
        'Foldable desktop collage frame showing 2 or 3 photos simultaneously. Includes complimentary photo prints. Price not listed on category page.',
    sourceUrl:
        'https://printo.in/categories/photo-frames/customizable-products/desktop-collage-foldable-frames',
    priceSource: 'Not Available',
    confidenceScore: 'Low',
    sortOrder: 18,
  ),
  _ProductSeed(
    id: 'fw_frameless_photo_frame',
    name: 'Frameless Photo Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 609,
    minConfig: '1 piece',
    sizeDetails: 'A3, A4, A5',
    material:
        '3mm and 5mm black/white boards, matte lamination, 4 gold corner clips',
    quantity: 'MOQ 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Sleek frameless display board with matte-laminated print and gold corner clips; wall or tabletop.',
    sourceUrl:
        'https://printo.in/categories/framease/customizable-products/frameless-photo-frame',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 19,
  ),
  _ProductSeed(
    id: 'fw_personalized_selfie_frames',
    name: 'Personalized Selfie Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 763,
    minConfig: '1 piece',
    sizeDetails: '7 sizes (specific dimensions not listed)',
    material: '5mm white sun board, single-sided print',
    quantity: 'Not specified',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Large event-prop selfie photo frame for weddings/parties/graduation, personalised with customer designs.',
    sourceUrl:
        'https://printo.in/categories/selfie-frames/customizable-products/personalized-selfie-frames',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 20,
  ),
  _ProductSeed(
    id: 'fw_led_photo_frames',
    name: 'LED Photo Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 3157,
    minConfig: '1 piece',
    sizeDetails: '10x10, 12x12, 12x18 in',
    material:
        'Rexin material frame (Brown/Grey); Square/Rectangle/Octagon shapes; LED strip + adaptor included',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Illuminated LED photo frame in 3 sizes and 3 shapes, with LED lighting included.',
    sourceUrl:
        'https://printo.in/categories/led-photo-frames/customizable-products/led-photo-frames',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 21,
  ),
  _ProductSeed(
    id: 'fw_personalised_acrylic_photo_frames',
    name: 'Personalised Acrylic Photo Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 638,
    minConfig: '1 piece',
    sizeDetails:
        'Desktop stands: 4x6, 6x8 in; Wall hangings: 12x12, A4, 12x18 in',
    material:
        'Crystal-clear acrylic; 3mm Standard (Indigo print, white back) or 5mm Premium (UV print, black back)',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'General acrylic photo frame line; desktop stand or wall hanging; 3mm or 5mm acrylic.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/personalized-photo-acrylic-prints',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 22,
  ),
  _ProductSeed(
    id: 'fw_standard_acrylic_photo_frames',
    name: 'Standard Acrylic Photo Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 638,
    minConfig: '1 piece',
    sizeDetails: '4x6, 6x8 in',
    material:
        '3mm acrylic, white back, Indigo/UV print; desktop stand or wall hanging',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Entry-level 3mm acrylic photo frame in 4x6 and 6x8 sizes.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/standard-acrylic-photo-frames',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 23,
  ),
  _ProductSeed(
    id: 'fw_premium_acrylic_photo_frames',
    name: 'Premium Acrylic Photo Frames',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 829,
    minConfig: '1 piece',
    sizeDetails: '4x6, 6x8, 12x12, A4 (8.3x11.7), 12x18 in',
    material:
        '5mm acrylic, black back, UV print; desktop stand or wall hanging',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Premium 5mm-thick acrylic photo frame with UV printing across 5 sizes.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/premium-photo-acrylic-prints',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 24,
  ),
  _ProductSeed(
    id: 'fw_ready_to_buy_premium_frame',
    name: 'Ready to Buy Premium Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 943,
    minConfig: '1 piece',
    sizeDetails: 'Small 7x9 in (fits 4x6 photo); Big 9x11 in (fits 6x8 photo)',
    material:
        '9mm glossy acrylic, buffed edge; includes 1 free photo print pre-inserted (270gsm glossy)',
    quantity: 'MOQ 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Ready-made premium acrylic desktop frame with a pre-inserted free photo print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/ready-to-buy-premium-frame',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 25,
  ),
  _ProductSeed(
    id: 'fw_custom_premium_frame',
    name: 'Custom Premium Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 943,
    minConfig: '10 pieces (MOQ 10)',
    sizeDetails: 'Small 7x9 in (fits 4x6 photo); Big 9x11 in (fits 6x8 photo)',
    material:
        '9mm glossy acrylic; full brand-design customization; photo on 270gsm glossy',
    quantity: 'MOQ 10 units',
    deliveryInfo: '3-7 working days based on order quantity',
    description:
        'Corporate-gifting variant with full custom frame branding. Same acrylic build as Ready to Buy, MOQ 10.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/custom-acrylic-photo-frame',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 26,
  ),
  _ProductSeed(
    id: 'fw_leatherette_acrylic_frame',
    name: 'Leatherette Acrylic Frame',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 1020,
    minConfig: '1 piece',
    sizeDetails: '6x8, A4 (8.3x11.7), A3 (11.7x16.5) in',
    material:
        '3mm clear acrylic + leatherette border (Black or Camel Tan); single-sided Indigo print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Acrylic frame with leatherette border in Black or Camel Tan.',
    sourceUrl:
        'https://printo.in/categories/acrylic-prints/customizable-products/leatherette-acrylic-frame',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 27,
  ),
  _ProductSeed(
    id: 'fw_acrylic_photo_cut_outs',
    name: 'Acrylic Photo Cut Outs',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 2359,
    minConfig: '1 piece',
    sizeDetails: 'Big: A4 (8.3x11.7 in); Small: 5x7 in (custom-shape cut)',
    material:
        'Imported transparent acrylic, black backing; black acrylic base (big) or magnets (small)',
    quantity: 'Not specified',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Free-standing acrylic cut-out shaped to the outline of the uploaded photo, creating a 3D display effect.',
    sourceUrl:
        'https://printo.in/categories/acrylic-desk-stands/customizable-products/acrylic-photo-cut-outs',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 28,
  ),
  _ProductSeed(
    id: 'fw_canvas_gallery_wraps',
    name: 'Canvas Gallery Wraps',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 879,
    minConfig: '1 piece',
    sizeDetails:
        'Rectangle: 9x12, 12x18, 14x18, 18x24, 27x36 in; Square: 12x12 in',
    material:
        '300gsm Premium Textured Canvas, glossy coating; 1-inch wooden frame',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Canvas print stretched on a 1-inch wooden frame for gallery-wrap wall display.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/canvas-wraps',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 29,
  ),
  _ProductSeed(
    id: 'fw_eco_friendly_canvas_posters',
    name: 'Eco-Friendly Canvas Posters',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 334,
    minConfig: '1 piece',
    sizeDetails: '9x12, 14x18, 18x24, 25x18, 27x36, 32x12 in',
    material: '300gsm Premium Textured Canvas, glossy coating, unframed flat',
    quantity: 'Order from 1 poster',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Unframed canvas poster in 6 sizes on premium textured canvas.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/canvas-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 30,
  ),
  _ProductSeed(
    id: 'fw_2_split_vertical_canvas_wrap',
    name: '2 Split Vertical Canvas Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 1958,
    minConfig: '1 unit (set)',
    sizeDetails: '10x18 in x 2 pieces',
    material:
        '300gsm Premium Textured Canvas, glossy coating, 1-inch wooden frame',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Two-panel vertical split canvas wrap set.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/two-split-vertical-canvas-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 31,
  ),
  _ProductSeed(
    id: 'fw_3_split_rectangle_canvas_wrap',
    name: '3 Split Rectangle Canvas Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 3544,
    minConfig: '1 unit (set)',
    sizeDetails: '18x25 in x1 + 12x12 in x2',
    material:
        '300gsm Premium Textured Canvas, glossy coating, 1-inch wooden frame',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Three-panel canvas combo: one rectangle plus two squares.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/three-split-rectangle-canvas-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 32,
  ),
  _ProductSeed(
    id: 'fw_3_split_vertical_canvas_wrap',
    name: '3 Split Vertical Canvas Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 5299,
    minConfig: '1 unit (set)',
    sizeDetails: '12x32 in x 3 pieces',
    material:
        '300gsm Premium Textured Canvas, glossy coating, 1.5-inch wooden frame',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Three tall vertical canvas panels for a dramatic split wall display.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/three-split-vertical-canvas-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 33,
  ),
  _ProductSeed(
    id: 'fw_4_split_square_canvas_wrap',
    name: '4 Split Square Canvas Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 3544,
    minConfig: '1 set',
    sizeDetails: '12x12 in x 4 pieces',
    material:
        '300gsm Premium Textured Canvas, glossy coating, 1-inch wooden frame',
    quantity: 'Order from 1 set',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Four 12x12in square canvas panels for a unified split-canvas wall display.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/four-split-square-canvas-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 34,
  ),
  _ProductSeed(
    id: 'fw_5_split_rectangle_canvas_wrap',
    name: '5 Split Rectangle Canvas Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 5299,
    minConfig: '1 unit (set)',
    sizeDetails: '18x25 in x1 + 12x12 in x4',
    material:
        '300gsm Premium Textured Canvas, glossy coating, 1-inch wooden frame',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Five-panel canvas combo: one rectangle plus four squares.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/five-split-rectangle-canvas-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 35,
  ),
  _ProductSeed(
    id: 'fw_mdf_canvas_gallery_wrap',
    name: 'MDF Canvas Gallery Wrap',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 656,
    minConfig: '1 piece',
    sizeDetails: '5 shapes: Rectangle, Square, Hexagon, Octagon, Triangle',
    material: '300gsm Premium Textured Canvas on 5mm MDF board',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Canvas print on 5mm MDF in 5 distinct shapes.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/mdf-gallery-wrap',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 36,
  ),
  _ProductSeed(
    id: 'fw_personalised_mdf_canvas_prints',
    name: 'Personalised MDF Canvas Prints',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 418,
    minConfig: '1 piece',
    sizeDetails: '4 shapes: Rectangle, Square, Circle, Oval',
    material: '300gsm Premium Textured Canvas on 5mm MDF board',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Canvas-on-MDF in 4 shapes (Rectangle, Square, Circle, Oval).',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/personalized-mdf-prints',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 37,
  ),
  _ProductSeed(
    id: 'fw_premium_mdf_prints',
    name: 'Premium MDF Prints',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 373,
    minConfig: '1 piece',
    sizeDetails: '12x18 in, A4 (8.3x11.7 in), 12x12 in Square',
    material: 'Non-tearable print media on 5mm MDF board, glossy coating',
    quantity: 'Order from 1 poster',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru only; standard nationwide delivery otherwise',
    description:
        'Photo on non-tearable media mounted on 5mm MDF board; rectangle and square shapes.',
    sourceUrl:
        'https://printo.in/categories/photo-plaque/customizable-products/premium-mdf-prints',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 38,
  ),
  _ProductSeed(
    id: 'fw_rolled_canvas_posters',
    name: 'Rolled Canvas Posters',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 361,
    minConfig: '1 piece',
    sizeDetails: '9x12, 14x18, 18x24, 25x18, 27x36, 32x12 in',
    material: '300gsm Premium Textured Canvas, glossy coating, shipped rolled',
    quantity: 'Order from 1 poster',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Unmounted canvas poster shipped rolled, same sizes as Eco-Friendly Canvas Posters.',
    sourceUrl:
        'https://printo.in/categories/canvas/customizable-products/roll-canvas',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 39,
  ),
  _ProductSeed(
    id: 'fw_photo_with_wooden_stand',
    name: 'Photo with Wooden Stand',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 607,
    minConfig: '1 piece',
    sizeDetails: '6x4 and 8x6 in',
    material:
        'Transparent acrylic with natural wood base; double-sided viewing',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Double-sided acrylic photo display on a natural wood stand, showing two images from either side.',
    sourceUrl:
        'https://printo.in/categories/photo-with-wooden-stand/customizable-products/photo-with-wooden-stand',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 40,
  ),
  _ProductSeed(
    id: 'fw_photo_pendant_wooden_stand',
    name: 'Photo Pendant Wooden Stand',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 848,
    minConfig: '1 piece',
    sizeDetails:
        '2 pendant shapes (Rectangle and Heart); exact dimensions not on page',
    material:
        'Photo printed on both sides; natural wood base with hooks for suspended display',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Dual-sided photo pendant suspended from hooks on a natural wood stand - photo elegantly floats within the frame.',
    sourceUrl:
        'https://printo.in/categories/photo-with-wooden-stand/customizable-products/wooden-photo-pendant',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 41,
  ),
  _ProductSeed(
    id: 'fw_wooden_engraved_plaque_with_photo',
    name: 'Wooden Engraved Plaque with Photo',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 1102,
    minConfig: '1 piece',
    sizeDetails: '8x10 in frame; 4x6 in photo insert',
    material:
        '1-inch thick beach wood, rounded corners; custom engraving + acrylic photo insert',
    quantity: 'Not specified',
    deliveryInfo: 'Not specified on page',
    description:
        'Engraved wooden plaque combining laser engraving with an acrylic photo insert.',
    sourceUrl:
        'https://printo.in/categories/photo-plaque/customizable-products/wooden-plaque-with-photo',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 42,
  ),
  _ProductSeed(
    id: 'fw_rectangle_wall_decals',
    name: 'Rectangle Wall Decals',
    categoryId: 'frames_wall_decor',
    categoryName: 'Frames & Wall Decor',
    startingPrice: 161,
    minConfig: '1 piece',
    sizeDetails: 'Rectangle; multiple sizes (see configurator)',
    material:
        'White vinyl / clear vinyl / window decal / frosted vinyl; eco-solvent print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Custom-printed rectangle wall/window decals with customer\'s photo/design. Related shapes: Square Rs 294, Circle Rs 143, Custom Shape Rs 156.',
    sourceUrl:
        'https://printo.in/categories/decals/customizable-products/rectangle-wall-decals',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 43,
  ),
  _ProductSeed(
    id: 'pg_personalised_white_photo_mug',
    name: 'Personalised White Photo Mug',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 326,
    minConfig: '1 piece',
    sizeDetails: '325 ml; print area 20x8 cm',
    material: 'White ceramic, sublimation; microwave/dishwasher safe',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Classic white ceramic photo mug (325ml) with full-colour sublimation print.',
    sourceUrl:
        'https://printo.in/categories/mugs/customizable-products/custom-photo-mugs',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 44,
  ),
  _ProductSeed(
    id: 'pg_photo_mini_mug',
    name: 'Photo Mini Mug',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 334,
    minConfig: '1 piece',
    sizeDetails: '175 ml; mug 7.2x7.2 cm; print area 16x6 cm',
    material: 'White ceramic, sublimation; microwave/dishwasher safe',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Compact 175ml ceramic mug for espresso/tea; full-colour sublimation.',
    sourceUrl:
        'https://printo.in/categories/mugs/customizable-products/small-coffee-mug',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 45,
  ),
  _ProductSeed(
    id: 'pg_bulk_mugs',
    name: 'Bulk Mugs',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 225,
    minConfig: '50 pieces (price per piece at 50pcs)',
    sizeDetails: '325 ml',
    material: 'Ceramic, sublimation print',
    quantity: 'Bulk order',
    deliveryInfo: 'Not specified on page',
    description:
        'Bulk ceramic photo mugs (325ml) at discounted per-unit pricing.',
    sourceUrl:
        'https://printo.in/categories/mugs/customizable-products/bulk-mugs',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 46,
  ),
  _ProductSeed(
    id: 'pg_photo_magic_mug',
    name: 'Photo Magic Mug',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: null,
    minConfig: '1 piece',
    sizeDetails: '325 ml; mug 8x9.5 cm; print area 20x8 cm',
    material:
        'Black ceramic, colour-changes with heat, sublimation; dishwasher/microwave safe',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Heat-sensitive mug: black at rest, reveals photo when filled with hot liquid. Price not shown on Mugs category listing.',
    sourceUrl:
        'https://printo.in/categories/mugs/customizable-products/Photo-Magic-Mug',
    priceSource: 'Not Available',
    confidenceScore: 'Low',
    sortOrder: 47,
  ),
  _ProductSeed(
    id: 'pg_personalised_beer_mug',
    name: 'Personalised Beer Mug',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 590,
    minConfig: '1 piece',
    sizeDetails: '500 ml (16 oz)',
    material: 'Clear or frosted glass; sublimation print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        '500ml glass beer mug in gloss or frosted finish; customised with photo/text/logo.',
    sourceUrl:
        'https://printo.in/categories/mugs/customizable-products/beer-mug',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 48,
  ),
  _ProductSeed(
    id: 'pg_personalized_sipper_bottle_600_ml',
    name: 'Personalized Sipper Bottle (600 ml)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 407,
    minConfig: '1 piece',
    sizeDetails: '600 ml',
    material: 'Aluminium/stainless steel',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        '600ml personalised sipper bottle with custom photo/design/logo print.',
    sourceUrl:
        'https://printo.in/categories/sippers-and-bottles/customizable-products/personalized-sipper-bottle-600ml',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 49,
  ),
  _ProductSeed(
    id: 'pg_personalized_spout_sipper_bottle_750_ml',
    name: 'Personalized Spout Sipper Bottle (750 ml)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 864,
    minConfig: '1 piece',
    sizeDetails: '750 ml',
    material: 'Premium stainless steel with spout cap',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: '750ml spout sipper bottle with custom photo/design/logo.',
    sourceUrl:
        'https://printo.in/categories/sippers-and-bottles/customizable-products/personalized-spout-sipper-bottle',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 50,
  ),
  _ProductSeed(
    id: 'pg_multicolour_printed_steel_bottle_1000_ml',
    name: 'Multicolour Printed Steel Bottle (1000 ml)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 735,
    minConfig: '1 piece',
    sizeDetails: '1000 ml',
    material: 'Stainless steel, multicolour full-colour print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        '1-litre stainless steel bottle with full multicolour custom photo/design print.',
    sourceUrl:
        'https://printo.in/categories/sippers-and-bottles/customizable-products/personalized-steel-bottle-multicolour-printed',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 51,
  ),
  _ProductSeed(
    id: 'pg_personalized_mason_jar',
    name: 'Personalized Mason Jar',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 494,
    minConfig: '1 piece',
    sizeDetails: 'Not specified',
    material: 'Glass mason jar with custom print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Glass mason jar personalised with custom photo/design/logo.',
    sourceUrl:
        'https://printo.in/categories/sippers-and-bottles/customizable-products/personalized-mason-jar',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 52,
  ),
  _ProductSeed(
    id: 'pg_personalized_cola_bottle_340_ml',
    name: 'Personalized Cola Bottle (340 ml)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 473,
    minConfig: '1 piece',
    sizeDetails: '340 ml',
    material: 'Glass cola-style bottle with custom print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        '340ml glass cola-style bottle personalised with custom photo/design/logo.',
    sourceUrl:
        'https://printo.in/categories/sippers-and-bottles/customizable-products/personalized-cola-bottle',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 53,
  ),
  _ProductSeed(
    id: 'pg_premium_photo_matte_posters',
    name: 'Premium Photo Matte Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 176,
    minConfig: '1 piece',
    sizeDetails: 'A4, A3, A3+, A2, A1, A0',
    material: '180gsm Photo Matte paper, inkjet print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Matte-finish photo poster in 6 sizes from A4 to A0; fingerprint-resistant.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/premium-photo-paper-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 54,
  ),
  _ProductSeed(
    id: 'pg_premium_photo_glossy_posters',
    name: 'Premium Photo Glossy Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 192,
    minConfig: '1 piece',
    sizeDetails: 'A4, A3, A3+, A2, A1, A0',
    material: '210gsm Photo Glossy paper, eco-solvent inkjet',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Glossy-finish photo poster in 6 sizes for vibrant home/office decor.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/premium-photo-glossy-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 55,
  ),
  _ProductSeed(
    id: 'pg_large_format_posters',
    name: 'Large Format Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 432,
    minConfig: '1 piece',
    sizeDetails: 'A3, A2, A1, A0',
    material:
        'Non-tearable paper, Self-Adhesive Vinyl, or 3M White-Back Vinyl; single-sided',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Large-format poster in 4 sizes and 3 material types.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/large-format-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 56,
  ),
  _ProductSeed(
    id: 'pg_standard_paper_posters',
    name: 'Standard Paper Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 47,
    minConfig: '2 pieces (minimum order)',
    sizeDetails: 'A4, A3, A3+',
    material: 'Glossy or Matte coated paper, 170-220gsm',
    quantity: 'Order from 2 units',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description: 'Everyday digital print poster in 3 sizes and 2 finishes.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/standard-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 57,
  ),
  _ProductSeed(
    id: 'pg_special_paper_posters',
    name: 'Special Paper Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 162,
    minConfig: '1 piece',
    sizeDetails: '3 sizes (specific dimensions not listed)',
    material: 'Metallic, Premium Textured, or Recycled paper; 10 options',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Specialty-paper posters in 10 distinct finishes for premium display.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/special-paper-posters',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 58,
  ),
  _ProductSeed(
    id: 'pg_premium_print_posters',
    name: 'Premium Print Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 57,
    minConfig: '5 pieces (MOQ 5)',
    sizeDetails: 'A3, A4',
    material: '300gsm paper board, Matte Lamination or Linen Textured',
    quantity: 'MOQ 5 units',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Bulk-oriented premium posters in A3/A4 with matte or linen finish.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/premium-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 59,
  ),
  _ProductSeed(
    id: 'pg_raised_foil_posters_premium_finish',
    name: 'Raised Foil Posters (Premium Finish)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 194,
    minConfig: '1 piece',
    sizeDetails: 'A4, A3, A3+',
    material:
        '300/350gsm coated paper, Matte or Velvet lamination + Gold/Silver foil & Spot UV',
    quantity: 'MOQ 1 piece',
    deliveryInfo: 'Not specified on page',
    description:
        'Embellished poster with raised gold/silver foil and Spot UV highlights.',
    sourceUrl:
        'https://printo.in/categories/premium-posters/customizable-products/premium-finish-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 60,
  ),
  _ProductSeed(
    id: 'pg_non_tearable_posters',
    name: 'Non-Tearable Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 432,
    minConfig: '1 piece',
    sizeDetails: 'A3, A2, A1, A0',
    material: 'Non-tearable synthetic paper, eco-solvent inkjet',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Durable synthetic-paper posters for high-traffic indoor/outdoor use.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/non-tearable-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 61,
  ),
  _ProductSeed(
    id: 'pg_sun_board_posters',
    name: 'Sun Board Posters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 717,
    minConfig: '1 piece',
    sizeDetails: 'A3, A2, A1, A0',
    material: '5mm PVC foam (sun) board, eco-solvent vinyl print',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Rigid lightweight foam-board posters for outdoor advertising and event signage.',
    sourceUrl:
        'https://printo.in/categories/posters/customizable-products/foam-mounted-posters',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 62,
  ),
  _ProductSeed(
    id: 'pg_photo_fridge_magnet_combo_set_of_4',
    name: 'Photo Fridge Magnet Combo Set-of-4',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 700,
    minConfig: '1 set (4 magnets)',
    sizeDetails: '2.5x2.5 in x 4 pieces',
    material: '2mm thick flexible magnet, full-colour print',
    quantity: '1 set = 4 magnets',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Set of 4 square photo fridge magnets on flexible 2mm magnet material.',
    sourceUrl:
        'https://printo.in/categories/magnets/customizable-products/combo-set-of-4',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 63,
  ),
  _ProductSeed(
    id: 'pg_acrylic_photo_fridge_magnets',
    name: 'Acrylic Photo Fridge Magnets',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 955,
    minConfig: '1 piece',
    sizeDetails: '5 shapes (dimensions not listed)',
    material: '4mm acrylic + magnet, glossy full-colour print',
    quantity: 'Not specified',
    deliveryInfo: 'Not specified on page',
    description: 'Premium 4mm acrylic-bodied fridge magnet in 5 shapes.',
    sourceUrl:
        'https://printo.in/categories/magnets/customizable-products/acrylic-photo-magnets',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 64,
  ),
  _ProductSeed(
    id: 'pg_premium_canvas_fridge_magnets',
    name: 'Premium Canvas Fridge Magnets',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 489,
    minConfig: '1 set (2 magnets)',
    sizeDetails: '3x3 in and 4x4 in (set of 2)',
    material: 'Canvas print magnet',
    quantity: 'Set of 2',
    deliveryInfo: 'Not specified on page',
    description: 'Set of 2 canvas-textured photo fridge magnets.',
    sourceUrl:
        'https://printo.in/categories/magnets/customizable-products/canvas-magnets',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 65,
  ),
  _ProductSeed(
    id: 'pg_rectangle_and_square_fridge_magnets_set_of_4',
    name: 'Rectangle & Square Fridge Magnets Set-of-4',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 924,
    minConfig: '1 set (4 magnets)',
    sizeDetails: '4x3 in x2 + 5x5 in x2',
    material: '2mm thick flexible magnet',
    quantity: '1 set = 4 magnets',
    deliveryInfo: 'Not specified on page',
    description:
        'Mixed set of 4 magnets (two 4x3in rectangles + two 5x5in squares).',
    sourceUrl:
        'https://printo.in/categories/magnets/customizable-products/square-photo-magnet',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 66,
  ),
  _ProductSeed(
    id: 'pg_a5_desktop_calendar_landscape',
    name: 'A5 Desktop Calendar (Landscape)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 306,
    minConfig: '1 piece',
    sizeDetails: 'A5, 8.3x5.8 in landscape',
    material:
        '7 sheets, 300gsm glossy or 250gsm shimmer; black wiro binding with stand',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Compact landscape desktop calendar with black wiro binding and stand.',
    sourceUrl:
        'https://printo.in/categories/desk-calendars/customizable-products/a5-desktop-calendar-landscape',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 67,
  ),
  _ProductSeed(
    id: 'pg_long_desktop_calendar',
    name: 'Long Desktop Calendar',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 354,
    minConfig: '1 piece',
    sizeDetails: '10x3.5 in',
    material:
        '7 sheets, 300gsm glossy or 250gsm shimmer; black hard fusion board stand',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Elongated panoramic desktop calendar on a black hard fusion board stand.',
    sourceUrl:
        'https://printo.in/categories/desk-calendars/customizable-products/long-desktop-calendar',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 68,
  ),
  _ProductSeed(
    id: 'pg_personalized_wall_calendar',
    name: 'Personalized Wall Calendar',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 472,
    minConfig: '1 piece',
    sizeDetails: 'A3',
    material: '7 sheets, 300gsm glossy or 250gsm shimmer; spiral/wiro binding',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'A3 wall calendar with spiral binding, full-colour double-sided print, 12 monthly photo slots.',
    sourceUrl:
        'https://printo.in/categories/wall-calendars/customizable-products/a3-wall-calendars',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 69,
  ),
  _ProductSeed(
    id: 'pg_small_square_wooden_base_calendar',
    name: 'Small Square Wooden Base Calendar',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 295,
    minConfig: '1 piece',
    sizeDetails: '5x5 in',
    material: '6 sheets, 300gsm glossy or 250gsm shimmer; natural wooden stand',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Compact 5x5in desk calendar on a natural wooden stand. The wooden stand itself cannot be personalised.',
    sourceUrl:
        'https://printo.in/categories/desk-calendars/customizable-products/mini-calendars',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 70,
  ),
  _ProductSeed(
    id: 'pg_alphabet_with_photo_keychain',
    name: 'Alphabet with Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 378,
    minConfig: '1 piece',
    sizeDetails: 'Not listed (size chart visible on page)',
    material: 'Black/white acrylic, 3mm thick',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Acrylic keychain combining an alphabet letter cut-out with a personal photo.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/alphabet-with-photo-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 71,
  ),
  _ProductSeed(
    id: 'pg_square_acrylic_photo_keychain',
    name: 'Square Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Square shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Square acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/square-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 72,
  ),
  _ProductSeed(
    id: 'pg_circle_acrylic_photo_keychain',
    name: 'Circle Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Circle shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Circle acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/circle-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 73,
  ),
  _ProductSeed(
    id: 'pg_heart_acrylic_photo_keychain',
    name: 'Heart Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Heart shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Heart-shaped acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/heart-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 74,
  ),
  _ProductSeed(
    id: 'pg_oval_acrylic_photo_keychain',
    name: 'Oval Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Oval shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Oval acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/oval-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 75,
  ),
  _ProductSeed(
    id: 'pg_rectangle_acrylic_photo_keychain',
    name: 'Rectangle Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Rectangle shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Rectangle acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/rectangle-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 76,
  ),
  _ProductSeed(
    id: 'pg_star_acrylic_photo_keychain',
    name: 'Star Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Star shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Star-shaped acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/star-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 77,
  ),
  _ProductSeed(
    id: 'pg_octagon_acrylic_photo_keychain',
    name: 'Octagon Acrylic Photo Keychain',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 189,
    minConfig: '1 piece',
    sizeDetails: 'Octagon shape',
    material: 'Acrylic, full-colour single-sided print, black back',
    quantity: 'Order from 1 unit',
    deliveryInfo: 'Not specified on page',
    description:
        'Octagon-shaped acrylic photo keychain with full-colour single-sided print.',
    sourceUrl:
        'https://printo.in/categories/acrylic-keychain/customizable-products/octogon-keychain',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 78,
  ),
  _ProductSeed(
    id: 'pg_personalized_mobile_pop_socket',
    name: 'Personalized Mobile Pop Socket',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 143,
    minConfig: '1 piece',
    sizeDetails: '40 mm diameter',
    material: 'Repositionable adhesive base',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru only; standard nationwide delivery otherwise',
    description:
        'Collapsible phone grip/stand (PopSocket-style) personalised with custom photo/design.',
    sourceUrl:
        'https://printo.in/categories/mobile-accessories/customizable-products/personalized-mobile-pop-socket',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 79,
  ),
  _ProductSeed(
    id: 'pg_personalized_tote_bags',
    name: 'Personalized Tote Bags',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 327,
    minConfig: '1 piece',
    sizeDetails: '15x16 in and 11x12 in',
    material:
        '140gsm natural cotton or 320gsm canvas cotton; Natural or Black; Digital or screen print',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Eco-friendly cotton/canvas tote bag personalised with photos/logos. Price Rs 327 confirmed from Cotton Carry Bags category page.',
    sourceUrl:
        'https://printo.in/categories/tote-bag/customizable-products/personalized-tote-bag',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 80,
  ),
  _ProductSeed(
    id: 'pg_acrylic_photo_coasters',
    name: 'Acrylic Photo Coasters',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 612,
    minConfig: 'Set of 4 or Set of 6',
    sizeDetails: '4 shapes: Square, Circle, Heart, and other',
    material: '2mm thick White & Black acrylic',
    quantity: 'Sets of 4 or 6',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Personalised acrylic table coasters in 4 shapes, sold in sets of 4 or 6.',
    sourceUrl:
        'https://printo.in/categories/coasters/customizable-products/acrylic-coasters',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 81,
  ),
  _ProductSeed(
    id: 'pg_personalized_mousepads',
    name: 'Personalized Mousepads',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 267,
    minConfig: '1 piece',
    sizeDetails: '9.25x7.5 in; 3mm thick',
    material: 'Rubber base, fabric surface, sublimation print; rounded corners',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Custom mousepad with photo/logo sublimation print, smooth fabric surface, anti-skid rubber base.',
    sourceUrl:
        'https://printo.in/categories/mousepads/customizable-products/custom-mousepads',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 82,
  ),
  _ProductSeed(
    id: 'pg_personalised_photo_playing_cards',
    name: 'Personalised Photo Playing Cards',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 253,
    minConfig: '1 set (52+3 cards)',
    sizeDetails: '2.5x3.5 in per card',
    material: '300gsm thick card; Matte or Glossy finish; rounded corners',
    quantity: '1 set = 52 + 3 joker cards',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Fully personalised playing card deck with customer photos on card backs. Standard 52+3 joker set.',
    sourceUrl:
        'https://printo.in/categories/playing-cards/customizable-products/personalized-playing-cards',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 83,
  ),
  _ProductSeed(
    id: 'pg_personalised_ludo',
    name: 'Personalised Ludo',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 310,
    minConfig: '1 set',
    sizeDetails: '12x12 in board',
    material:
        '3mm thick cardboard, digital printing; includes 1 die + 16 coloured coins (4 colours)',
    quantity: 'MOQ 1 set',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Classic Ludo board game personalised with customer photos on the playing board.',
    sourceUrl:
        'https://printo.in/categories/kids-and-games/customizable-products/personalized-ludo',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 84,
  ),
  _ProductSeed(
    id: 'pg_personalised_memory_game',
    name: 'Personalised Memory Game',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 310,
    minConfig: '1 game (24 cards)',
    sizeDetails: '3x3 in per card',
    material: '675gsm thick paper board; 24-piece set (12 matching pairs)',
    quantity: '1 game set = 24 cards',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Concentration/flip card memory game personalised with customer photos on card backs.',
    sourceUrl:
        'https://printo.in/categories/kids-and-games/customizable-products/personalized-memory-game',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 85,
  ),
  _ProductSeed(
    id: 'pg_personalized_gift_wrapping_paper',
    name: 'Personalized Gift Wrapping Paper',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: null,
    minConfig: '25 sheets (MOQ 25)',
    sizeDetails: '5 sizes available',
    material:
        '4 paper types (including Kraft medium); single-colour or full-colour print',
    quantity: 'MOQ 25 sheets',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Custom gift wrapping paper sheets with photos/logo/text in 5 sizes and 4 paper types. Starting price not visible on product page.',
    sourceUrl:
        'https://printo.in/categories/gift-wrapping-paper/customizable-products/custom-gift-wrapping-paper',
    priceSource: 'Not Available',
    confidenceScore: 'Low',
    sortOrder: 86,
  ),
  _ProductSeed(
    id: 'pg_desktop_frames_with_messages_3d_printed',
    name: 'Desktop Frames with Messages (3D Printed)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: null,
    minConfig: '1 piece',
    sizeDetails: '8cm W x 14cm H x 2cm D',
    material: 'Sturdy 3D-printed frame; 4 colours (Red, Blue, Yellow, Black)',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        '3D-printed desktop photo frame personalised with a text message (up to 12 chars/line, 2 lines, English only). Starting price not visible on photo gifts category page.',
    sourceUrl:
        'https://printo.in/categories/3d-printed-products/customizable-products/timeless-frame',
    priceSource: 'Not Available',
    confidenceScore: 'Low',
    sortOrder: 87,
  ),
  _ProductSeed(
    id: 'pg_personalised_t_shirt_round_neck',
    name: 'Personalised T-Shirt (Round Neck)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 499,
    minConfig: '1 piece',
    sizeDetails: 'S, M, L, XL, XXL',
    material:
        '180gsm, 100% cotton, bio-washed; digital print (DTG) or screen print; 7 colour options',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Custom round-neck t-shirt printable with photos/logos/artwork. White, Black, Grey Melange, Navy Blue, Royal Blue, Red, Yellow available.',
    sourceUrl:
        'https://printo.in/categories/t-shirts/customizable-products/round-neck-t-shirts',
    priceSource: 'Category Page',
    confidenceScore: 'High',
    sortOrder: 88,
  ),
  _ProductSeed(
    id: 'pg_personalized_laptop_sleeve_13_in',
    name: 'Personalized Laptop Sleeve (13 in)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 1072,
    minConfig: '1 piece',
    sizeDetails: '13x9.5 in',
    material: 'Custom-printed sleeve material',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Personalised 13-inch laptop sleeve with custom photo/design/logo printing.',
    sourceUrl:
        'https://printo.in/categories/laptop-sleeves/customizable-products/13x9.5-in-laptop-sleeve',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 89,
  ),
  _ProductSeed(
    id: 'pg_personalized_laptop_sleeve_13_5_in',
    name: 'Personalized Laptop Sleeve (13.5 in)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 1208,
    minConfig: '1 piece',
    sizeDetails: '13.5x10 in',
    material: 'Custom-printed sleeve material',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Personalised 13.5-inch laptop sleeve with custom photo/design/logo printing.',
    sourceUrl:
        'https://printo.in/categories/laptop-sleeves/customizable-products/13.5x10-in-laptop-sleeve',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 90,
  ),
  _ProductSeed(
    id: 'pg_personalized_laptop_sleeve_15_6_in',
    name: 'Personalized Laptop Sleeve (15.6 in)',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 1300,
    minConfig: '1 piece',
    sizeDetails: '15.6x11 in',
    material: 'Custom-printed sleeve material',
    quantity: 'Order from 1 unit',
    deliveryInfo:
        'Same-day delivery (4-6 hrs) in Bengaluru, Hyderabad, NCR & Chennai if ordered before 4:30 PM; standard nationwide',
    description:
        'Personalised 15.6-inch laptop sleeve with custom photo/design/logo printing.',
    sourceUrl:
        'https://printo.in/categories/laptop-sleeves/customizable-products/15.6x11-in-laptop-sleeve',
    priceSource: 'Category Page',
    confidenceScore: 'Medium',
    sortOrder: 91,
  ),
  _ProductSeed(
    id: 'pg_personalized_selfie_photo_booth',
    name: 'Personalized Selfie Photo Booth',
    categoryId: 'personalized_gifts',
    categoryName: 'Personalized Gifts',
    startingPrice: 763,
    minConfig: '1 piece',
    sizeDetails: 'Large event-prop format (exact dimensions not listed)',
    material: '5mm white sun board',
    quantity: 'Not specified',
    deliveryInfo: 'Not specified on page',
    description:
        'Large free-standing event photo-booth prop personalised with event branding/designs. Borderline product - primarily an event prop.',
    sourceUrl:
        'https://printo.in/categories/selfie-frames/customizable-products/selfie-photo-booth',
    priceSource: 'Category Page',
    confidenceScore: 'Low',
    sortOrder: 92,
  ),
];

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  final db = FirebaseFirestore.instance;
  var categoriesWritten = 0;
  var productsWritten = 0;

  print('Seeding ${_categories.length} categories...');
  final categoryBatch = db.batch();
  for (final category in _categories) {
    categoryBatch.set(
      db.collection('categories').doc(category.id),
      category.toMap(),
      SetOptions(merge: true),
    );
  }
  await categoryBatch.commit();
  for (final category in _categories) {
    categoriesWritten += 1;
    print('Seeded category ${category.name}');
  }

  print('Seeding ${_products.length} products...');
  const batchLimit = 500;
  for (var start = 0; start < _products.length; start += batchLimit) {
    final batch = db.batch();
    final end = (start + batchLimit > _products.length)
        ? _products.length
        : start + batchLimit;
    final chunk = _products.sublist(start, end);

    for (final product in chunk) {
      batch.set(
        db.collection('products').doc(product.id),
        product.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    for (final product in chunk) {
      productsWritten += 1;
      print(
        'Seeded product $productsWritten of ${_products.length}: ${product.name}',
      );
    }
  }

  print(
    'Seed complete: $categoriesWritten categories written, '
    '$productsWritten products written.',
  );
}
