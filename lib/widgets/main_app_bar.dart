import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey filterButtonKey;
  final VoidCallback onFilterPressed;

  const MainAppBar({
    super.key,
    required this.filterButtonKey,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Image.network(
            'https://raw.githubusercontent.com/mschula79-coder/Stadtschreiber/f39994cfe3e217fe10e7df5c5b4b4e6b51b4daf1/logo-basel.png',
            height: 35,
          ),
          const SizedBox(width: 5),
          const Text(
            'THIS IS BASEL',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: IconButton(
            key: filterButtonKey,
            iconSize: 50,
            icon: Image.network(
              'https://raw.githubusercontent.com/mschula79-coder/Stadtschreiber/refs/heads/main/map_search_black.png',
              height: 30,
              width: 30,
            ),
            onPressed: onFilterPressed,
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
