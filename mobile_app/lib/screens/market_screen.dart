import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';

const Color _bgDeep = Color(0xFF0F0A1F);
const Color _cardInk = Color(0xFF18152B);
const Color _accentPink = Color(0xFFFF2E63);
const Color _accentAmber = Color(0xFFFFB400);
const Color _accentMint = Color(0xFF00F5D4);

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late final Dio _dio;
  final NumberFormat _decimal = NumberFormat.decimalPattern('es_CO');
  final List<dynamic> _products = [];

  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _showSuccessAnimation = false;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiService.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      }),
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _hydrateSession();
    await _fetchProducts();
  }

  Future<void> _hydrateSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
  }

  Future<void> _fetchProducts() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final response = await _dio.get('/api/market/products');
      if (!mounted) return;
      _products
        ..clear()
        ..addAll(response.data is List ? response.data : []);
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar productos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _buyProduct(Map<String, dynamic> product) async {
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero')),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(product);
    if (confirmed != true) return;

    try {
      setState(() {
        _isPurchasing = true;
        _showSuccessAnimation = false;
      });

      final response = await _dio.post(
        '/api/market/buy/$_userId',
        data: {'product_id': product['id']},
      );

      if (!mounted) return;
      setState(() => _showSuccessAnimation = true);
      await Future.delayed(const Duration(milliseconds: 900));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.data['message'] ?? '¡Compra exitosa! Se descontará en tu nómina.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      await _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la compra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _showSuccessAnimation = false;
      });
    }
  }

  Future<bool?> _showConfirmDialog(Map<String, dynamic> product) {
    final double price = (product['price_cop'] as num?)?.toDouble() ?? 0;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Comprar ${product['name']}?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '- \$${_decimal.format(price)} COP',
              style: GoogleFonts.montserrat(
                color: _accentPink,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se descontará de tu saldo en el próximo corte.',
              style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'COMPRAR',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Sweet Boutique 🛍️',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchProducts,
            icon: const Icon(Icons.refresh, color: _accentMint),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgDeep, Color(0xFF14102A), _bgDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: _accentPink,
                backgroundColor: _cardInk,
                onRefresh: _fetchProducts,
                child: _buildContent(),
              ),
              if (_showSuccessAnimation)
                Center(
                  child: Lottie.asset(
                    'assets/animations/success.json',
                    height: 220,
                    repeat: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentPink),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: GoogleFonts.montserrat(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh),
              label: Text('Reintentar', style: GoogleFonts.montserrat()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentAmber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Text(
          'No hay productos disponibles',
          style: GoogleFonts.montserrat(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _ProductCard(
          product: product,
          onBuy: _isPurchasing ? null : () => _buyProduct(product),
          currency: _decimal,
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onBuy;
  final NumberFormat currency;

  const _ProductCard({
    required this.product,
    required this.onBuy,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final double price = (product['price_cop'] as num?)?.toDouble() ?? 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _cardInk,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentPink.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentPink.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product['image_url'] ?? 'https://via.placeholder.com/300',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      color: const Color(0xFF231B3F),
                      child: const Icon(Icons.image_not_supported, color: Colors.white38),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product['stock'] != null ? 'Stock: ${product['stock']}' : 'Disponible',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Producto',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '- \$${currency.format(price)} COP',
                    style: GoogleFonts.montserrat(
                      color: _accentAmber,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: Text(
                        'COMPRAR',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
