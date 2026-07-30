String _luxuryImage(String id, {int width = 900, int height = 900}) =>
    'https://images.unsplash.com/$id?auto=format&fit=crop&w=$width&h=$height&q=74';

const _photoPrints = 'photo_prints';
const _photoBooks = 'photo_books';
const _framesWallDecor = 'frames_wall_decor';
const _personalizedGifts = 'personalized_gifts';

final Map<String, String> kCategoryBannerImages = {
  _photoPrints: _luxuryImage(
    'photo-1516035069371-29a1b244cc32',
    width: 1200,
    height: 720,
  ),
  _photoBooks: _luxuryImage(
    'photo-1521587760476-6c12a4b040da',
    width: 1200,
    height: 720,
  ),
  _framesWallDecor: _luxuryImage(
    'photo-1594026112284-02bb6f3352fe',
    width: 1200,
    height: 720,
  ),
  _personalizedGifts: _luxuryImage(
    'photo-1544787219-7f47ccb76574',
    width: 1200,
    height: 720,
  ),
};

final Map<String, String> kProductImages = {
  // Legacy product ids retained for compatibility with existing carts/routes.
  'pp_classic': _luxuryImage('photo-1516035069371-29a1b244cc32'),
  'pp_passport': _luxuryImage('photo-1544717305-2782549b5136'),
  'pp_square': _luxuryImage('photo-1526170375885-4d8ecf77b99f'),
  'pp_panoramic': _luxuryImage('photo-1506905925346-21bda4d32df4'),
  'pp_matte': _luxuryImage('photo-1503676260728-1c00da094a0b'),
  'pp_bulk': _luxuryImage('photo-1516035069371-29a1b244cc32'),
  'pb_classic': _luxuryImage('photo-1521587760476-6c12a4b040da'),
  'pb_wedding': _luxuryImage('photo-1519741497674-611481863552'),
  'pb_travel': _luxuryImage('photo-1476514525535-07fb3b4ae5f1'),
  'pb_baby': _luxuryImage('photo-1519689680058-324335c77eba'),
  'pb_graduation': _luxuryImage('photo-1627556704302-624286467c65'),
  'pg_mug': _luxuryImage('photo-1544787219-7f47ccb76574'),
  'pg_cushion': _luxuryImage('photo-1531877025030-f7696a50770f'),
  'pg_calendar': _luxuryImage('photo-1506784365847-bbad939e9335'),
  'pg_phone_case': _luxuryImage('photo-1601784551446-20c9e07cdbdb'),
};

