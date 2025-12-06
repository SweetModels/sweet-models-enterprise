import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class ModeratorGroup {
  final String id;
  final String name;
  final int membersCount;
  final double tokensToday;

  ModeratorGroup({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.tokensToday,
  });

  double get progress => (tokensToday / 10000).clamp(0, 1);
  double get remaining => (10000 - tokensToday).clamp(0, 10000);
  bool get goalReached => tokensToday >= 10000;

  ModeratorGroup copyWith({double? tokensToday}) {
    return ModeratorGroup(
      id: id,
      name: name,
      membersCount: membersCount,
      tokensToday: tokensToday ?? this.tokensToday,
    );
  }
}

class PendingProduction {
  final String groupId;
  final String groupName;
  final DateTime date;
  final double tokens;

  PendingProduction({
    required this.groupId,
    required this.groupName,
    required this.date,
    required this.tokens,
  });

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'groupName': groupName,
        'date': date.toIso8601String(),
        'tokens': tokens,
      };

  factory PendingProduction.fromJson(Map<String, dynamic> json) {
    return PendingProduction(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      date: DateTime.parse(json['date'] as String),
      tokens: (json['tokens'] as num).toDouble(),
    );
  }
}

class ModeratorConsoleState {
  final bool loading;
  final List<ModeratorGroup> groups;
  final List<PendingProduction> pending;
  final String? error;

  const ModeratorConsoleState({
    this.loading = false,
    this.groups = const [],
    this.pending = const [],
    this.error,
  });

  ModeratorConsoleState copyWith({
    bool? loading,
    List<ModeratorGroup>? groups,
    List<PendingProduction>? pending,
    String? error,
  }) {
    return ModeratorConsoleState(
      loading: loading ?? this.loading,
      groups: groups ?? this.groups,
      pending: pending ?? this.pending,
      error: error,
    );
  }
}

// ============================================================================
// STATE NOTIFIER
// ============================================================================

class ModeratorConsoleNotifier extends StateNotifier<ModeratorConsoleState> {
  ModeratorConsoleNotifier(this._apiService) : super(const ModeratorConsoleState()) {
    _init();
  }

  final ApiService _apiService;
  static const _pendingKey = 'pending_production_reports';

  Future<void> _init() async {
    await _loadPendingFromStorage();
    await fetchGroups();
    await _flushPendingQueue();
  }

  Future<void> _loadPendingFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final pending = decoded
          .cast<Map<String, dynamic>>()
          .map(PendingProduction.fromJson)
          .toList();
      state = state.copyWith(pending: pending);
    } catch (_) {
      // ignore corrupt cache
    }
  }

  Future<void> _persistPending(List<PendingProduction> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_pendingKey, encoded);
  }

  Future<void> fetchGroups() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _apiService.fetchModeratorGroups();
      final groups = data
          .map((g) => ModeratorGroup(
                id: g['id'] as String,
                name: g['name'] as String,
                membersCount: g['members_count'] as int,
                tokensToday: double.tryParse(g['total_tokens'].toString()) ?? 0,
              ))
          .toList();
      state = state.copyWith(groups: groups, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> submitProduction({
    required ModeratorGroup group,
    required DateTime date,
    required double tokens,
  }) async {
    // Optimistic UI: update card immediately
    _updateGroupTokens(group.id, tokens);

    try {
      await _apiService.registerProduction(
        groupId: group.id,
        date: DateFormat('yyyy-MM-dd').format(date),
        tokens: tokens,
      );
      // Refresh from server to align totals
      await fetchGroups();
      await _flushPendingQueue();
    } catch (e) {
      // Offline mode: enqueue and persist
      final updatedQueue = [...state.pending, PendingProduction(
        groupId: group.id,
        groupName: group.name,
        date: date,
        tokens: tokens,
      )];
      state = state.copyWith(pending: updatedQueue);
      await _persistPending(updatedQueue);
      state = state.copyWith(error: 'Guardado offline. Reintentaremos más tarde.');
    }
  }

  Future<void> _flushPendingQueue() async {
    if (state.pending.isEmpty) return;
    final queue = List<PendingProduction>.from(state.pending);
    final successful = <PendingProduction>[];

    for (final item in queue) {
      try {
        await _apiService.registerProduction(
          groupId: item.groupId,
          date: DateFormat('yyyy-MM-dd').format(item.date),
          tokens: item.tokens,
        );
        successful.add(item);
      } catch (_) {
        // stop on first failure to avoid rate issues
        break;
      }
    }

    if (successful.isNotEmpty) {
      final remaining = queue.where((e) => !successful.contains(e)).toList();
      state = state.copyWith(pending: remaining);
      await _persistPending(remaining);
      await fetchGroups();
    }
  }

  void _updateGroupTokens(String groupId, double delta) {
    final updated = state.groups.map((g) {
      if (g.id == groupId) {
        return g.copyWith(tokensToday: g.tokensToday + delta);
      }
      return g;
    }).toList();
    state = state.copyWith(groups: updated);
  }
}

