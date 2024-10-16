import 'dart:io';
import 'arceus.dart';
import 'values.dart';

void openFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw Exception('File not found: $path');
  }
  final arceus = Arceus(file);
  currentInstance = arceus;
}
