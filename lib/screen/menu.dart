import 'package:edit_srt_for_youtube/screen/download.dart';
import 'package:edit_srt_for_youtube/screen/edit_subtitles.dart';
import 'package:edit_srt_for_youtube/screen/setting.dart';
import 'package:edit_srt_for_youtube/screen/translate_subtitles.dart';
import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Menu'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingScreen()),
            );
          },
        ),
      ],
    ),
    body: Center(
      child: Column(
        spacing: 16,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DownloadScreen()),
              );
            },
            child: const Text('Download Video & Subtitles'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EditFirstScreen()),
              );
            },
            child: const Text('Edit Subtitles'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => TranslateScreen()),
              );
            },
            child: const Text('Translate Subtitles'),
          ),
        ],
      ),
    ),
  );
}
