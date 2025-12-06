import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/financial_candle.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final ApiService _apiService = ApiService();
  
  List<FinancialCandle> _candleData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final data = await _apiService.getFinancialHistory();
      
      setState(() {
        _candleData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  double _calculateDayTokens() {
    if (_candleData.isEmpty) return 0;
    return _candleData.last.volume;
  }

  double _calculateDayRevenue() {
    if (_candleData.isEmpty) return 0;
    return _candleData.last.close;
  }

  double _calculateEstimatedNomina() {
    if (_candleData.isEmpty) return 0;
    return _calculateDayRevenue() * 0.30 * 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Rendimiento del Studio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _fetchFinancialData,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, color: Colors.black, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(color: Colors.red.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchFinancialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _fetchFinancialData,
      backgroundColor: Colors.black87,
      color: Colors.green.shade400,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del Día',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Tokens', _calculateDayTokens(), 'tokens',
                          Icons.trending_up, Colors.blue.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Dólar', _calculateDayRevenue(), 'USD',
                          Icons.attach_money, Colors.green.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Nómina', _calculateEstimatedNomina(), 'COP',
                          Icons.account_balance_wallet, Colors.orange.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gráfico de 30 Días',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800, width: 1),
                    ),
                    height: 280,
                    child: _buildCandleChart(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Mínimo (30d)',
                    _formatCurrency(
                      _candleData.isNotEmpty
                          ? _candleData.map((c) => c.low).reduce((a, b) => a < b ? a : b)
                          : 0,
                    ),
                    Colors.red.shade400,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'Máximo (30d)',
                    _formatCurrency(
                      _candleData.isNotEmpty
                          ? _candleData.map((c) => c.high).reduce((a, b) => a > b ? a : b)
                          : 0,
                    ),
                    Colors.green.shade400,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'Cierre Último',
                    _formatCurrency(
                      _candleData.isNotEmpty ? _candleData.last.close : 0,
                    ),
                    Colors.blue.shade400,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'Volumen Total',
                    '${(_candleData.fold<double>(0, (sum, c) => sum + c.volume) / 1000).toStringAsFixed(1)}K',
                    Colors.purple.shade400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandleChart() {
    if (_candleData.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: Colors.grey)),
      );
    }
    return CustomPaint(
      painter: CandleChartPainter(candles: _candleData),
      child: Container(),
    );
  }

  Widget _buildSummaryCard(String title, double value, String unit,
      IconData icon, Color color) {
    String display;
    if (unit == 'tokens') {
      display = '${(value / 1000).toStringAsFixed(1)}K';
    } else if (unit == 'USD') {
      display = '\$${value.toStringAsFixed(2)}';
    } else {
      display = '\$${(value / 1000000).toStringAsFixed(1)}M';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(display,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(unit,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class CandleChartPainter extends CustomPainter {
  final List<FinancialCandle> candles;
  CandleChartPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 30.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;
    
    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    final range = (maxPrice - minPrice) * 1.1;
    minPrice -= (maxPrice - minPrice) * 0.05;

    final gridPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = padding + (height / 5) * i;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1;
    
    canvas.drawLine(Offset(padding, padding), Offset(padding, size.height - padding), axisPaint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(size.width - padding, size.height - padding), axisPaint);

    final candleWidth = width / (candles.length + 1);

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = padding + (i + 1) * candleWidth;

      final openY = size.height - padding - ((c.open - minPrice) / range) * height;
      final highY = size.height - padding - ((c.high - minPrice) / range) * height;
      final lowY = size.height - padding - ((c.low - minPrice) / range) * height;
      final closeY = size.height - padding - ((c.close - minPrice) / range) * height;

      final color = c.close >= c.open ? const Color(0xFF00FF41) : const Color(0xFFFF1744);

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), Paint()..color = color..strokeWidth = 1);

      final bodyHeight = (openY - closeY).abs().clamp(1.0, double.infinity);
      final bodyY = openY < closeY ? openY : closeY;
      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth * 0.3, bodyY, candleWidth * 0.6, bodyHeight),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(CandleChartPainter oldDelegate) => false;
}
