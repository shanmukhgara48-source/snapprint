import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart' show AdminDrawer;

final _usersProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(adminApiClientProvider);
  final response = await client.dio.get('/admin/users');
  return response.data as List<dynamic>;
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      drawer: const AdminDrawer(),
      body: usersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AdminTheme.primary)),
        error: (e, s) => Center(child: Text('$e')),
        data: (users) => Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            columns: const [
              DataColumn2(label: Text('Phone'), size: ColumnSize.M),
              DataColumn2(label: Text('Role'), size: ColumnSize.S),
              DataColumn2(label: Text('Active'), size: ColumnSize.S),
              DataColumn2(label: Text('Joined'), size: ColumnSize.M),
            ],
            rows: users.map<DataRow>((u) {
              final createdAt = u['created_at'] != null
                  ? DateTime.tryParse(u['created_at'] as String)
                  : null;
              return DataRow(cells: [
                DataCell(Text(u['phone'] as String? ?? '—')),
                DataCell(Text(u['role'] as String? ?? '—')),
                DataCell(Icon(
                  (u['is_active'] as bool? ?? false)
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: (u['is_active'] as bool? ?? false)
                      ? AdminTheme.primary
                      : AdminTheme.error,
                  size: 20,
                )),
                DataCell(Text(createdAt != null
                    ? DateFormat('dd MMM yyyy').format(createdAt)
                    : '—')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
