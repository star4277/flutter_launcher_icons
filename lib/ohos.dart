import 'dart:io';

import 'package:flutter_launcher_icons/config/config.dart';
import 'package:flutter_launcher_icons/constants.dart' as constants;
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/utils.dart' as utils;
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

/// Template for OHOS icon generation
class OhosIconTemplate {
  /// Creates an [OhosIconTemplate] with the given [size] and [fileName]
  OhosIconTemplate({
    required this.size,
    required this.fileName,
  });

  /// The file name for the icon
  final String fileName;

  /// The size of the icon in pixels
  final int size;
}

/// List of OHOS icon templates to generate
final List<OhosIconTemplate> ohosIcons = <OhosIconTemplate>[
  OhosIconTemplate(fileName: 'app_icon.png', size: 144),
  OhosIconTemplate(fileName: 'icon.png', size: 144),
];

/// Creates OHOS launcher icons based on the provided [config] and [flavor]
Future<void> createIcons(Config config, String? flavor) async {
  utils.printStatus('Creating default icons for OHOS');
  final String? filePath = config.getImagePathOhos();
  if (filePath == null) {
    throw const InvalidConfigException(constants.errorMissingImagePath);
  }
  final Image? image = await utils.decodeImageFile(filePath);
  if (image == null) {
    return;
  }

  final concurrentIconUpdates = <Future<void>>[];

  utils.printStatus(
    'Overwriting the default OHOS launcher icon with a new icon',
  );

  for (OhosIconTemplate template in ohosIcons) {
    concurrentIconUpdates.add(
      overwriteExistingIcons(
        template,
        image,
        flavor,
      ),
    );
  }

  await Future.wait(concurrentIconUpdates);
}

/// Overwrites existing OHOS icons with the provided [template] and [image]
Future<void> overwriteExistingIcons(
  OhosIconTemplate template,
  Image image,
  String? flavor,
) async {
  final Image newFile = utils.createResizedImage(template.size, image);

  const String ohosProjectPath = 'ohos';

  final List<String> targetPaths = <String>[
    path.join(
      ohosProjectPath,
      'AppScope',
      'resources',
      'base',
      'media',
      template.fileName,
    ),
    path.join(
      ohosProjectPath,
      'entry',
      'src',
      'main',
      'resources',
      'base',
      'media',
      template.fileName,
    ),
    path.join(
      ohosProjectPath,
      'entry',
      'src',
      'ohosTest',
      'resources',
      'base',
      'media',
      template.fileName,
    ),
  ];

  for (final targetPath in targetPaths) {
    final file = File(targetPath);
    if (!file.existsSync()) {
      continue;
    }
    final pngFile = await file.create(recursive: true);
    await pngFile.writeAsBytes(encodePng(newFile));
  }
}
