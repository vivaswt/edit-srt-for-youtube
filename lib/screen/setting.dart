import 'package:edit_srt_for_youtube/extension/widget_wrap.dart';
import 'package:edit_srt_for_youtube/model/setting_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _folderPathController = TextEditingController();
  final _preferences = SettingsService().getSaveFolderPath();

  @override
  void dispose() {
    _folderPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: FutureBuilder(
      future: _preferences,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _folderPathController.text = snapshot.data!;
          _folderPathController.addListener(() {
            SettingsService().setSaveFolderPath(_folderPathController.text);
          });
          return TextField(
            controller: _folderPathController,
            decoration: InputDecoration(
              labelText: 'Save Folder Path',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _pickFolder,
              ),
            ),
            readOnly: true,
          );
        }

        return const CircularProgressIndicator()
            .wrapWithSizedBox(width: 60, height: 60)
            .wrapWithCenter();
      },
    ).wrapWithPadding(padding: const EdgeInsets.all(16.0)),
  );

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      _folderPathController.text = selectedDirectory;
    }
  }
}
