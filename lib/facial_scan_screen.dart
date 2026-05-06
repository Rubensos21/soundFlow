import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_client.dart';
import 'generated_playlist_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE EMOCIÓN
// ─────────────────────────────────────────────────────────────────────────────
class _Emotion {
  final String label;
  final Color color;
  final Color glow;
  final IconData icon;
  const _Emotion({required this.label, required this.color, required this.glow, required this.icon});
}

const _emotions = {
  // Positivas
  'happy':   _Emotion(label: 'Feliz',      color: Color(0xFF2ECC71), glow: Color(0xFF27AE60), icon: Icons.sentiment_very_satisfied),
  'excited': _Emotion(label: 'Emocionado', color: Color(0xFF1ABC9C), glow: Color(0xFF16A085), icon: Icons.celebration),
  'calm':    _Emotion(label: 'Tranquilo',  color: Color(0xFF3498DB), glow: Color(0xFF2980B9), icon: Icons.spa_outlined),
  // Neutras
  'neutral':   _Emotion(label: 'Neutral',     color: Color(0xFFF1C40F), glow: Color(0xFFD4AC0D), icon: Icons.sentiment_neutral),
  'surprised': _Emotion(label: 'Sorprendido', color: Color(0xFFE67E22), glow: Color(0xFFCA6F1E), icon: Icons.sentiment_satisfied),
  // Negativas
  'sad':     _Emotion(label: 'Triste',     color: Color(0xFFE74C3C), glow: Color(0xFFC0392B), icon: Icons.sentiment_very_dissatisfied),
  'angry':   _Emotion(label: 'Enojado',    color: Color(0xFFC0392B), glow: Color(0xFF96281B), icon: Icons.mood_bad),
  'fearful': _Emotion(label: 'Ansioso',    color: Color(0xFF9B59B6), glow: Color(0xFF7D3C98), icon: Icons.sentiment_dissatisfied),
  'disgust': _Emotion(label: 'Disgustado', color: Color(0xFF884EA0), glow: Color(0xFF6C3483), icon: Icons.do_not_disturb_alt),
};

