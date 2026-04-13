import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'utils/share_helper.dart';

class PlaylistResultScreen extends StatelessWidget {
  final String title;
  final String subtitleUser;
  final String mood;

  const PlaylistResultScreen({super.key, required this.title, required this.subtitleUser, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Stack(
          children: [
            // Top bar icons
            Positioned(
              left: 8,
              top: 6,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2x2 cover grid
                    Row(
                      children: [
                        _coverBox('assets/images/artist1.png'),
                        const SizedBox(width: 8),
                        _coverBox('assets/images/artist2.png'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _coverBox('assets/images/artist3.png'),
                        const SizedBox(width: 8),
                        _coverBox('assets/images/artist4.png'),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitleUser,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Mood: $mood',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _roundIcon(Icons.search),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            ShareHelper.shareText('Escucha mi playlist \'$title\' en Sound Flow');
                          },
                          child: _roundIcon(Icons.share_outlined),
                        ),
                        const SizedBox(width: 14),
                        _roundIcon(Icons.playlist_add),
                        const Spacer(),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }

  Widget _coverBox(String asset) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}


