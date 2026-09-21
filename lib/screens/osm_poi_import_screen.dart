import 'package:flutter/material.dart';
import 'package:stadtschreiber/services/osm_pbf_import_service.dart';
import 'package:file_picker/file_picker.dart';

class OsmPoiImportScreen extends StatefulWidget {
  const OsmPoiImportScreen({super.key});

  @override
  State<OsmPoiImportScreen> createState() => _OsmPoiImportScreenState();
}

class _OsmPoiImportScreenState extends State<OsmPoiImportScreen> {
  String status = "Bereit";
  bool isImporting = false;
  bool isFinished = false;
  String selectedFilePath = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OSM POI Import")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isImporting ? null : pickFile,
              child: const Text("Datei auswählen"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isImporting ? null : startImport,
              child: const Text("OSM POIs importieren"),
            ),

            const SizedBox(height: 20),

            // ⭐ Cancel-Button (immer sichtbar)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startImport() async {
    if (selectedFilePath == "") {
      setState(() => status = "Bitte zuerst eine Datei auswählen.");
      return;
    }

    setState(() {
      status = "Import läuft...";
      isImporting = true;
    });

    final result = await OsmPbfPoiImportService().runImport(
      filePath: selectedFilePath,
      onStatus: (msg) {
        setState(() => status = msg);
      },
    );

    setState(() {
      status = result;
      isImporting = false;
      isFinished = true;
    });
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> pickFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pbf'],
    );

    if (result == null) return; // User hat abgebrochen

    setState(() {
      selectedFilePath = result.uri.path;
      status = "Datei gewählt:\n$selectedFilePath";
    });
  }
}