final moderatorConsoleProvider = StateNotifierProvider<ModeratorConsoleNotifier, ModeratorConsoleState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ModeratorConsoleNotifier(api);
});

// ============================================================================
// UI
// ============================================================================

class ModeratorConsoleScreen extends ConsumerWidget {
  const ModeratorConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderatorConsoleProvider);
    final notifier = ref.read(moderatorConsoleProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Grupos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.fetchGroups,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.fetchGroups,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.pending.isNotEmpty)
              _OfflineBanner(pending: state.pending),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (state.loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...state.groups.map((g) => _GroupCard(group: g, onReport: () => _openBottomSheet(context, ref, g))),
            if (!state.loading && state.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('No hay grupos asignados'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openBottomSheet(BuildContext context, WidgetRef ref, ModeratorGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: _ReportForm(group: group, ref: ref),
        );
      },
    );
  }
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.group, required this.onReport});

  final ModeratorGroup group;
  final VoidCallback onReport;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final progress = g.progress;
    final remaining = g.remaining;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = g.goalReached ? (2 + 2 * _controller.value) : 0.5;
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF121422), Color(0xFF0A0E21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: g.goalReached ? Colors.amber.withOpacity(0.5) : Colors.black54,
                  blurRadius: g.goalReached ? 16 : 8,
                  spreadRadius: glow,
                ),
              ],
              border: Border.all(
                color: g.goalReached ? Colors.amberAccent : Colors.white12,
                width: g.goalReached ? 3 : 1,
              ),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      g.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text('${g.membersCount} miembros', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(
                  g.goalReached ? Colors.amberAccent : Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                g.goalReached
                    ? '¡Meta diaria alcanzada! (${NumberFormat('#,###').format(g.tokensToday)} tokens)'
                    : 'Faltan ${NumberFormat('#,###').format(remaining)} tokens para el bono (${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: g.goalReached ? Colors.amberAccent : Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onReport,
                  icon: const Text('📝', style: TextStyle(fontSize: 20)),
                  label: const Text('Reportar Tokens', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFEB1555),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({required this.group, required this.ref});
  final ModeratorGroup group;
  final WidgetRef ref;

  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  final _tokensController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _tokensController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final tokens = double.tryParse(_tokensController.text.replaceAll(',', '.'));
    if (tokens == null || tokens <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número válido de tokens')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.ref.read(moderatorConsoleProvider.notifier).submitProduction(
            group: widget.group,
            date: _selectedDate,
            tokens: tokens,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          'Reportar Tokens - ${widget.group.name}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tokensController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: '0',
            filled: true,
            fillColor: Color(0xFF111427),
            border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFEB1555),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar Producción'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Si no hay internet, guardaremos el reporte y lo enviaremos automáticamente más tarde.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.pending});
  final List<PendingProduction> pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo offline: ${pending.length} reporte(s) pendientes. Se enviarán automáticamente cuando vuelva la conexión.',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }
}
