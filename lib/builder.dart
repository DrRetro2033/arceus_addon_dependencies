import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:yaml/yaml.dart';

void compile() {
  final _compiler = Compiler();
  final projectPath = Directory.current.path;
  String addonName;

  final dir = Directory(projectPath);
  Map<String, Map<String, String>> packages = {"project": {}};
  final files = dir
      .listSync(recursive: true)
      .where((element) => element.path.endsWith('.dart'))
      .map((e) => e.path)
      .toList(); // Get all the dart files.

  AddOnFingerprint y;
  if (!dir
      .listSync()
      .map((e) => e.path)
      .toList()
      .any((e) => e.endsWith('addon.yaml') || e.endsWith('addon.yml'))) {
    throw Exception(
        "Cannot compile without an addon.yaml file in the project folder.");
  } else {
    File addonYaml = File('$projectPath/addon.yaml');
    if (!addonYaml.existsSync()) {
      addonYaml = File('$projectPath/addon.yml');
    }
    final addonYamlMap = loadYaml(addonYaml.readAsStringSync());
    addonName = addonYamlMap['name'];
    y = AddOnFingerprint.fromYaml(addonYamlMap);
  }

  if (!files.any((e) => e.endsWith('main.dart'))) {
    throw Exception(
        "Cannot compile without a main.dart file in the project folder with read, write, and isCompatible functions.");
  } else {
    final mainCode = File("$projectPath/main.dart").readAsStringSync();
    if (!mainCode.contains("Map<String, dynamic> read(String file)") ||
        !mainCode
            .contains("void write(String file, Map<String, dynamic> data)") ||
        !mainCode.contains("bool isCompatible(String file)")) {
      throw Exception(
          "Cannot compile without a read, write, and or isCompatible function in the main.dart file.");
    }
  }

  for (var file in files) {
    final code = File(file).readAsStringSync(); // Read the file.
    packages["project"]?[file] = code; // Add the file to the package.
  }

  final addon = _compiler.compile(packages); // The compiled code.
  final addonFile = File('$projectPath/build/$addonName.evc');
  addonFile.createSync(
      recursive: true); // Create the compiled file for writing to.

  addonFile.writeAsBytesSync(y.fingerprint.codeUnits,
      mode: FileMode.write); // Write the fingerprint to disk.

  addonFile.writeAsBytesSync(addon.write(),
      mode: FileMode.append); // Write the compiled addon to disk.
}

class AddOnFingerprint {
  final String name;
  final String author;
  final String version;
  final String description;
  final YamlList compatibleFiles;

  AddOnFingerprint(this.name, this.author, this.version, this.description,
      this.compatibleFiles);

  String get fingerprint {
    String x = '$name\n$author\n$version\n$description\n';
    for (var file in compatibleFiles) {
      x += '$file\n';
    }
    x += "<END_OF_FINGERPRINT>\n";
    return x;
  }

  factory AddOnFingerprint.fromYaml(YamlMap yaml) {
    return AddOnFingerprint(yaml['name'], yaml['author'], yaml['version'],
        yaml['description'], yaml['compatible-files']);
  }

  factory AddOnFingerprint.fromLines(List<String> lines) {
    return AddOnFingerprint(lines[0], lines[1], lines[2], lines[3],
        YamlList.wrap(lines.sublist(4)));
  }

  @override
  String toString() {
    return "Name: $name\nAuthor: $author\nVersion: $version\nDescription: $description\nCompatible Files: $compatibleFiles";
  }
}
