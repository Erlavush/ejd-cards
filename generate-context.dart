// generate_context.dart
import 'dart:io';
import 'package:path/path.dart' as p;

// --- Configuration ---
const String outputFile = 'project_context.txt';
final String rootDir = Directory.current.path;

// Directories to completely ignore. This is the most effective way to cut tokens.
final Set<String> excludeDirs = {
  '.git',
  '.dart_tool',
  '.idea',
  'build',
  'ios',
  'android',
  'linux',
  'macos',
  'windows',
  'web',
  '.fvm', // In case you use Flutter Version Management
};

// Specific file names to exclude.
final Set<String> excludeFiles = {
  'pubspec.lock',
  'generate_context.dart', // Exclude this script itself
  'generate-tree.cjs',     // Exclude the other script
  'project-tree.txt',
  outputFile,
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.metadata',
  'README.md',
};

// File extensions to exclude.
final Set<String> excludeExtensions = {
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.svg',
  '.woff', '.woff2', '.ttf', '.eot',
  '.db', '.sqlite', '.sqlite3',
  '.DS_Store',
  '.iml',
  '.packages',
};
// --- End Configuration ---

Future<void> main() async {
  final outputFileSink = File(outputFile).openWrite();
  int processedCount = 0;
  int excludedCount = 0;

  print('--- Starting Context Generation Script ---');
  print('Root directory: $rootDir');
  print('Output file: $outputFile');

  outputFileSink.writeln('--- Project Context for ${p.basename(rootDir)} ---');
  outputFileSink.writeln('--- Generated on: ${DateTime.now().toIso8601String()} ---');
  outputFileSink.writeln('--- Root Directory: $rootDir ---\n\n');

  final entities = Directory(rootDir).listSync(recursive: true, followLinks: false);

  entities.sort((a, b) {
    if (a is Directory && b is File) return -1;
    if (a is File && b is Directory) return 1;
    return a.path.compareTo(b.path);
  });

  for (final entity in entities) {
    final relativePath = p.relative(entity.path, from: rootDir);
    final pathParts = p.split(relativePath);

    if (pathParts.any((part) => excludeDirs.contains(part))) {
      excludedCount++;
      continue;
    }

    if (entity is File) {
      final fileName = p.basename(entity.path);
      final fileExt = p.extension(fileName).toLowerCase();

      if (excludeFiles.contains(fileName) || excludeExtensions.contains(fileExt)) {
        excludedCount++;
        continue;
      }

      print('Processing: $relativePath');
      processedCount++;
      
      outputFileSink.writeln('--- START FILE: $relativePath ---');
      try {
        final content = await entity.readAsString();
        if (content.isEmpty) {
          outputFileSink.writeln('[EMPTY FILE]');
        } else {
          outputFileSink.writeln(content);
        }
      } catch (e) {
        outputFileSink.writeln('[ERROR: Could not read file as text - likely a binary file]');
      }
      outputFileSink.writeln('--- END FILE: $relativePath ---\n\n');
    }
  }

  await outputFileSink.close();
  print('--- Script Finished ---');
  print('Processed $processedCount files.');
  print('Excluded $excludedCount files/directories.');
  print('Output saved to: $outputFile');
}