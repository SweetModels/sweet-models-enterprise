import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';

class CameraMonitorScreen extends StatefulWidget {
  const CameraMonitorScreen({Key? key}) : super(key: key);

  @override
  State<CameraMonitorScreen> createState() => _CameraMonitorScreenState();
}

class _CameraMonitorScreenState extends State<CameraMonitorScreen> {
  bool _isLoading = true;
  bool _hasAccess = false;
  String _userRole = '';
  List<Map<String, dynamic>> _cameras = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadCameras();
  }

  Future<void> _checkAccessAndLoadCameras() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener rol del usuario
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString('user_role') ?? '';

      // Verificar si es admin
      if (_userRole != 'admin') {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }

      // Cargar cámaras desde la API
      final response = await ApiService().getCameras();

      setState(() {
        _hasAccess = true;
        _cameras = List<Map<String, dynamic>>.from(response['cameras'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasAccess = false;
        _isLoading = false;
        _errorMessage = 'Error al cargar las cámaras: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Monitoreo de Cámaras'),
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAccessAndLoadCameras,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1555)),
              ),
            )
          : !_hasAccess
              ? _buildAccessDenied()
              : _buildCameraGrid(isLargeScreen),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        color: const Color(0xFF1D1E33),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.block,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Acceso Denegado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Solo los administradores pueden acceder al sistema de monitoreo de cámaras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu rol actual: ${_userRole.isEmpty ? "Desconocido" : _userRole}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1555),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraGrid(bool isLargeScreen) {
    if (_cameras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              size: 100,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay cámaras disponibles',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkAccessAndLoadCameras,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB1555),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con contador
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1D1E33),
          child: Row(
            children: [
              const Icon(
                Icons.videocam,
                color: Color(0xFFEB1555),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '${_cameras.length} Cámaras Activas',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, size: 12, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid de cámaras
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLargeScreen ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 16 / 9,
            ),
            itemCount: _cameras.length,
            itemBuilder: (context, index) {
              final camera = _cameras[index];
              return _buildCameraCard(camera);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraCard(Map<String, dynamic> camera) {
    final name = camera['name'] ?? 'Cámara Sin Nombre';
    final platform = camera['platform'] ?? 'Unknown';
    final isActive = camera['is_active'] ?? false;
    final streamUrl = camera['stream_url'] ?? '';

    return Card(
      elevation: 4,
      color: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCameraDetails(camera),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.green : Colors.red.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Placeholder de video (simulado)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.videocam : Icons.videocam_off,
                      size: 60,
                      color: isActive
                          ? const Color(0xFFEB1555)
                          : Colors.white38,
                    ),
                    const SizedBox(height: 8),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '● REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Overlay con información
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getPlatformIcon(platform),
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              platform,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Badge de estado
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'studio':
        return Icons.business;
      case 'vip':
        return Icons.star;
      case 'lobby':
        return Icons.meeting_room;
      default:
        return Icons.videocam;
    }
  }

  void _showCameraDetails(Map<String, dynamic> camera) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFEB1555)),
            const SizedBox(width: 8),
            const Text(
              'Detalles de Cámara',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre', camera['name'] ?? 'N/A'),
              _buildDetailRow('ID', camera['id']?.toString() ?? 'N/A'),
              _buildDetailRow('Plataforma', camera['platform'] ?? 'N/A'),
              _buildDetailRow(
                'Estado',
                camera['is_active'] == true ? '✅ Activo' : '❌ Inactivo',
              ),
              _buildDetailRow('URL Stream', camera['stream_url'] ?? 'N/A', mono: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFEB1555)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
