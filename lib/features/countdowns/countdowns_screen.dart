import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_screen.dart';
import 'create_countdown_screen.dart';
import 'countdown_detail_screen.dart';
import 'enter_id_screen.dart';
import 'widgets/countdown_tile.dart';

class CountdownsScreen extends ConsumerWidget {
  const CountdownsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return const _NotConfiguredScreen();
    }
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AuthScreen();
    }
    return const _CountdownsList();
  }
}

class _CountdownsList extends ConsumerStatefulWidget {
  const _CountdownsList();

  @override
  ConsumerState<_CountdownsList> createState() => _CountdownsListState();
}

class _CountdownsListState extends ConsumerState<_CountdownsList> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final countdownsAsync = ref.watch(myCountdownsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdowns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Find by ID',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EnterIdScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => SupabaseService.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.surface,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateCountdownScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myCountdownsProvider),
          child: countdownsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text('Could not load countdowns', style: TextStyle(color: color)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Text(
                        'No countdowns yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: color.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                );
              }

              final categories = items
                  .map((e) => e.countdown.category)
                  .whereType<String>()
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              final filtered = _categoryFilter == null
                  ? items
                  : items.where((e) => e.countdown.category == _categoryFilter).toList();

              return Column(
                children: [
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'All',
                              selected: _categoryFilter == null,
                              color: color,
                              onTap: () => setState(() => _categoryFilter = null),
                            ),
                            const SizedBox(width: 8),
                            for (final c in categories) ...[
                              _CategoryChip(
                                label: c,
                                selected: _categoryFilter == c,
                                color: color,
                                onTap: () => setState(() => _categoryFilter = c),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(color: color.withValues(alpha: 0.08)),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final userId = ref.watch(countdownRepositoryProvider).currentUserId;
                        final isOwner = userId != null && userId == item.countdown.ownerId;
                        return Dismissible(
                          key: ValueKey(item.countdown.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: Icon(Icons.delete_outline, color: color.withValues(alpha: 0.6)),
                          ),
                          confirmDismiss: (_) => showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isOwner ? 'Delete countdown?' : 'Remove countdown?'),
                              content: Text(
                                isOwner
                                    ? '"${item.countdown.title}" will be permanently deleted for everyone following it.'
                                    : '"${item.countdown.title}" will be removed from your list.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ).then((confirmed) => confirmed ?? false),
                          onDismissed: (_) async {
                            final repo = ref.read(countdownRepositoryProvider);
                            await NotificationService.instance
                                .cancelCountdownNotification(item.countdown.id);
                            if (isOwner) {
                              await repo.deleteCountdown(item.countdown.id);
                            } else {
                              await repo.unfollow(item.countdown.id);
                            }
                            ref.invalidate(myCountdownsProvider);
                          },
                          child: CountdownTile(
                            countdown: item.countdown,
                            notify: item.follow.notify,
                            pinned: item.follow.pinned,
                            onTogglePin: () async {
                              final repo = ref.read(countdownRepositoryProvider);
                              await repo.setPinned(
                                countdownId: item.countdown.id,
                                pinned: !item.follow.pinned,
                              );
                              ref.invalidate(myCountdownsProvider);
                            },
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CountdownDetailScreen(
                                  countdownId: item.countdown.id,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color.withValues(alpha: selected ? 0 : 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Theme.of(context).colorScheme.surface : color.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _NotConfiguredScreen extends StatelessWidget {
  const _NotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Countdowns need a Supabase project to be connected.\n\nAdd your project URL and anon key in lib/core/services/supabase_service.dart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}