final List<({List<String> terms, String url})> _premiumProductRules = [
  (
    terms: ['passport', 'stamp'],
    url: _luxuryImage('photo-1544717305-2782549b5136'),
  ),
  (
    terms: ['polaroid', 'retro', 'instant'],
    url: _luxuryImage('photo-1526170375885-4d8ecf77b99f'),
  ),
  (
    terms: ['square photo print'],
    url: _luxuryImage('photo-1495567720989-cebdbdd97913'),
  ),
  (
    terms: ['bulk photo'],
    url: _luxuryImage('photo-1516035069371-29a1b244cc32'),
  ),
  (
    terms: ['photo print'],
    url: _luxuryImage('photo-1516035069371-29a1b244cc32'),
  ),
  (
    terms: ['pre wedding', 'anniversary'],
    url: _luxuryImage('photo-1519741497674-611481863552'),
  ),
  (
    terms: ['baby shower', 'baby album'],
    url: _luxuryImage('photo-1519689680058-324335c77eba'),
  ),
  (terms: ['travel'], url: _luxuryImage('photo-1476514525535-07fb3b4ae5f1')),
  (terms: ['birthday'], url: _luxuryImage('photo-1530103862676-de8c9debad1d')),
  (
    terms: ['graduation'],
    url: _luxuryImage('photo-1627556704302-624286467c65'),
  ),
  (
    terms: ['album', 'book'],
    url: _luxuryImage('photo-1521587760476-6c12a4b040da'),
  ),
  (
    terms: ['canvas', 'gallery wrap', 'split'],
    url: _luxuryImage('photo-1558618666-fcd25c85cd64'),
  ),
  (terms: ['acrylic'], url: _luxuryImage('photo-1524758631624-e2822e304c36')),
  (terms: ['led'], url: _luxuryImage('photo-1513506003901-1e6a229e2d15')),
  (
    terms: ['wooden', 'wood', 'mdf', 'plaque', 'stand'],
    url: _luxuryImage('photo-1517705008128-361805f42e86'),
  ),
  (terms: ['decal'], url: _luxuryImage('photo-1511818966892-d7d671e672a2')),
  (terms: ['poster'], url: _luxuryImage('photo-1549277513-f1b32fe1f8f5')),
  (terms: ['frame'], url: _luxuryImage('photo-1594026112284-02bb6f3352fe')),
  (
    terms: [
      'magic mug',
      'beer mug',
      'mini mug',
      'white photo mug',
      'bulk mugs',
    ],
    url: _luxuryImage('photo-1544787219-7f47ccb76574'),
  ),
  (
    terms: ['sipper', 'bottle', 'mason jar', 'cola bottle'],
    url: _luxuryImage('photo-1523362628745-0c100150b504'),
  ),
  (terms: ['magnet'], url: _luxuryImage('photo-1526170375885-4d8ecf77b99f')),
  (terms: ['calendar'], url: _luxuryImage('photo-1506784365847-bbad939e9335')),
  (terms: ['keychain'], url: _luxuryImage('photo-1606760227091-3dd870d97f1d')),
  (
    terms: ['pop socket', 'mobile'],
    url: _luxuryImage('photo-1601784551446-20c9e07cdbdb'),
  ),
  (terms: ['tote bag'], url: _luxuryImage('photo-1590874103328-eac38a683ce7')),
  (terms: ['coaster'], url: _luxuryImage('photo-1605152276897-4f618f831968')),
  (terms: ['mousepad'], url: _luxuryImage('photo-1587202372775-e229f172b9d7')),
  (
    terms: ['playing cards', 'ludo', 'memory game'],
    url: _luxuryImage('photo-1511193311914-0346f16efe90'),
  ),
  (
    terms: ['wrapping paper'],
    url: _luxuryImage('photo-1513201099705-a9746e1e201f'),
  ),
  (
    terms: ['t-shirt', 'shirt'],
    url: _luxuryImage('photo-1521572163474-6864f9cf17ab'),
  ),
  (
    terms: ['laptop sleeve'],
    url: _luxuryImage('photo-1516321318423-f06f85e504b3'),
  ),
  (
    terms: ['photo booth', 'selfie'],
    url: _luxuryImage('photo-1519741497674-611481863552'),
  ),
];

String resolveProductImage(
  String productId,
  String categoryId, {
  String productName = '',
  String? description,
}) {
  final direct = kProductImages[_slug(productId)];
  if (direct != null && direct.isNotEmpty) return direct;

  final searchable = [
    productName,
    productId,
    description ?? '',
  ].join(' ').toLowerCase();

  for (final rule in _premiumProductRules) {
    if (rule.terms.any(searchable.contains)) return rule.url;
  }

  return kCategoryBannerImages[normalizeCategoryId(categoryId)] ?? '';
}

String resolveNetworkProductImage({
  required String productId,
  required String categoryId,
  String productName = '',
  String? description,
  String imageUrl = '',
}) {
  if (imageUrl.trim().isNotEmpty) return imageUrl.trim();
  return resolveProductImage(
    productId,
    categoryId,
    productName: productName,
    description: description,
  );
}

String resolveCartProductImage(String productId, {String productName = ''}) =>
    resolveProductImage(
      productId,
      categoryFromProductId(productId, fallbackName: productName),
      productName: productName,
    );

String categoryFromProductId(String productId, {String fallbackName = ''}) {
  final slug = _slug(productId);
  if (slug.startsWith('pp_')) return _photoPrints;
  if (slug.startsWith('pb_')) return _photoBooks;
  if (slug.startsWith('fw_')) return _framesWallDecor;
  if (slug.startsWith('pg_')) return _personalizedGifts;
  return normalizeCategoryId(fallbackName);
}

String normalizeCategoryId(String category) {
  final slug = _slug(category);
  if (slug.contains('photo_print')) return _photoPrints;
  if (slug.contains('photo_book') || slug.contains('album')) return _photoBooks;
  if (slug.contains('frame') ||
      slug.contains('wall') ||
      slug.contains('canvas') ||
      slug.contains('poster')) {
    return _framesWallDecor;
  }
  if (slug.contains('gift') ||
      slug.contains('mug') ||
      slug.contains('calendar') ||
      slug.contains('keychain')) {
    return _personalizedGifts;
  }
  return slug;
}

String _slug(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');
