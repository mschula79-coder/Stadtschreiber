import 'package:flutter/material.dart';

class MapActions extends StatelessWidget {
  final VoidCallback onChangeStyle;
  const MapActions({super.key, required this.onChangeStyle});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //info
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.info_outlined),
          ),
          const SizedBox(height: 12),
          //change style
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: onChangeStyle,
            mini: true,
            child: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 12),
          //my location
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          //search
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btn4",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
