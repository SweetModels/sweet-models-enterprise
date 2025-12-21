import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Widget para marcar entrada/salida (Check-in/Check-out)
class AttendanceButton extends StatefulWidget {
  final Function? onStatusChanged;

  const AttendanceButton({Key? key, this.onStatusChanged}) : super(key: key);

  @override
  State<AttendanceButton> createState() => _AttendanceButtonState();
}

class _AttendanceButtonState extends State<AttendanceButton> {
  bool _isWorking = false;
  DateTime? _checkInTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;

  static const String baseUrl = 'http://10.0.2.2:3000';
  final _greenNeon = const Color(0xFF00FF00);
  final _redOrange = const Color(0xFFFF6B35);
  final _darkBg = const Color(0xFF0F0F1E);

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'No hay sesión activa';
        });
        return;
      }

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.get(
        '/api/model/attendance-status',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _isWorking = data['is_working'] ?? false;
          if (_isWorking && data['check_in_time'] != null) {
            _checkInTime = DateTime.parse(data['check_in_time']);
            _startTimer();
          }
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance status: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error cargando estado';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_checkInTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_checkInTime!);
        });
      }
    });
    // Calcular tiempo inicial
    if (_checkInTime != null) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_checkInTime!);
      });
    }
  }

  Future<void> _performCheckIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _showError('No hay sesión activa');
        return;
      }

      setState(() => _isLoading = true);

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post(
        '/api/model/check-in',
        data: {},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isWorking = true;
          _checkInTime = DateTime.now();
          _elapsedTime = Duration.zero;
          _isLoading = false;
        });
        _startTimer();
        _showSuccess('¡Bienvenida! Turno iniciado.');
        widget.onStatusChanged?.call();
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Error al marcar entrada';
      _showError(errorMsg);
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performCheckOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _showError('No hay sesión activa');
        return;
      }

      setState(() => _isLoading = true);

      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post(
        '/api/model/check-out',
        data: {},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final hours = (data['duration_hours'] as num?)?.toStringAsFixed(2) ?? '0';
        
        setState(() {
          _isWorking = false;
          _checkInTime = null;
          _elapsedTime = Duration.zero;
          _isLoading = false;
        });
        _timer?.cancel();
        
        _showSuccess(
          'Turno finalizado.\nTrabajaste $hours horas.',
        );
        widget.onStatusChanged?.call();
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Error al marcar salida';
      _showError(errorMsg);
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingButton();
    }

    if (_isWorking) {
      return _buildCheckOutButton();
    }

    return _buildCheckInButton();
  }

  Widget _buildLoadingButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[700],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando estado...',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _performCheckIn,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _greenNeon.withOpacity(0.15),
                border: Border.all(
                  color: _greenNeon,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _greenNeon.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  '●',
                  style: TextStyle(
                    fontSize: 60,
                    color: _greenNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MARCAR ENTRADA',
            style: GoogleFonts.poppins(
              color: _greenNeon,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para iniciar tu turno',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _performCheckOut,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _redOrange.withOpacity(0.15),
                border: Border.all(
                  color: _redOrange,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _redOrange.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '●',
                      style: TextStyle(
                        fontSize: 50,
                        color: _redOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_elapsedTime),
                      style: GoogleFonts.poppins(
                        color: _redOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'FINALIZAR TURNO',
            style: GoogleFonts.poppins(
              color: _redOrange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiempo: ${_formatDuration(_elapsedTime)}',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
