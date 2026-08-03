import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart' show AdminDrawer;

// ── Providers ──────────────────────────────────────────────────────────────

final _productsProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/products');
  return response.data as List<dynamic>;
});

final _categoriesProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/categories');
  return (response.data as List<dynamic>)
      .map((item) => (item as Map<String, dynamic>)['name'] as String)
      .toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AdminTheme.primary,
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AdminTheme.primary),
        ),
        error: (e, s) => Center(child: Text('$e')),
        data: (products) => products.isEmpty
            ? const Center(
                child: Text(
                  'No products yet. Tap + to add one.',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn2(label: Text('Image'), size: ColumnSize.S),
                    DataColumn2(label: Text('Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('Category'), size: ColumnSize.M),
                    DataColumn2(label: Text('Price'), size: ColumnSize.S),
                    DataColumn2(label: Text('Sizes'), size: ColumnSize.S),
                    DataColumn2(label: Text('Active'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                  ],
                  rows: products.map<DataRow>((p) {
                    final images = p['images'] as List<dynamic>? ?? [];
                    final imageUrl = images.isNotEmpty
                        ? images.first as String
                        : '';
                    final sizes = p['sizes'] as List<dynamic>? ?? [];
                    return DataRow(
                      cells: [
                        DataCell(
                          imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: AdminTheme.textSecondary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: AdminTheme.textSecondary,
                                ),
                        ),
                        DataCell(Text(p['name'] as String? ?? '')),
                        DataCell(Text(p['category'] as String? ?? '')),
                        DataCell(
                          Text(
                            '₹${(p['base_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${sizes.length} size${sizes.length == 1 ? '' : 's'}',
                          ),
                        ),
                        DataCell(
                          Icon(
                            (p['is_active'] as bool? ?? false)
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: (p['is_active'] as bool? ?? false)
                                ? AdminTheme.primary
                                : AdminTheme.error,
                            size: 20,
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _showProductForm(context, ref, product: p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AdminTheme.error,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _deleteProduct(
                                  context,
                                  ref,
                                  p['id'] as String,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'This product will be permanently deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminApiClientProvider).dio.delete('/admin/products/$id');
      ref.invalidate(_productsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      }
    }
  }

  void _showProductForm(
    BuildContext context,
    WidgetRef ref, {
    dynamic product,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductFormDialog(product: product, ref: ref),
    );
  }
}

// ── Form Dialog ────────────────────────────────────────────────────────────

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product, required this.ref});
  final dynamic product;
  final WidgetRef ref;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _newCategoryCtrl;
  late final TextEditingController _stockCtrl;

  late String _selectedCategory;
  late bool _isActive;
  late bool _tracksInventory;
  late List<Map<String, dynamic>> _sizes;

  String _imageUrl = '';
  Uint8List? _pickedImageBytes;
  bool _uploadingImage = false;
  bool _isSaving = false;

  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _priceCtrl = TextEditingController(
      text: p?['base_price']?.toString() ?? '',
    );
    _descCtrl = TextEditingController(text: p?['description'] ?? '');
    _newCategoryCtrl = TextEditingController();
    _stockCtrl = TextEditingController(
      text: (p?['stock_quantity'] ?? 0).toString(),
    );
    _selectedCategory = p?['category'] ?? '';
    _isActive = p?['is_active'] ?? true;
    _tracksInventory = p?['tracks_inventory'] ?? false;
    final images = p?['images'] as List<dynamic>? ?? [];
    _imageUrl = images.isNotEmpty ? images.first as String : '';
    _sizes = (p?['sizes'] as List<dynamic>? ?? [])
        .map(
          (s) => {
            'label': (s as Map)['label']?.toString() ?? '',
            'price': (s['price'] as num?)?.toDouble() ?? 0.0,
            'labelCtrl': TextEditingController(
              text: s['label']?.toString() ?? '',
            ),
            'priceCtrl': TextEditingController(
              text: (s['price'] as num?)?.toString() ?? '',
            ),
          },
        )
        .toList();

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.ref.read(_categoriesProvider.future);
      if (mounted) {
        setState(() {
          _availableCategories = cats;
          if (_selectedCategory.isNotEmpty &&
              !_availableCategories.contains(_selectedCategory)) {
            _availableCategories = [_selectedCategory, ..._availableCategories];
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _newCategoryCtrl.dispose();
    _stockCtrl.dispose();
    for (final s in _sizes) {
      (s['labelCtrl'] as TextEditingController).dispose();
      (s['priceCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _pickedImageBytes = file.bytes;
      _uploadingImage = true;
    });

    try {
      final client = widget.ref.read(adminApiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: DioMediaType.parse(_mimeFromName(file.name)),
        ),
      });
      final response = await client.dio.post('/admin/upload', data: formData);
      final url = (response.data as Map)['url'] as String;
      setState(() {
        _imageUrl = url;
        _uploadingImage = false;
      });
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  void _addSize() {
    setState(() {
      _sizes.add({
        'label': '',
        'price': 0.0,
        'labelCtrl': TextEditingController(),
        'priceCtrl': TextEditingController(),
      });
    });
  }

  void _removeSize(int index) {
    final s = _sizes[index];
    (s['labelCtrl'] as TextEditingController).dispose();
    (s['priceCtrl'] as TextEditingController).dispose();
    setState(() => _sizes.removeAt(index));
  }

  void _addNewCategory() {
    final cat = _newCategoryCtrl.text.trim();
    if (cat.isEmpty) return;
    setState(() {
      if (!_availableCategories.contains(cat)) {
        _availableCategories = [cat, ..._availableCategories];
      }
      _selectedCategory = cat;
      _newCategoryCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product name is required')));
      return;
    }
    if (_selectedCategory.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category is required')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid base price')));
      return;
    }

    setState(() => _isSaving = true);

    final sizesPayload = _sizes
        .where(
          (s) =>
              (s['labelCtrl'] as TextEditingController).text.trim().isNotEmpty,
        )
        .map(
          (s) => {
            'label': (s['labelCtrl'] as TextEditingController).text.trim(),
            'price':
                double.tryParse(
                  (s['priceCtrl'] as TextEditingController).text.trim(),
                ) ??
                0.0,
          },
        )
        .toList();
    if (price <= 0 && sizesPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive base or size price')),
      );
      return;
    }
    if (sizesPayload.any((size) => (size['price'] as double) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every size needs a positive price')),
      );
      return;
    }
    final stock = int.tryParse(_stockCtrl.text.trim());
    if (_tracksInventory && (stock == null || stock < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid stock quantity')),
      );
      return;
    }

    final data = {
      'name': _nameCtrl.text.trim(),
      'category': _selectedCategory.trim(),
      'base_price': price,
      'images': _imageUrl.isEmpty ? <String>[] : [_imageUrl],
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'sizes': sizesPayload,
      'stock_quantity': stock ?? 0,
      'tracks_inventory': _tracksInventory,
      'is_active': _isActive,
    };

    try {
      final client = widget.ref.read(adminApiClientProvider);
      if (widget.product == null) {
        await client.dio.post('/admin/products', data: data);
      } else {
        await client.dio.put(
          '/admin/products/${widget.product!['id']}',
          data: data,
        );
      }
      widget.ref.invalidate(_productsProvider);
      widget.ref.invalidate(_categoriesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Product' : 'Add Product'),
            backgroundColor: AdminTheme.primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ──────────────────────────────────────────────
                const Text(
                  'Product Image',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _uploadingImage
                          ? Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AdminTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _pickedImageBytes != null
                          ? Image.memory(
                              _pickedImageBytes!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            )
                          : _imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _imageUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _uploadingImage
                              ? null
                              : _pickAndUploadImage,
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(
                            _imageUrl.isNotEmpty
                                ? 'Change Image'
                                : 'Upload Image',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primary,
                          ),
                        ),
                        if (_imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _imageUrl = '';
                              _pickedImageBytes = null;
                            }),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: AdminTheme.error,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(
                                color: AdminTheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Text(
                          'JPEG / PNG / WebP, max 5 MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Name ───────────────────────────────────────────────
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category ───────────────────────────────────────────
                const Text(
                  'Category *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (_availableCategories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._availableCategories.map(
                        (cat) => ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: AdminTheme.primary,
                          labelStyle: TextStyle(
                            color: _selectedCategory == cat
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Add new category inline
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type new category name…',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addNewCategory(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _addNewCategory,
                      child: const Text('Add'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Base Price ─────────────────────────────────────────
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Base Price (₹) *',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Description ────────────────────────────────────────
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Sizes ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Size Variants',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addSize,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Size'),
                    ),
                  ],
                ),
                if (_sizes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'No size variants — customers will order at base price.',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ..._sizes.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: s['labelCtrl'] as TextEditingController,
                            decoration: InputDecoration(
                              labelText: 'Size label (e.g. 4×6)',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: s['priceCtrl'] as TextEditingController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Price (₹)',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AdminTheme.error,
                            size: 20,
                          ),
                          onPressed: () => _removeSize(i),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                SwitchListTile(
                  value: _tracksInventory,
                  onChanged: (value) =>
                      setState(() => _tracksInventory = value),
                  title: const Text('Track inventory'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_tracksInventory) ...[
                  TextField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Units in stock',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── is_active ──────────────────────────────────────────
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active (visible to customers)'),
                  activeThumbColor: AdminTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving || _uploadingImage ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        size: 32,
        color: AdminTheme.textSecondary,
      ),
    );
  }
}
