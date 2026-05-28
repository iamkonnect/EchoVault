import 'package:flutter/material.dart';
import '../services/image_utils.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.currentIndex,
    this.onSelected,
  });

  final int currentIndex;
  final void Function(int)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Image(
              image: ImageUtils.getAppLogo(),
              width: 36.0,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(Icons.home, 0),
                _buildIconButton(Icons.explore, 1),
                _buildIconButton(Icons.music_video, 2),
                _buildIconButton(Icons.video_library, 3),
                _buildIconButton(Icons.account_circle, 4),
                _buildIconButton(Icons.account_balance_wallet, 5),
                _buildIconButton(Icons.insights, 6),
                _buildIconButton(Icons.settings, 7),
                _buildIconButton(Icons.mail, 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, 
          color: currentIndex == index ? Colors.white : Colors.grey, 
          size: 20.0
        ),
        onPressed: () => onSelected?.call(index),
      ),
    );
  }
}
