import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/product_images.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../../domain/entities/cart_item_entity.dart';

const _kSourcePrefKey = 'snap_photo_source';

class _PhotoSource {
  final String key;
  final String label;
  final IconData icon;
  const _PhotoSource(this.key, this.label, this.icon);
}

final _androidSources = [
  const _PhotoSource('gallery', 'Gallery', Icons.photo_library_outlined),
  const _PhotoSource('folder', 'Files', Icons.folder_open_outlined),
  const _PhotoSource('google_photos', 'Google Photos', Icons.add_photo_alternate_outlined),
];

final _iosSources = [
  const _PhotoSource('photo_library', 'Photo Library', Icons.photo_library_outlined),
  const _PhotoSource('files', 'Files', Icons.folder_open_outlined),
  const _PhotoSource('icloud', 'iCloud Drive', Icons.cloud_outlined),
];

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({
    super.key,
    required this.productId,
    required this.productName,
    this.preselectedSize,
  });
  final String productId;
  final String productName;
  final String? preselectedSize;

  @override
  ConsumerState<CustomizationScreen> createState() =>
      _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen> {
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedUrls = [];
  late String? _selectedSize;
  int _quantity = 1;
  bool _isUploading = false;
  bool _isAdding = false;
  String? _lastSource;

  List<_PhotoSource> get _sources =>
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? _iosSources : _androidSources;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.preselectedSize;
    _loadLastSource();
  }

  Future<void> _loadLastSource() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _lastSource = prefs.getString(_kSourcePrefKey));
  }

  Future<void> _saveSource(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourcePrefKey, key);
    if (mounted) setState(() => _lastSource = key);
  }

  // ── Auth guard ─────────────────────────────────────────────────────────────

  /// Returns true if authenticated (Firebase session or dev bypass); shows login prompt otherwise.
  bool _requireAuth() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return true;
    // Also accept dev-mode auth (dev token set in ApiClient)
    final authUser = ref.read(authProvider).valueOrNull;
    if (authUser != null && authUser.id != 'guest') return true;
    _showLoginRequiredDialog();
    return false;
  }

  void _showLoginRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Login required'),
        content: const Text(
          'You need to sign in to upload photos and place orders.\n\nIt only takes 30 seconds with your phone number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.login);
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickViaImagePicker({required bool multi}) async {
    final picker = ImagePicker();
    if (multi) {
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) await _processFiles(picked, multi: multi);
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) await _processFiles([picked], multi: false);
    }
  }

  Future<void> _pickViaFilePicker({required bool multi}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: multi,
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      final files = result.files.map((f) => XFile(f.path ?? f.name, bytes: f.bytes)).toList();
      await _processFiles(files, multi: multi);
    }
  }

  Future<void> _pickFromSource(String key, {required bool multi}) async {
    await _saveSource(key);
    switch (key) {
      case 'gallery':
      case 'photo_library':
      case 'google_photos':
        await _pickViaImagePicker(multi: multi);
        break;
      case 'folder':
      case 'files':
      case 'icloud':
        await _pickViaFilePicker(multi: multi);
        break;
    }
  }

  Future<void> _processFiles(List<XFile> files, {required bool multi}) async {
    if (!multi) {
      // Single-photo products: replace existing selection
      _selectedImages.clear();
      _uploadedUrls.clear();
    }
    setState(() => _selectedImages.addAll(files));
    await _uploadImages(files);
  }

  Future<void> _uploadImages(List<XFile> files) async {
    setState(() => _isUploading = true);
    try {
      final client = ref.read(apiClientProvider);
      for (final file in files) {
        final filename = file.name.isNotEmpty ? file.name : 'photo.jpg';
        final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpg';
        final contentType = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';

        // Step 1 — ask backend for a presigned upload URL
        final presign = await client.get<Map<String, dynamic>>(
          '/upload/presign',
          queryParameters: {'filename': filename, 'content_type': contentType},
        );
        final uploadUrl = presign.data?['upload_url'] as String?;
        final publicUrl = presign.data?['public_url'] as String?;
        if (uploadUrl == null || publicUrl == null) throw Exception('Invalid presign response');

        // Step 2 — PUT file bytes directly to R2 (no server in the middle)
        final bytes = await file.readAsBytes();
        await Dio().put<void>(
          uploadUrl,
          data: bytes,
          options: Options(
            contentType: contentType,
            headers: {'Content-Length': bytes.length},
            sendTimeout: const Duration(minutes: 2),
            receiveTimeout: const Duration(minutes: 2),
            validateStatus: (status) => status != null && status < 400,
          ),
        );

        if (mounted) setState(() => _uploadedUrls.add(publicUrl));
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int i) {
    setState(() {
      _selectedImages.removeAt(i);
      if (i < _uploadedUrls.length) _uploadedUrls.removeAt(i);
    });
  }

  // ── Photo tap handler ──────────────────────────────────────────────────────

  void _onTapUpload({required bool isPhotoCategory}) {
    if (!_requireAuth()) return;
    if (_lastSource == null) {
      _showSourceSheet(isPhotoCategory: isPhotoCategory);
    } else {
      _pickFromSource(_lastSource!, multi: isPhotoCategory);
    }
  }

  void _showSourceSheet({required bool isPhotoCategory}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select photo from',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const Divider(height: 1),
            ..._sources.map((s) => ListTile(
                  leading: Icon(s.icon, color: AppColors.primary),
                  title: Text(s.label),
                  trailing: _lastSource == s.key
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromSource(s.key, multi: isPhotoCategory);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Add to cart ────────────────────────────────────────────────────────────

  void _addToCart(List<dynamic> sizes) {
    if (!_requireAuth()) return;
    if (_isUploading) {
      showErrorSnackbar(context, 'Please wait for upload to complete');
      return;
    }
    if (_uploadedUrls.isEmpty) {
      showErrorSnackbar(context, 'Please upload a photo first');
      return;
    }
    if (_selectedSize == null && sizes.isNotEmpty) {
      showErrorSnackbar(context, 'Please select a size');
      return;
    }
    setState(() => _isAdding = true);

    final selectedSizeObj = sizes.cast<dynamic>().firstWhere(
          (s) => s.label == _selectedSize,
          orElse: () => sizes.isNotEmpty ? sizes.first : null,
        );
    final price = (selectedSizeObj?.price as num?)?.toDouble() ?? 0.0;

    final catalogImageUrl = resolveCartProductImage(widget.productId);

    for (var i = 0; i < _uploadedUrls.length; i++) {
      final url = _uploadedUrls[i];
      ref.read(cartProvider.notifier).addItem(CartItemEntity(
            cartItemId:
                '${widget.productId}_${DateTime.now().microsecondsSinceEpoch}_$i',
            productId: widget.productId,
            productName: widget.productName,
            productImageUrl: catalogImageUrl,
            selectedSize: _selectedSize ?? 'Default',
            quantity: _quantity,
            unitPrice: price,
            customizationImageUrl: url,
          ));
    }

    setState(() => _isAdding = false);
    if (mounted) {
      final count = _uploadedUrls.length;
      showSuccessSnackbar(context,
          count == 1 ? 'Added to cart!' : '$count photos added to cart!');
      context.go(AppRoutes.cart);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.productName)),
      body: productAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (product) {
          final isPhotoCategory = product.category == 'photo_prints';
          final hasImages = _selectedImages.isNotEmpty;
          final allUploaded = !_isUploading && _uploadedUrls.length >= _selectedImages.length;
          final hasSize = _selectedSize != null || product.sizes.isEmpty;

          return Column(
            children: [
              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STEP 1 — Photo(s)
                      _StepHeader(
                        step: '1',
                        label: isPhotoCategory ? 'Select Photos' : 'Upload Photo',
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoSection(isPhotoCategory),

                      // STEP 2 — Size (only when photos uploaded & product has sizes)
                      if (hasImages && allUploaded && product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _StepHeader(step: '2', label: AppStrings.selectSize),
                        const SizedBox(height: 12),
                        _buildSizeGrid(product.sizes),
                      ],

                      // STEP 3 — Quantity (after size chosen or if no sizes)
                      if (hasImages && allUploaded && hasSize) ...[
                        const SizedBox(height: 28),
                        _StepHeader(
                          step: product.sizes.isNotEmpty ? '3' : '2',
                          label: isPhotoCategory && _selectedImages.length > 1
                              ? '${AppStrings.quantity} per photo'
                              : AppStrings.quantity,
                        ),
                        const SizedBox(height: 12),
                        _buildQuantityRow(isPhotoCategory),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Change source bar (shows when photos selected) ───────────
              if (hasImages)
                _ChangeSourceBar(
                  sources: _sources,
                  activeKey: _lastSource,
                  onTap: (key) {
                    if (!_requireAuth()) return;
                    _pickFromSource(key, multi: isPhotoCategory);
                  },
                ),

              // ── Add to Cart ──────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: CustomButton(
                    label: _cartLabel(isPhotoCategory),
                    icon: Icons.shopping_cart_outlined,
                    isLoading: _isAdding || _isUploading,
                    onPressed: () => _addToCart(product.sizes),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Photo section ──────────────────────────────────────────────────────────

  Widget _buildPhotoSection(bool isPhotoCategory) {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: () => _onTapUpload(isPhotoCategory: isPhotoCategory),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: _isUploading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate,
                        size: 52, color: AppColors.primary),
                    const SizedBox(height: 10),
                    Text(
                      isPhotoCategory
                          ? 'Tap to select photos'
                          : 'Tap to upload photo',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastSource != null
                          ? 'Opens ${_sources.firstWhere((s) => s.key == _lastSource, orElse: () => _sources.first).label}'
                          : 'Gallery · Files · ${(!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? "iCloud" : "Google Photos"}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
        ),
      );
    }

    // Thumbnail row with "Add More" tile for photo category
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (isPhotoCategory ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (isPhotoCategory && i == _selectedImages.length) {
                return GestureDetector(
                  onTap: () => _onTapUpload(isPhotoCategory: true),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            color: AppColors.primary, size: 26),
                        SizedBox(height: 4),
                        Text('Add More',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                );
              }

              final uploading =
                  _isUploading && i >= _uploadedUrls.length;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _XFileThumbnail(
                      file: _selectedImages[i],
                      width: 100,
                      height: 120,
                    ),
                  ),
                  if (uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(i),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_selectedImages.length} photo${_selectedImages.length != 1 ? 's' : ''} selected'
          '${_isUploading ? '  •  Uploading…' : ''}',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // ── Size grid ──────────────────────────────────────────────────────────────

  Widget _buildSizeGrid(List<dynamic> sizes) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        final selected = _selectedSize == size.label;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  size.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${((size.price as num).toDouble()).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: selected ? Colors.white70 : AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Quantity row ───────────────────────────────────────────────────────────

  Widget _buildQuantityRow(bool isPhotoCategory) {
    return Row(
      children: [
        _QtyButton(
          icon: Icons.remove,
          onTap: () {
            if (_quantity > 1) setState(() => _quantity--);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('$_quantity',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        _QtyButton(
          icon: Icons.add,
          onTap: () {
            if (_quantity < 50) setState(() => _quantity++);
          },
        ),
        if (isPhotoCategory && _selectedImages.length > 1) ...[
          const SizedBox(width: 16),
          Text(
            '= ${_quantity * _selectedImages.length} prints total',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }

  String _cartLabel(bool isPhotoCategory) {
    if (_isUploading) return 'Uploading…';
    if (isPhotoCategory && _selectedImages.length > 1) {
      return 'Add ${_selectedImages.length} Photos to Cart';
    }
    return AppStrings.addToCart;
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.label});
  final String step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ChangeSourceBar extends StatelessWidget {
  const _ChangeSourceBar({
    required this.sources,
    required this.activeKey,
    required this.onTap,
  });
  final List<_PhotoSource> sources;
  final String? activeKey;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = sources.where((s) => s.key != activeKey).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text('Change:',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          ...inactive.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  icon: Icon(s.icon, size: 14),
                  label: Text(s.label),
                  onPressed: () => onTap(s.key),
                ),
              )),
        ],
      ),
    );
  }
}

class _XFileThumbnail extends StatefulWidget {
  const _XFileThumbnail({required this.file, required this.width, required this.height});
  final XFile file;
  final double width;
  final double height;

  @override
  State<_XFileThumbnail> createState() => _XFileThumbnailState();
}

class _XFileThumbnailState extends State<_XFileThumbnail> {
  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.accentLight,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return Image.memory(snap.data!, width: widget.width, height: widget.height, fit: BoxFit.cover);
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
