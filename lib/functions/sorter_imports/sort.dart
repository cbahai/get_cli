import 'dart:convert';

import '../../common/utils/pubspec/pubspec_utils.dart';
import '../../core/structure.dart';
import '../../extensions.dart';
import '../create/create_single_file.dart';
// import '../formatter_dart_file/frommatter_dart_file.dart';
import '../path/replace_to_relative.dart';

/// Sort imports from a dart file
String sortImports(
  String content, {
  String? packageName,
  bool renameImport = false,
  String filePath = '',
  bool useRelative = false,
}) {
  packageName = packageName ?? PubspecUtils.projectName;
  final filePathElements = Structure.safeSplitPath(filePath);
  final lastIndexOfLib = filePathElements.lastIndexOf('lib');
  if (lastIndexOfLib > 0) {
    packageName = filePathElements[lastIndexOfLib - 1];
  }
  // content = formatterDartFile(content);
  var lines = LineSplitter.split(content).toList();

  var contentLines = <String>[];

  var librarys = <String>[];
  var dartImports = <String>[];
  var flutterImports = <String>[];
  var packageImports = <String>[];
  var projectRelativeImports = <String>[];
  var projectImports = <String>[];
  var exports = <String>[];

  var stringLine = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    if (line.startsWith('import ') &&
        !stringLine &&
        line.endsWith(';')) {
      if (line.contains('dart:')) {
        dartImports.add(line);
      } else if (line.contains('package:flutter/')) {
        flutterImports.add(line);
      } else if (line.contains('package:$packageName/')) {
        projectImports.add(line);
      } else if (!line.contains('package:')) {
        projectRelativeImports.add(line);
      } else if (line.contains('package:')) {
        if (!line.contains('package:flutter/')) {
          packageImports.add(line);
        }
      }
    } else if (line.startsWith('export ') &&
        line.endsWith(';') &&
        !stringLine) {
      exports.add(line);
    } else if (line.startsWith('library ') &&
        line.endsWith(';') &&
        !stringLine) {
      librarys.add(line);
    } else {
      var containsThreeQuotes = line.contains("'''");
      if (containsThreeQuotes) {
        stringLine = !stringLine;
      }
      if (contentLines.isNotEmpty || line.isNotEmpty) {
        contentLines.add(line);
      }
    }
  }

  if (dartImports.isEmpty &&
      flutterImports.isEmpty &&
      packageImports.isEmpty &&
      projectImports.isEmpty &&
      projectRelativeImports.isEmpty &&
      exports.isEmpty) {
    return content;
  }

  if (renameImport) {
    projectImports.replaceAll(_replacePath);

    projectRelativeImports.replaceAll(_replacePath);
  }
  if (filePath.isNotEmpty && useRelative) {
    projectImports
        .replaceAll((element) => replaceToRelativeImport(element, filePath));
    projectRelativeImports.addAll(projectImports);
    projectImports.clear();
  }

  dartImports.sort();
  flutterImports.sort();
  packageImports.sort();
  projectImports.sort();
  projectRelativeImports.sort();
  exports.sort();
  librarys.sort();

  var sortedLines = <String>[];

  if (contentLines.isNotEmpty) {
    contentLines.add('');
  }

  sortedLines.addAll([
    ...librarys,
    if (librarys.isNotEmpty) '',
    ...dartImports,
    if (dartImports.isNotEmpty) '',
    ...flutterImports,
    if (flutterImports.isNotEmpty) '',
    ...packageImports,
    if (packageImports.isNotEmpty) '',
    ...projectImports,
    if (projectImports.isNotEmpty) '',
    ...projectRelativeImports,
    if (projectRelativeImports.isNotEmpty) '',
    ...exports,
    if (exports.isNotEmpty) '',
    ...contentLines
  ]);

  // return formatterDartFile(sortedLines.join('\n'));
  return sortedLines.join('\n');
}

String _replacePath(String str) {
  var separator = PubspecUtils.separatorFileType!;
  return replacePathTypeSeparator(str, separator);
}
