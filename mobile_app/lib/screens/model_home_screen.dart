import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/model_service.dart';
import 'login_screen.dart';
import 'kyc_upload_screen.dart';
import '../widgets/attendance_button.dart';

// Colors - Sweet Models Gamification Theme
const Color _bgDarkPurple = Color(0xFF2D1B3D);
const Color _bgLightPurple = Color(0xFF4A2D5E);
const Color _accentPink = Color(0xFFE91E63);
const Color _accentDorado = Color(0xFFD4AF37);
const Color _successGreen = Color(0xFF4CAF50);
const Color _warningOrange = Color(0xFFFFA726);
const Color _whiteText = Color(0xFFFFFFFF);
const Color _greyText = Color(0xFFB0B0B0);

/// Model Statistics Response
class ModelStats {
  final int xp;
  final String rank;
  final String icon;
  final int nextLevelIn;
  final double progress;
  final int todayTokens;
  final double todayEarningsCop;

  ModelStats({
    required this.xp,
    required this.rank,
    required this.icon,
    required this.nextLevelIn,
    required this.progress,
    required this.todayTokens,
    required this.todayEarningsCop,
  });

  factory ModelStats.fromJson(Map<String, dynamic> json) {
    return ModelStats(
      xp: json['xp'] as int? ?? 0,
      rank: json['rank'] as String? ?? 'Novice',
      icon: json['icon'] as String? ?? '🐣',
      nextLevelIn: json['next_level_in'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      todayTokens: json['today_tokens'] as int? ?? 0,
      todayEarningsCop: (json['today_earnings_cop'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory ModelStats.empty() {
    return ModelStats(
      xp: 0,
      rank: 'Novice',
      icon: '🐣',
      nextLevelIn: 20000,
      progress: 0.0,
      todayTokens: 0,
      todayEarningsCop: 0.0,
    );
  }
}

/// Model Home Screen - Gamification Dashboard
class ModelHomeScreen extends StatefulWidget {
  const ModelHomeScreen({Key? key}) : super(key: key);

  @override
  State<ModelHomeScreen> createState() => _ModelHomeScreenState();
}

class _ModelHomeScreenState extends State<ModelHomeScreen> {
  late ModelService _modelService;
  late Future<ModelStats> _statsFuture;
  late Future<List<PenaltyEvent>> _penaltiesFuture;

  @override
  void initState() {
    super.initState();
    _modelService = ModelService();
    _statsFuture = _modelService.getModelStats();
    _penaltiesFuture = _modelService.getRecentPenalties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDarkPurple,
      appBar: _buildAppBar(),
      body: FutureBuilder<ModelStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentDorado),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _modelService.getModelStats();
                _penaltiesFuture = _modelService.getRecentPenalties();
              });
            },
            color: _accentDorado,
            backgroundColor: _bgLightPurple,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🕐 Attendance Button - First thing to see
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bgLightPurple.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accentDorado.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: AttendanceButton(
                      onStatusChanged: () {
                        setState(() {
                          _statsFuture = _modelService.getModelStats();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Last Events / Penalties alert
                  FutureBuilder<List<PenaltyEvent>>(
                    future: _penaltiesFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final events = snap.data ?? [];
                      if (events.isEmpty) return const SizedBox.shrink();

                      final now = DateTime.now();
                      final hasToday = events.any((e) => e.createdAt.year == now.year && e.createdAt.month == now.month && e.createdAt.day == now.day);

                      return Column(
                        children: [
                          if (hasToday)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: Row(
                                children: [
                                  const Text('⚠️', style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Sanción Aplicada: ${events.first.reason} (${events.first.xpDeduction} XP)',
                                      style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          _buildRecentEventsList(events),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  // Welcome Message
                  _buildWelcomeSection(stats),
                  const SizedBox(height: 28),

                  // Main Progress Circle
                  _buildProgressCircle(stats),
                  const SizedBox(height: 28),

                  // Motivational Message
                  _buildMotivationalMessage(stats),
                  const SizedBox(height: 28),

                  // Stats Cards
                  _buildStatsCards(stats),
                  const SizedBox(height: 28),

                  // Daily Goal Card
                  _buildDailyGoalCard(stats),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgLightPurple,
      elevation: 0,
      title: Text(
        '✨ Sweet Models - Level Up! ✨',
        style: GoogleFonts.poppins(
          color: _accentPink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.verified_user, color: Color(0xFF4CAF50)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const KycUploadScreen(),
              ),
            );
          },
          tooltip: 'Verificación KYC',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFFF44336)),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentPink.withOpacity(0.3),
                _accentDorado.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ModelStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎮 Welcome Back!',
          style: GoogleFonts.poppins(
            color: _whiteText,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You\'re a ${stats.rank} ${stats.icon} - Keep climbing!',
          style: GoogleFonts.poppins(
            color: _greyText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCircle(ModelStats stats) {
    return Center(
      child: CircularPercentIndicator(
        radius: 120,
        lineWidth: 12,
        percent: stats.progress.clamp(0.0, 1.0),
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stats.icon,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 8),
            Text(
              stats.rank,
              style: GoogleFonts.poppins(
                color: _accentPink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(stats.progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: _accentDorado,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        progressColor: _accentPink,
        backgroundColor: _bgLightPurple,
        circularStrokeCap: CircularStrokeCap.round,
        animation: true,
        animationDuration: 1000,
      ),
    );
  }

  Widget _buildMotivationalMessage(ModelStats stats) {
    String message;
    Color messageColor;

    if (stats.progress < 0.3) {
      message = '🔥 ¡Vamos a calentar motores! Necesitas ${stats.nextLevelIn} XP más';
      messageColor = _warningOrange;
    } else if (stats.progress > 0.8) {
      message = '🚀 ¡Casi tocas el cielo! Solo ${stats.nextLevelIn} XP para el siguiente nivel';
      messageColor = _accentPink;
    } else {
      message = '💪 ¡Vas muy bien! ${stats.nextLevelIn} XP para ascender';
      messageColor = _successGreen;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: messageColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: messageColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ModelStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Today',
            value: '${stats.todayTokens}',
            subtitle: 'Tokens',
            color: _successGreen,
            icon: '🎯',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Earnings',
            value: '\$${stats.todayEarningsCop.toStringAsFixed(0)}',
            subtitle: 'COP',
            color: _accentDorado,
            icon: '💰',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: _greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: _greyText,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(ModelStats stats) {
    // Assume daily goal is 100 tokens
    const dailyGoal = 100;
    final dailyProgress = (stats.todayTokens / dailyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentPink.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Daily Goal',
                style: GoogleFonts.poppins(
                  color: _whiteText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${stats.todayTokens}/$dailyGoal',
                style: GoogleFonts.poppins(
                  color: _accentPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: dailyProgress,
            progressColor: _accentPink,
            backgroundColor: _bgDarkPurple,
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 500,
          ),
          const SizedBox(height: 8),
          Text(
            dailyProgress >= 1.0
                ? '🎉 Daily goal completed!'
                : 'Need ${(dailyGoal - stats.todayTokens).toStringAsFixed(0)} more tokens',
            style: GoogleFonts.poppins(
              color: dailyProgress >= 1.0 ? _successGreen : _greyText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEventsList(List<PenaltyEvent> events) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos Eventos',
            style: GoogleFonts.poppins(
              color: _whiteText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...events.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Text('⚠️'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${e.reason} (${e.xpDeduction} XP)',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Text(
                      _formatShortDate(e.createdAt),
                      style: GoogleFonts.poppins(color: _greyText, fontSize: 11),
                    )
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgLightPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFF44336), width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 48),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFF44336),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    color: _greyText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _statsFuture = _modelService.getModelStats();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentDorado,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No data available',
        style: GoogleFonts.poppins(
          color: _greyText,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💸 Request payment feature coming soon!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _accentPink,
          ),
        );
      },
      backgroundColor: _accentPink,
      icon: const Icon(Icons.attach_money),
      label: Text(
        'REQUEST PAYMENT',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgLightPurple,
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            color: _whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(color: _greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: _accentDorado),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('access_token');
              await _modelService.clearCache();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Color(0xFFF44336),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
