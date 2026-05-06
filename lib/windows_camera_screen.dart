import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class WindowsCameraScreen extends StatefulWidget {
  const WindowsCameraScreen({super.key});

  @override
  State<WindowsCameraScreen> createState() => _WindowsCameraScreenState();
}

class _WindowsCameraScreenState extends State<WindowsCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  String? _error;
  int _selectedCameraIndex = 0;

  static const _kBg = Color(0xFF1A0E3B);
  static const _kAccent = Color(0xFF9C7CFE);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No se detectó ninguna cámara';
          _isInitializing = false;
        });
        return;
      }

      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      setState(() {
        _error = 'Error al inicializar la cámara: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller?.dispose();

    final camera = _cameras![cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _selectedCameraIndex = cameraIndex;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al configurar la cámara: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;
    
    final newIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    setState(() {
      _isInitializing = true;
    });
    await _setupCamera(newIndex);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        Navigator.of(context).pop(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar la foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildCameraPreview(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text('Cámara', style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            )),
          ),
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
              onPressed: _switchCamera,
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _kAccent),
            const SizedBox(height: 16),
            Text(
              'Inicializando cámara...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.red.withOpacity(0.7), size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Cámara no disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kAccent.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            _buildCornerBrackets(),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBrackets() {
    const size = 24.0;
    const thick = 3.0;
    const r = 8.0;
    const color = _kAccent;

    Widget corner({required Alignment align, required BorderRadius br}) =>
        Align(
          alignment: align,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: size, height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: align == Alignment.topLeft || align == Alignment.topRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    left: align == Alignment.topLeft || align == Alignment.bottomLeft
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    right: align == Alignment.topRight || align == Alignment.bottomRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                  ),
                  borderRadius: br,
                ),
              ),
            ),
          ),
        );

    return Stack(
      children: [
        corner(align: Alignment.topLeft, br: const BorderRadius.only(topLeft: Radius.circular(r))),
        corner(align: Alignment.topRight, br: const BorderRadius.only(topRight: Radius.circular(r))),
        corner(align: Alignment.bottomLeft, br: const BorderRadius.only(bottomLeft: Radius.circular(r))),
        corner(align: Alignment.bottomRight, br: const BorderRadius.only(bottomRight: Radius.circular(r))),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: _kAccent, width: 3),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}