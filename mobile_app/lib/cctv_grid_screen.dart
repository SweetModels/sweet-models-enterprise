import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'api_service.dart';

class CctvGridScreen extends StatefulWidget {
  const CctvGridScreen({Key? key}) : super(key: key);

  @override
  State<CctvGridScreen> createState() => _CctvGridScreenState();
}

class _CctvGridScreenState extends State<CctvGridScreen> {
  late Future<Map<String, dynamic>> _camerasFuture;
  List<CameraStreamPlayer> _streamPlayers = [];
  String _userRole = '';
  bool _hasAccess = true;

  @override
  void initState() {
    super.initState();
    _camerasFuture = _loadCameras();
  }

  Future<Map<String, dynamic>> _loadCameras() async {
    try {
      final camerasData = await ApiService().getCameras();
      // Inicializar players después de cargar cámaras
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePlayers(camerasData);
      });
      return camerasData;
    } catch (e) {
      print('Error loading cameras: $e');
      rethrow;
    }
  }

  void _initializePlayers(Map<String, dynamic> camerasData) {
    final cameras = List.from(camerasData['cameras'] ?? []);
    final players = <CameraStreamPlayer>[];

    for (int i = 0; i < cameras.length; i++) {
      final camera = cameras[i];
      final player = CameraStreamPlayer(
        cameraIndex: i,
        name: camera['name'] ?? 'Camera ${i + 1}',
        streamUrl: camera['stream_url'] ?? '',
        isActive: camera['is_active'] ?? false,
      );
      players.add(player);
    }

    setState(() => _streamPlayers = players);
  }

  @override
  void dispose() {
    for (var player in _streamPlayers) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1E33),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Color(0xFFEB1555)),
            SizedBox(width: 8),
            Text('Monitoreo en Vivo'),
          ],
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _camerasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFEB1555),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar cámaras',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final cameras = List.from(data['cameras'] ?? []);
          final totalActive = data['total_active'] ?? 0;

          return CustomScrollView(
            slivers: [
              // Header con estadísticas
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: const Color(0xFF1A1F3A),
                elevation: 0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📹 $totalActive Activas',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green,
                        ),
                      ),
                      child: const Text(
                        '🟢 EN VIVO',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grid de cámaras
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 16 / 9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _streamPlayers.length) {
                        return const SizedBox();
                      }
                      return _buildCameraCard(_streamPlayers[index], cameras[index]);
                    },
                    childCount: _streamPlayers.length,
                  ),
                ),
              ),

              // Info footer
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1E33),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF262D47),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Estadísticas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _statRow(
                              '🟢 Activas',
                              '$totalActive',
                              Colors.green,
                            ),
                            _statRow(
                              '🔴 Inactivas',
                              '${cameras.length - totalActive}',
                              Colors.red,
                            ),
                            _statRow(
                              '📍 Ubicaciones',
                              _getLocationCount(cameras).toString(),
                              const Color(0xFFEB1555),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraCard(CameraStreamPlayer player, Map<String, dynamic> camera) {
    return GestureDetector(
      onTap: () => _showCameraFullscreen(player, camera),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: camera['is_active'] ? Colors.green : Colors.grey,
            width: 1.5,
          ),
          boxShadow: [
            if (camera['is_active'])
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: player.isInitialized
                  ? _buildVideoPlayer(player)
                  : _buildPlaceholder(camera),
            ),

            // Overlay con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
            ),

            // Info & Status
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera['name'] ?? 'Camera',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    camera['platform'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Live Badge
            if (camera['is_active'])
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (!player.isInitialized)
              const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFEB1555),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(CameraStreamPlayer player) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.videocam,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Map<String, dynamic> camera) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            camera['is_active'] ? Icons.videocam : Icons.videocam_off,
            color: camera['is_active'] ? Colors.white24 : Colors.red,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            camera['is_active'] ? 'Cargando...' : 'Sin Señal',
            style: TextStyle(
              color: camera['is_active'] ? Colors.white38 : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showCameraFullscreen(CameraStreamPlayer player, Map<String, dynamic> camera) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            _buildVideoPlayer(player),

            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Info bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera['name'] ?? 'Camera',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: camera['is_active'] ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          camera['is_active'] ? '🟢 En Vivo' : '🔴 Inactiva',
                          style: TextStyle(
                            color: camera['is_active'] ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '📍 ${camera['platform'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'URL: ${camera['stream_url'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getLocationCount(List<dynamic> cameras) {
    final locations = <String>{};
    for (var camera in cameras) {
      final platform = camera['platform'] as String?;
      if (platform != null) {
        locations.add(platform);
      }
    }
    return locations.length;
  }
}

// Clase auxiliar para manejar streams de cámara
class CameraStreamPlayer {
  final int cameraIndex;
  final String name;
  final String streamUrl;
  final bool isActive;
  bool isInitialized = false;

  CameraStreamPlayer({
    required this.cameraIndex,
    required this.name,
    required this.streamUrl,
    required this.isActive,
  }) {
    _initialize();
  }

  void _initialize() {
    // En una implementación real, aquí inicializarías el player RTSP
    // Por ahora, simulamos que se carga después de un delay
    Future.delayed(const Duration(seconds: 1), () {
      isInitialized = true;
    });
  }

  void dispose() {
    // Limpiar recursos del player
  }
}
