import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const Color _selectedColor = Color(0xFF9C7CFE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _item('assets/svg/headphones.svg', 0),
                _item('assets/svg/heart.svg', 1),
                _item('assets/svg/home.svg', 2),
                _item('assets/svg/explore.svg', 3),
                _item('assets/svg/user.svg', 4),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _item(String asset, int index) {
    final bool selected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? _selectedColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          asset,
          width: 26,
          height: 26,
          colorFilter: ColorFilter.mode(
            selected ? _selectedColor : Colors.white.withValues(alpha: 0.5), 
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}