_Emotion _emotionFor(String? raw) {
  if (raw == null) return _emotions['neutral']!;
  return _emotions[raw.toLowerCase()] ?? _emotions['neutral']!;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FacialScanScreen extends StatefulWidget {
  const FacialScanScreen({super.key});

  @override
  State<FacialScanScreen> createState() => _FacialScanScreenState();
}

class _FacialScanScreenState extends State<FacialScanScreen>
    with SingleTickerProviderStateMixin {
  static const _kBg     = Color(0xFF1A0E3B);
  static const _kCard   = Color(0xFF2D1B69);
  static const _kAccent = Color(0xFF9C7CFE);

  final ApiClient _api = ApiClient();

  // States: idle | scanning | result | error
  String _state = 'idle';
  String? _rawEmotion;
  String? _playlistName;
  String? _errorMsg;
  String? _imagePath;
  String? _playlistId;

  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;

  // Simulated scan progress
  double _scanProgress = 0;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  // ── LANZAR CÁMARA / GALERÍA ─────────────────────────────────────────────
  Future<void> _pickAndScan(ImageSource source) async {
    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (xfile == null || !mounted) return;

    setState(() {
      _imagePath    = xfile.path;
      _state        = 'scanning';
      _scanProgress = 0;
      _rawEmotion   = null;
      _errorMsg     = null;
    });

    // Animate progress bar while waiting for API
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _scanProgress = min(_scanProgress + 0.012, 0.92);
      });
    });

    try {
      final result = await _api.generatePlaylistFromFacial(xfile);
      _scanTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _scanProgress = 1.0;
        _rawEmotion   = result['emotion_detected'] as String?;
        _playlistName = result['playlist_name'] as String?;
        _playlistId   = result['playlist_id']?.toString();
        _state        = 'result';
      });
    } catch (e) {
      _scanTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _errorMsg = 'No se pudo analizar la imagen.\nIntenta con otra foto.';
        _state    = 'error';
      });
    }
  }

  void _reset() => setState(() {
    _state        = 'idle';
    _rawEmotion   = null;
    _imagePath    = null;
    _errorMsg     = null;
    _scanProgress = 0;
  });

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final emotion = _emotionFor(_rawEmotion);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 24),
                    _buildViewfinder(emotion),
                    const SizedBox(height: 28),
                    if (_state == 'idle')   _buildIdleActions(),
                    if (_state == 'scanning') _buildScanningIndicator(),
                    if (_state == 'result')  _buildResultCard(emotion),
                    if (_state == 'error')   _buildErrorCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
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
            child: Text('Escaneo Facial', style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            )),
          ),
          if (_state != 'idle' && _state != 'scanning')
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: _kAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    final texts = {
      'idle':     'Toma una foto o sube una imagen\npara detectar tu estado de ánimo',
      'scanning': 'Analizando tu expresión...',
      'result':   'Emoción detectada con éxito ✓',
      'error':    'Algo salió mal',
    };
    return Text(
      texts[_state] ?? '',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontFamily: 'Poppins', height: 1.5),
    );
  }

  // ── VIEWFINDER (cuadro de cámara) ─────────────────────────────────────────
  Widget _buildViewfinder(_Emotion emotion) {
    final frameColor = _state == 'result' ? emotion.color
        : _state == 'scanning' ? _kAccent
        : _kAccent.withOpacity(0.5);

    return ScaleTransition(
      scale: _state == 'scanning' ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: frameColor, width: _state == 'result' ? 2.5 : 1.5),
          boxShadow: [
            BoxShadow(
              color: (_state == 'result' ? emotion.glow : _kAccent).withOpacity(0.35),
              blurRadius: _state == 'result' ? 28 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      (_state == 'result' ? emotion.color : _kAccent).withOpacity(0.18),
                      _kCard,
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
              // Image if taken
              if (_imagePath != null)
                _buildImagePreview(),
              // Corner brackets
              ..._buildCorners(frameColor),
              // Center content when idle
              if (_state == 'idle') _buildIdleCenterContent(),
              // Scanning laser line
              if (_state == 'scanning') _buildLaserLine(),
              // Result emotion icon overlay
              if (_state == 'result') _buildResultOverlay(emotion),
              // Progress bar at bottom
              if (_state == 'scanning') _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    // On web XFile.path is a blob URL, works fine with Image.network
    return Image.network(
      _imagePath!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: _kCard),
    );
  }

  List<Widget> _buildCorners(Color color) {
    const size = 24.0;
    const thick = 3.0;
    const r = 8.0;
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
                    top:    align == Alignment.topLeft || align == Alignment.topRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    left:   align == Alignment.topLeft || align == Alignment.bottomLeft
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                    right:  align == Alignment.topRight || align == Alignment.bottomRight
                        ? BorderSide(color: color, width: thick) : BorderSide.none,
                  ),
                  borderRadius: br,
                ),
              ),
            ),
          ),
        );

    return [
      corner(align: Alignment.topLeft,     br: const BorderRadius.only(topLeft: Radius.circular(r))),
      corner(align: Alignment.topRight,    br: const BorderRadius.only(topRight: Radius.circular(r))),
      corner(align: Alignment.bottomLeft,  br: const BorderRadius.only(bottomLeft: Radius.circular(r))),
      corner(align: Alignment.bottomRight, br: const BorderRadius.only(bottomRight: Radius.circular(r))),
    ];
  }

  Widget _buildIdleCenterContent() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kAccent.withOpacity(0.15),
            border: Border.all(color: _kAccent.withOpacity(0.4)),
          ),
          child: const Icon(Icons.face_retouching_natural, color: _kAccent, size: 36),
        ),
        const SizedBox(height: 12),
        Text('Aquí aparecerá tu rostro',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Poppins', fontSize: 13)),
      ],
    ),
  );

  Widget _buildLaserLine() => AnimatedBuilder(
    animation: _pulseCtrl,
    builder: (_, __) {
      final y = (_pulseCtrl.value * 280).clamp(0.0, 280.0);
      return Positioned(
        top: y,
        left: 16, right: 16,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent, _kAccent.withOpacity(0.9), Colors.transparent,
            ]),
            boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
      );
    },
  );

  Widget _buildResultOverlay(_Emotion emotion) => Positioned(
    top: 12, right: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emotion.color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: emotion.glow.withOpacity(0.5), blurRadius: 10)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(emotion.icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(emotion.label.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
      ]),
    ),
  );

  Widget _buildProgressBar() => Positioned(
    bottom: 0, left: 0, right: 0,
    child: LinearProgressIndicator(
      value: _scanProgress,
      backgroundColor: Colors.white.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
      minHeight: 3,
    ),
  );

  // ── IDLE ACTIONS ──────────────────────────────────────────────────────────
  Widget _buildIdleActions() {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildActionBtn(
          icon: Icons.camera_alt_rounded,
          label: 'Tomar foto',
          primary: true,
          onTap: () => _pickAndScan(ImageSource.camera),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionBtn(
          icon: Icons.photo_library_rounded,
          label: 'Galería',
          primary: false,
          onTap: () => _pickAndScan(ImageSource.gallery),
        )),
      ]),
      const SizedBox(height: 20),
      _buildTipCard(),
    ]);
  }

  Widget _buildActionBtn({required IconData icon, required String label, required bool primary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: primary ? _kAccent : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: primary ? null : Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: primary ? [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildTipCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Row(children: [
      Icon(Icons.lightbulb_outline, color: _kAccent.withOpacity(0.8), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(
        'Para mejores resultados, asegúrate de tener buena iluminación y que tu rostro esté visible.',
        style: TextStyle(color: Colors.white.withOpacity(0.45), fontFamily: 'Poppins', fontSize: 11, height: 1.5),
      )),
    ]),
  );

  // ── SCANNING ──────────────────────────────────────────────────────────────
  Widget _buildScanningIndicator() => Column(children: [
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2.5),
      ),
      const SizedBox(width: 12),
      const Text('Analizando emociones...', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14)),
    ]),
    const SizedBox(height: 20),
    _buildScanSteps(),
  ]);

  Widget _buildScanSteps() {
    final steps = ['Detectando rostro', 'Analizando expresión', 'Generando playlist'];
    return Column(children: steps.asMap().entries.map((e) {
      final done   = _scanProgress > (e.key + 1) / 3.5;
      final active = _scanProgress > e.key / 3.5 && !done;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF2ECC71) : active ? _kAccent : Colors.white.withOpacity(0.1),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : active
                    ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : null,
          ),
          const SizedBox(width: 10),
          Text(steps[e.key], style: TextStyle(
            color: done || active ? Colors.white : Colors.white30,
            fontFamily: 'Poppins', fontSize: 13,
            fontWeight: done || active ? FontWeight.w600 : FontWeight.normal,
          )),
        ]),
      );
    }).toList());
  }

  // ── RESULT CARD ───────────────────────────────────────────────────────────
  Widget _buildResultCard(_Emotion emotion) => Column(children: [
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [emotion.color.withOpacity(0.2), emotion.color.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emotion.color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: emotion.glow.withOpacity(0.25), blurRadius: 20)],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: emotion.color.withOpacity(0.2)),
            child: Icon(emotion.icon, color: emotion.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estado de ánimo',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Poppins', fontSize: 11)),
            const SizedBox(height: 4),
            Text(emotion.label,
              style: TextStyle(color: emotion.color, fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 22)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: emotion.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.circle, color: emotion.color, size: 10),
          ),
        ]),
        if (_playlistName != null) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: Text('Playlist generada',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Poppins', fontSize: 11))),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerLeft, child: Text(_playlistName!,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ]),
    ),
    const SizedBox(height: 16),
    SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
        label: const Text('Ver mi Playlist', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: emotion.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () {
          if (_playlistId != null) {
            // Usamos la nueva pantalla que lee de tu base de datos SQLite
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GeneratedPlaylistDetailScreen(
                playlistId: int.parse(_playlistId!), // Lo convertimos a int
              ),
            ));
          }
        },
      ),
    ),
    const SizedBox(height: 10),
    TextButton(
      onPressed: _reset,
      child: Text('Escanear de nuevo', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Poppins')),
    ),
  ]);

  // ── ERROR CARD ────────────────────────────────────────────────────────────
  Widget _buildErrorCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Column(children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
      const SizedBox(height: 12),
      Text(_errorMsg ?? 'Error desconocido',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13, height: 1.5)),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: _reset,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
        child: const Text('Intentar de nuevo', style: TextStyle(color: Colors.redAccent, fontFamily: 'Poppins')),
      ),
    ]),
  );
}
