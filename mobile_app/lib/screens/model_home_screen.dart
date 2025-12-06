import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../api_service.dart';
import '../models/model_home.dart';

final modelHomeProvider = FutureProvider<ModelHomeStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getModelHomeStats();
});

class ModelHomeScreen extends ConsumerStatefulWidget {
  const ModelHomeScreen({super.key});

  @override
  ConsumerState<ModelHomeScreen> createState() => _ModelHomeScreenState();
}

class _ModelHomeScreenState extends ConsumerState<ModelHomeScreen> {
  late final ConfettiController _confettiController;
  bool _hasCelebrated = false;
  String _displayName = 'Modelo';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadName();
  }

  Future<void> _loadName() async {
    final email = await ref.read(apiServiceProvider).getUserEmail();
    if (!mounted) return;
    setState(() {
      _displayName = _extractName(email);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _maybeCelebrate(ModelHomeStats stats) {
    if (!_hasCelebrated && stats.activePoints > 0) {
      _hasCelebrated = true;
      _confettiController.play();
    }
  }

  String _extractName(String? email) {
    if (email == null || email.isEmpty) return 'Modelo';
    final raw = email.split('@').first;
    return raw.isEmpty ? 'Modelo' : raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(modelHomeProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Espacio del Modelo'),
        backgroundColor: const Color(0xFF1A1F3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(modelHomeProvider),
          ),
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: () => Navigator.pushNamed(context, '/model/contract'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF00F5FF),
            backgroundColor: const Color(0xFF1A1F3A),
            onRefresh: () async {
              await ref.refresh(modelHomeProvider.future);
            },
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(message: err.toString(), onRetry: () => ref.refresh(modelHomeProvider)),
              data: (stats) {
                _maybeCelebrate(stats);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  children: [
                    _Header(displayName: _displayName),
                    const SizedBox(height: 18),
                    _PointsCard(stats: stats),
                    const SizedBox(height: 16),
                    _WeeklyProgress(points: stats.activePoints),
                    const SizedBox(height: 20),
                    _EarningsGrid(
                      today: currency.format(stats.todayEarningsCop),
                      week: currency.format(stats.weekEarningsCop),
                      month: currency.format(stats.monthEarningsCop),
                    ),
                    const SizedBox(height: 20),
                    _SocialSection(onLink: _showLinkSheet),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 18,
              gravity: 0.15,
              maxBlastForce: 18,
              minBlastForce: 8,
              colors: const [
                Color(0xFFFF6B9D),
                Color(0xFF00F5FF),
                Color(0xFF4ADE80),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkSheet(BuildContext context) async {
    final controller = TextEditingController();
    bool submitting = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.pinkAccent),
                      SizedBox(width: 10),
                      Text('Vincular Instagram', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Usuario / Handle',
                      prefixText: '@',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              final handle = controller.text.trim();
                              if (handle.isEmpty) return;
                              setModalState(() => submitting = true);
                              try {
                                await ref.read(apiServiceProvider).linkSocialAccount(
                                      platform: 'instagram',
                                      handle: handle,
                                    );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cuenta vinculada.')),
                                  );
                                  ref.refresh(modelHomeProvider);
                                }
                              } catch (e) {
                                setModalState(() => submitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                      icon: submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(submitting ? 'Vinculando...' : 'Vincular cuenta'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String displayName;
  const _Header({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF00F5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF0A0E27),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.circle, color: Color(0xFF4ADE80), size: 14),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $displayName',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              'Estado: Al día',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
          ],
        )
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  final ModelHomeStats stats;
  const _PointsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141A3A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis Puntos Sweet', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stats.activePoints.toStringAsFixed(0),
                    style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Text('💎', style: TextStyle(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Puntos activos en tu cuenta',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A52),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF00F5FF)),
                const SizedBox(height: 6),
                Text(
                  '+${stats.weekEarningsCop.toStringAsFixed(0)} COP',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  'Semana',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final double points;
  const _WeeklyProgress({required this.points});

  @override
  Widget build(BuildContext context) {
    const double weeklyGoal = 1500;
    final double progress = min(points / weeklyGoal, 1);
    final remaining = max(weeklyGoal - points, 0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFC857)),
              const SizedBox(width: 8),
              Text('Premio Semanal', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltan $remaining pts para el Premio Semanal',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EarningsGrid extends StatelessWidget {
  final String today;
  final String week;
  final String month;
  const _EarningsGrid({required this.today, required this.week, required this.month});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatTile(title: 'Hoy', value: today, icon: Icons.wb_sunny),
      _StatTile(title: 'Esta Semana', value: week, icon: Icons.calendar_view_week),
      _StatTile(title: 'Este Mes', value: month, icon: Icons.date_range),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatTile({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00F5FF)),
          const Spacer(),
          Text(title, style: GoogleFonts.poppins(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SocialSection extends StatelessWidget {
  final Future<void> Function(BuildContext context) onLink;
  const _SocialSection({required this.onLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF007A), Color(0xFFFFB700), Color(0xFF5F64FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Redes Sociales', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                Text('Vincula tu Instagram para sumar bonus', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onLink(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Vincular Cuenta'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
