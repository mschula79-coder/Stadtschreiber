import 'package:flutter/material.dart';

class MapActions extends StatelessWidget {
  const MapActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.info_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {},
            mini: true,
            child: const Icon(Icons.my_location),
          ),
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
