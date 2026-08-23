import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/notification_service.dart';
import 'create_countdown_screen.dart';
import 'widgets/countdown_tile.dart';

const String kCountdownShareBaseUrl = 'https://time.ivaan.cc/?c=';

class CountdownDetailScreen extends ConsumerStatefulWidget {
  final String countdownId;
  const CountdownDetailScreen({super.key, required this.countdownId});

  @override
  ConsumerState<CountdownDetailScreen> createState() =>
      _CountdownDetailScreenState();
}

class _CountdownDetailScreenState
    extends ConsumerState<CountdownDetailScreen> {
  late Timer _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _toggleNotify(bool isOwner) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(countdownRepositoryProvider);
      final follow = await ref.read(
          followByCountdownIdProvider(widget.countdownId).future);
      final newValue = !(follow?.notify ?? false);
      await repo.setFollow(countdownId: widget.countdownId, notify: newValue);

      final countdown =
          await ref.read(countdownByIdProvider(widget.countdownId).future);
      if (newValue) {
        await NotificationService.instance.scheduleCountdownNotification(
          countdownId: widget.countdownId,
          title: countdown.title,
          targetDate: countdown.targetDate,
        );
      } else {
        await NotificationService.instance
            .cancelCountdownNotification(widget.countdownId);
      }
      ref.invalidate(followByCountdownIdProvider(widget.countdownId));
      ref.invalidate(myCountdownsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _shareText(String title) {
    final url = '$kCountdownShareBaseUrl${widget.countdownId}';
    return '$title countdown — count down with me: $url';
  }

  Future<void> _share(String title) async {
    final color = Theme.of(context).colorScheme.onSurface;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share countdown'),
        content: Text(
          'Share "$title" with others.',
          style: TextStyle(color: color.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'copy'),
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'apps'),
            child: const Text('Share via Apps'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: _shareText(title)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    } else {
      await Share.share(_shareText(title));
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.countdownId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Countdown ID copied')),
    );
  }

  Future<void> _togglePin(bool pinned) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(countdownRepositoryProvider);
      await repo.setPinned(countdownId: widget.countdownId, pinned: !pinned);
      ref.invalidate(followByCountdownIdProvider(widget.countdownId));
      ref.invalidate(myCountdownsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String title, bool isOwner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOwner ? 'Delete countdown?' : 'Remove countdown?'),
        content: Text(
          isOwner
              ? '"$title" will be permanently deleted for everyone following it.'
              : '"$title" will be removed from your list.',
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
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(countdownRepositoryProvider);
      await NotificationService.instance
          .cancelCountdownNotification(widget.countdownId);
      if (isOwner) {
        await repo.deleteCountdown(widget.countdownId);
      } else {
        await repo.unfollow(widget.countdownId);
      }
      ref.invalidate(myCountdownsProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final countdownAsync =
        ref.watch(countdownByIdProvider(widget.countdownId));
    final followAsync =
        ref.watch(followByCountdownIdProvider(widget.countdownId));
    final userId = ref.watch(countdownRepositoryProvider).currentUserId;

    final isOwnerForActions = countdownAsync.valueOrNull != null &&
        userId != null &&
        userId == countdownAsync.value!.ownerId;
    final pinnedForActions = followAsync.valueOrNull?.pinned ?? false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(pinnedForActions ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: pinnedForActions ? 'Unpin' : 'Pin to top',
            onPressed: _busy || countdownAsync.valueOrNull == null
                ? null
                : () => _togglePin(pinnedForActions),
          ),
          if (isOwnerForActions)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateCountdownScreen(existing: countdownAsync.value),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: countdownAsync.valueOrNull == null
                ? null
                : () => _share(countdownAsync.value!.title),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy || countdownAsync.valueOrNull == null
                ? null
                : () => _delete(
                      countdownAsync.value!.title,
                      userId != null && userId == countdownAsync.value!.ownerId,
                    ),
          ),
        ],
      ),
      body: SafeArea(
        child: countdownAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text('Countdown not found', style: TextStyle(color: color)),
          ),
          data: (countdown) {
            final remaining = countdown.targetDate.difference(DateTime.now());
            final isOwner = userId != null && userId == countdown.ownerId;
            final notify = followAsync.valueOrNull?.notify ?? false;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(builder: (context) {
                    final fontSize = ref.watch(settingsProvider).valueOrNull?.clockFontSize ?? 72;
                    return Column(
                      children: [
                        Text(
                          countdown.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: (fontSize * 0.3).clamp(18.0, 32.0),
                            fontWeight: FontWeight.w400,
                            color: color.withValues(alpha: 0.7),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          formatRemaining(remaining),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -2,
                            color: color,
                            height: 1,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    '${countdown.targetDate.month}/${countdown.targetDate.day}/${countdown.targetDate.year}',
                    style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.4)),
                  ),
                  if (countdown.category != null && countdown.category!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        countdown.category!,
                        style: TextStyle(fontSize: 11, letterSpacing: 0.5, color: color.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _busy ? null : () => _toggleNotify(isOwner),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: notify ? color : Colors.transparent,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notify
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            size: 18,
                            color: notify
                                ? Theme.of(context).colorScheme.surface
                                : color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notify ? 'Notifying' : 'Notify me',
                            style: TextStyle(
                              color: notify
                                  ? Theme.of(context).colorScheme.surface
                                  : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _copyId,
                    child: Text(
                      'ID: ${countdown.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.3),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
