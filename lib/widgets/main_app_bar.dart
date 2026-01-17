import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
/* import 'package:flutter_svg/flutter_svg.dart'; */

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
          Image.asset('assets/icons/basel.jpg', height: 35),
          /* SvgPicture.asset( 'assets/icons/basel.svg', height: 35, ), */
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
            icon: 
              Iconify(Mdi.map_search, size: 30),
            onPressed: onFilterPressed,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
