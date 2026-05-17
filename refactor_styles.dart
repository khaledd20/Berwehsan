import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\khali\Desktop\Berwehsan-1\lib\screens');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int modifiedCount = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    
    if (content.contains('<style>')) {
      bool changed = false;

      // Ensure PrintStyle is imported
      if (!content.contains('package:berwehsan/core/print_style.dart')) {
        // Find last import
        int lastImportIndex = content.lastIndexOf(RegExp(r"import\s+'[^']+';"));
        if (lastImportIndex != -1) {
          int endOfLine = content.indexOf('\n', lastImportIndex);
          content = content.substring(0, endOfLine + 1) + 
                    "import 'package:berwehsan/core/print_style.dart';\n" + 
                    content.substring(endOfLine + 1);
        } else {
          content = "import 'package:berwehsan/core/print_style.dart';\n" + content;
        }
      }

      // We want to replace the HTML generation part.
      // Usually it's something like:
      // buffer.writeln('<html>');
      // buffer.writeln('<head>');
      // buffer.writeln('<meta charset="UTF-8">');
      // buffer.writeln('<style>');
      // ...
      // buffer.writeln('</style>');
      // buffer.writeln('</head>');
      // buffer.writeln('<body>');
      // buffer.writeln('<h1>TITLE</h1>');

      // Let's use Regex to find everything from buffer.writeln('<html>'); or buffer.writeln('<head>') or <style>
      // up to <body> and the first heading <h1> or <h2> or <h3>
      
      final stylePattern = RegExp(r"(buffer\.writeln\(['\u0022]<html[^\n]*\n)?(buffer\.writeln\(['\u0022]<head>[^\n]*\n)?(buffer\.writeln\(['\u0022]<meta charset=[^\n]*\n)?buffer\.writeln\(['\u0022]<style>[^\n]*\n(?:.*?buffer\.writeln\(['\u0022].*?\n)*?buffer\.writeln\(['\u0022]<\/style>['\u0022]\);\n(buffer\.writeln\(['\u0022]<\/head>['\u0022]\);\n)?(buffer\.writeln\(['\u0022]<body[^>]*>['\u0022]\);\n)?", multiLine: true, dotAll: true);
      
      content = content.replaceAllMapped(stylePattern, (match) {
        changed = true;
        return "buffer.writeln('<html>');\nbuffer.writeln(PrintStyle.htmlHead);\nbuffer.writeln('<body>');\n";
      });

      // Now we need to replace the first <h1> or <h2> after the newly replaced body with PrintStyle.getHeader(...)
      // Actually, since we replaced <body>, let's find the first <h\d> that comes right after.
      final h1Pattern = RegExp(r"buffer\.writeln\(['\u0022]<h[1-3]>(.*?)<\/h[1-3]>['\u0022]\);\n");
      content = content.replaceAllMapped(h1Pattern, (match) {
        // We only want to replace if it is close to <body>, but replacing all <h> at root is fine for these tables usually.
        // Wait, what if there's multiple? We can just replace all headings with getHeader(title) or just the first one.
        // Better to replace it all since they are usually titles.
        String titleContent = match.group(1)!;
        // The titleContent might contain Dart string interpolation variables like $year.
        // Since it's inside single quotes in the source, it's just dart code.
        return "buffer.writeln(PrintStyle.getHeader('\${$titleContent}'));\n"; // Wrapping in ${...} will evaluate it properly if it was previously string interpolation. Actually, if it was '<h1>$year</h1>', group 1 is '$year'. So we can just do getHeader('$year').
      });

      // Fix double string interpolation if needed, e.g. '${$year}' -> '$year' (we don't need to do '${...}' if we just insert it directly into the dart string.
      // Wait, if group 1 is `كشف توريد الكفالة للسنة $year`, returning `buffer.writeln(PrintStyle.getHeader('${كشف توريد الكفالة للسنة $year}'));` is invalid dart.
      // We should return `buffer.writeln(PrintStyle.getHeader('$titleContent'));`
      // Let's refine:
      content = content.replaceAllMapped(h1Pattern, (match) {
        String titleContent = match.group(1)!;
        return "buffer.writeln(PrintStyle.getHeader('$titleContent'));\n";
      });

      // Some files have `<style>table { width: 100%; border-collapse: collapse; margin-top: 20px; }` on a single line!
      // Example: buffer.writeln('<style>table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
      final singleLineStylePattern = RegExp(r"buffer\.writeln\(['\u0022]<style>table.*?['\u0022]\);\n");
      content = content.replaceAllMapped(singleLineStylePattern, (match) {
        changed = true;
        return "buffer.writeln('<html>');\nbuffer.writeln(PrintStyle.htmlHead);\nbuffer.writeln('<body>');\n";
      });

      if (changed) {
        file.writeAsStringSync(content);
        modifiedCount++;
        print('Updated \${file.path}');
      }
    }
  }
  print('Modified $modifiedCount files.');
}
