const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'lib', 'screens');

function walk(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        isDirectory ? walk(dirPath, callback) : callback(path.join(dir, f));
    });
}

let modifiedCount = 0;

walk(dir, function(filePath) {
    if (filePath.endsWith('.dart')) {
        let content = fs.readFileSync(filePath, 'utf8');
        
        if (content.includes('<style>')) {
            let changed = false;

            if (!content.includes('package:berwehsan/core/print_style.dart')) {
                const match = content.match(/import\s+'[^']+';/g);
                if (match && match.length > 0) {
                    const lastImport = match[match.length - 1];
                    content = content.replace(lastImport, lastImport + "\nimport 'package:berwehsan/core/print_style.dart';");
                } else {
                    content = "import 'package:berwehsan/core/print_style.dart';\n" + content;
                }
            }

            // More robust patterns:
            
            // Pattern 1: Multi-line style block wrapped in individual writelns
            const multiLineStyle = /buffer\.writeln\(['"]<html>['"]\);\s*buffer\.writeln\(['"]<head>['"]\);\s*buffer\.writeln\(['"]<meta charset="UTF-8">['"]\);\s*buffer\.writeln\(['"]<style>['"]\);[\s\S]*?buffer\.writeln\(['"]<\/style>['"]\);\s*buffer\.writeln\(['"]<\/head>['"]\);\s*buffer\.writeln\(['"]<body>['"]\);/g;
            content = content.replace(multiLineStyle, () => {
                changed = true;
                return "buffer.writeln('<html>');\nbuffer.writeln(PrintStyle.htmlHead);\nbuffer.writeln('<body>');";
            });

            // Pattern 2: Multi-line style block without html/head/body wrapping in exact same order
            // If they are missing some tags, just match from <style> to </style>
            if (!changed) {
                const styleOnly = /buffer\.writeln\(['"]<style>['"]\);[\s\S]*?buffer\.writeln\(['"]<\/style>['"]\);/g;
                content = content.replace(styleOnly, () => {
                    changed = true;
                    return "buffer.writeln(PrintStyle.htmlHead);";
                });
            }

            // Pattern 3: Single line style like '<style>table ...</style>' or '<style>...'
            const singleLineStyle = /buffer\.writeln\(['"]<style(?:>|[^]*?['"]\);)/g;
            if (!changed) {
                // Not completely safe, let's look for specific single line ones
                const singleLine = /buffer\.writeln\(['"](?:<html><head><meta charset="UTF-8">)?<style>.*?<\/style>(?:<\/head><body>)?['"]\);/g;
                content = content.replace(singleLine, () => {
                    changed = true;
                    return "buffer.writeln('<html>');\nbuffer.writeln(PrintStyle.htmlHead);\nbuffer.writeln('<body>');";
                });
            }
            
            // For IncomePage and others, some have <style>... inside one writeln, let's match that:
            const singleLineUnclosed = /buffer\.writeln\(['"]<style(?:>.*?)?['"]\);/g;
            if (!changed) {
                 content = content.replace(singleLineUnclosed, () => {
                    changed = true;
                    return "buffer.writeln(PrintStyle.htmlHead);";
                 });
            }

            // Replace headings h1/h2/h3
            const h1Pattern = /buffer\.writeln\(['"]<h[1-3]>(.*?)<\/h[1-3]>['"]\);\n/g;
            content = content.replace(h1Pattern, function(match, titleContent) {
                return "buffer.writeln(PrintStyle.getHeader('" + titleContent + "'));\n";
            });

            // Replace single-line html head style
            const htmlHeadStyle = /buffer\.writeln\(['"]<html><head><meta charset="UTF-8"><style>['"]\);/g;
            content = content.replace(htmlHeadStyle, function() {
                changed = true;
                return "buffer.writeln('<html>');\nbuffer.writeln(PrintStyle.htmlHead);\n";
            });
            
            const headMetaStyle = /buffer\.writeln\(['"]<head><meta charset="UTF-8"><style>['"]\);/g;
            content = content.replace(headMetaStyle, function() {
                changed = true;
                return "buffer.writeln(PrintStyle.htmlHead);\n";
            });

            if (changed) {
                fs.writeFileSync(filePath, content, 'utf8');
                modifiedCount++;
                console.log('Updated', filePath);
            }
        }
    }
});

console.log('Modified', modifiedCount, 'files.');
