import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:yaml/yaml.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder getAddonBuilder(BuilderOptions options) => AddonBuilder();

class AddonBuilder implements Builder {
  final compiler = Compiler();

  @override
  Future<void> build(BuildStep buildStep) async {
    print(buildStep.inputId.path);
    final inputFiles = await buildStep.findAssets(Glob("**")).toList();
    print(inputFiles.map((e) => e.path));
    await compile(buildStep, inputFiles);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'.dart': ['build/output.evc']
      };
}

Future<void> compile(BuildStep buildStep, List<AssetId> files) async {
  final compiler = Compiler();
  String addonName;
  Map<String, Map<String, String>> packages = {"project": {}};
  AddOnFingerprint y;
  if (!files.any((e) {
    return e.path.endsWith('addon.yaml');
  })) {
    YamlMap yaml = YamlMap();
    for (var file in files) {
      if (file.path.endsWith('addon.yaml')) {
        final content = await buildStep.readAsString(file);
        print(content);
        yaml = loadYaml(content) as YamlMap;
      }
    }
    y = AddOnFingerprint.fromYaml(
      yaml,
    );
    addonName = y.name;
  } else {
    throw Exception(
        "Cannot compile without an addon.yaml file in the project folder.");
  }

  if (!files.any((e) {
    return e.path.endsWith('main.dart');
  })) {
    throw Exception(
        "Cannot compile without a main.dart file in the project folder with read, write, and isCompatible functions.");
  } else {
    final mainCode = await buildStep
        .readAsString(files.firstWhere((e) => e.path.endsWith('main.dart')));
    if (!mainCode.contains("Map<String, dynamic> read(String file)") ||
        !mainCode
            .contains("void write(String file, Map<String, dynamic> data)") ||
        !mainCode.contains("bool isCompatible(String file)")) {
      throw Exception(
          "Cannot compile without a read, write, and or isCompatible function in the main.dart file.");
    }
  }

  for (var file in files) {
    final code = await buildStep.readAsString(file);
    packages["project"]?[file.path] = code; // Add the file to the package.
  }

  final addon = compiler.compile(packages); // The compiled code.
  print(buildStep.inputId.path);
  print(buildStep.inputId.package);
  final outputId = AssetId(buildStep.inputId.package, 'build/output.evc');
  final finalFile = y.fingerprint.codeUnits.toList();
  finalFile.addAll(addon.write().toList());
  await buildStep.writeAsBytes(
    outputId,
    Uint8List.fromList(finalFile),
  );
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
