import 'dart:io';
import 'dart:typed_data';

class Arceus {
  final File? _file;
  File get file => _file!;

  Arceus(this._file);
  Uint8List? _bytes;
  Uint8List get bytes {
    _bytes ??= _file!.readAsBytesSync();
    return _bytes!;
  }
}
