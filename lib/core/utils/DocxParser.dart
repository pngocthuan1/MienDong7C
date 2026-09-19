import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TextAlign;

// ─── Models ────────────────────────────────────────────────────────────────

class DocxTextRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;

  const DocxTextRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });
}

sealed class DocxBlock {}

class DocxHeadingBlock extends DocxBlock {
  final String text;
  final int level;
  DocxHeadingBlock(this.text, {this.level = 1});
}

class DocxParagraphBlock extends DocxBlock {
  final List<DocxTextRun> runs;
  final TextAlign align;
  final double indentLeft;
  DocxParagraphBlock(this.runs, {this.align = TextAlign.start, this.indentLeft = 0});
  String get plainText => runs.map((r) => r.text).join();
}

class DocxTableBlock extends DocxBlock {
  final List<List<List<DocxTextRun>>> rows;
  DocxTableBlock(this.rows);
}

class DocxListItemBlock extends DocxBlock {
  final List<DocxTextRun> runs;
  final int level;
  final bool isOrdered;
  DocxListItemBlock(this.runs, {this.level = 0, this.isOrdered = false});
  String get plainText => runs.map((r) => r.text).join();
}

class DocxSpacerBlock extends DocxBlock {}
class DocxImagePlaceholderBlock extends DocxBlock {}

// ─── Isolate-safe top-level entry point ─────────────────────────────────────

List<DocxBlock> parseDocxBlocks(Uint8List xmlBytes) {
  try {
    final xmlString = utf8.decode(xmlBytes, allowMalformed: true);
    return _DocxXmlParser(xmlString).parse();
  } catch (_) {
    return [];
  }
}

// ─── Internal parser ─────────────────────────────────────────────────────────

class _DocxXmlParser {
  final String _xml;
  _DocxXmlParser(this._xml);

  List<DocxBlock> parse() {
    final blocks = <DocxBlock>[];
    final bodyMatch = RegExp(r'<w:body[^>]*>(.*?)</w:body>', dotAll: true).firstMatch(_xml);
    final bodyXml = bodyMatch?.group(1) ?? _xml;
    final topLevelElements = _extractTopLevelElements(bodyXml);
    for (final el in topLevelElements) {
      if (el.startsWith('<w:tbl')) {
        final tableBlock = _parseTable(el);
        if (tableBlock != null) blocks.add(tableBlock);
      } else if (el.startsWith('<w:p')) {
        final block = _parseParagraph(el);
        if (block != null) blocks.add(block);
      }
    }
    return blocks;
  }

  List<String> _extractTopLevelElements(String xml) {
    final result = <String>[];
    int i = 0;
    while (i < xml.length) {
      final start = xml.indexOf('<', i);
      if (start == -1) break;
      int nameEnd = start + 1;
      while (nameEnd < xml.length && xml[nameEnd] != ' ' && xml[nameEnd] != '>' && xml[nameEnd] != '/') {
        nameEnd++;
      }
      final tagName = xml.substring(start + 1, nameEnd).trim();
      if (tagName == 'w:p' || tagName == 'w:tbl' || tagName == 'w:sectPr') {
        final tagClose = xml.indexOf('>', start);
        if (tagClose != -1 && tagClose > 0 && xml[tagClose - 1] == '/') {
          result.add(xml.substring(start, tagClose + 1));
          i = tagClose + 1;
          continue;
        }
        final end = _findMatchingClose(xml, start, tagName);
        if (end == -1) { i = start + 1; continue; }
        result.add(xml.substring(start, end));
        i = end;
      } else {
        i = start + 1;
      }
    }
    return result;
  }

  int _findMatchingClose(String xml, int openStart, String tagName) {
    final openTag = '<$tagName';
    final closeTag = '</$tagName>';
    int depth = 0;
    int i = openStart;
    while (i < xml.length) {
      if (xml.startsWith(openTag, i) &&
          xml.length > i + openTag.length &&
          (xml[i + openTag.length] == ' ' || xml[i + openTag.length] == '>')) {
        depth++;
        i += openTag.length;
      } else if (xml.startsWith(closeTag, i)) {
        depth--;
        if (depth == 0) return i + closeTag.length;
        i += closeTag.length;
      } else {
        i++;
      }
    }
    return -1;
  }

  DocxBlock? _parseParagraph(String pXml) {
    final pPrMatch = RegExp(r'<w:pPr>(.*?)</w:pPr>', dotAll: true).firstMatch(pXml);
    final pPrXml = pPrMatch?.group(1) ?? '';

    final styleMatch = RegExp(r'<w:pStyle\s+w:val="([^"]*)"').firstMatch(pPrXml);
    final styleVal = styleMatch?.group(1) ?? '';
    final headingMatch = RegExp(r'[Hh]eading\s*(\d+)|[Hh]eading(\d+)').firstMatch(styleVal);
    final isDocHeading = headingMatch != null;
    final headingLevel = isDocHeading
        ? int.tryParse(headingMatch.group(1) ?? headingMatch.group(2) ?? '1') ?? 1
        : null;
    final isVnHeading = styleVal.contains('Tieu') || styleVal.contains('Title') ||
        styleVal.contains('tieu') || styleVal.contains('Caption');

    final jcMatch = RegExp(r'<w:jc\s+w:val="([^"]*)"').firstMatch(pPrXml);
    TextAlign align = TextAlign.start;
    switch (jcMatch?.group(1)) {
      case 'center': align = TextAlign.center; break;
      case 'right': align = TextAlign.right; break;
      case 'both': align = TextAlign.justify; break;
    }

    final indMatch = RegExp(r'<w:ind\s[^/]*(?:w:left|w:firstLine)="(\d+)"').firstMatch(pPrXml);
    double indentLeft = 0;
    if (indMatch != null) {
      final twips = double.tryParse(indMatch.group(1) ?? '0') ?? 0;
      indentLeft = (twips * 0.0667).clamp(0, 120);
    }

    final numPrMatch = RegExp(r'<w:numPr>(.*?)</w:numPr>', dotAll: true).firstMatch(pPrXml);
    int? numId;
    int listLevel = 0;
    if (numPrMatch != null) {
      final ilvlMatch = RegExp(r'<w:ilvl\s+w:val="(\d+)"').firstMatch(numPrMatch.group(1)!);
      final numIdMatch = RegExp(r'<w:numId\s+w:val="(\d+)"').firstMatch(numPrMatch.group(1)!);
      listLevel = int.tryParse(ilvlMatch?.group(1) ?? '0') ?? 0;
      numId = int.tryParse(numIdMatch?.group(1) ?? '0');
    }

    final runs = _extractRuns(pXml);
    final plainText = runs.map((r) => r.text).join().trim();
    if (plainText.isEmpty) return DocxSpacerBlock();

    final allBold = runs.isNotEmpty && runs.every((r) => r.bold);
    final isShortUpperCase = plainText.length < 120 &&
        (plainText == plainText.toUpperCase() ||
            plainText.startsWith('CỘNG HÒA') ||
            plainText.startsWith('BỆNH VIỆN') ||
            plainText.startsWith('ĐỘC LẬP') ||
            plainText.startsWith('THÔNG BÁO') ||
            plainText.startsWith('KẾ HOẠCH') ||
            plainText.startsWith('QUYẾT ĐỊNH'));

    if (isDocHeading || isVnHeading) {
      return DocxHeadingBlock(plainText, level: headingLevel ?? 2);
    }
    if (allBold && isShortUpperCase) {
      return DocxHeadingBlock(plainText, level: 2);
    }
    if (numId != null && numId > 0) {
      return DocxListItemBlock(runs, level: listLevel);
    }
    return DocxParagraphBlock(runs, align: align, indentLeft: indentLeft);
  }

  List<DocxTextRun> _extractRuns(String pXml) {
    final runs = <DocxTextRun>[];
    final runRegex = RegExp(r'<w:r(?:\s[^>]*)?>.*?</w:r>', dotAll: true);
    for (final rMatch in runRegex.allMatches(pXml)) {
      final rXml = rMatch.group(0)!;
      final rPrMatch = RegExp(r'<w:rPr>(.*?)</w:rPr>', dotAll: true).firstMatch(rXml);
      final rPrXml = rPrMatch?.group(1) ?? '';
      final bold = rPrXml.contains('<w:b/>') || rPrXml.contains('<w:b ') || rPrXml.contains('<w:b>');
      final italic = rPrXml.contains('<w:i/>') || rPrXml.contains('<w:i ') || rPrXml.contains('<w:i>');
      final underline = RegExp(r'<w:u\s').hasMatch(rPrXml) || rPrXml.contains('<w:u/>');

      final tRegex = RegExp(r'<w:t(?:[^>]*)>(.*?)</w:t>', dotAll: true);
      for (final tMatch in tRegex.allMatches(rXml)) {
        final text = tMatch.group(1) ?? '';
        if (text.isNotEmpty) {
          runs.add(DocxTextRun(text, bold: bold, italic: italic, underline: underline));
        }
      }
      if (rXml.contains('<w:br') && !rXml.contains('w:type="page"')) {
        runs.add(const DocxTextRun('\n'));
      }
    }
    return runs;
  }

  DocxTableBlock? _parseTable(String tblXml) {
    final rows = <List<List<DocxTextRun>>>[];
    final trRegex = RegExp(r'<w:tr(?:\s[^>]*)?>.*?</w:tr>', dotAll: true);
    for (final trMatch in trRegex.allMatches(tblXml)) {
      final trXml = trMatch.group(0)!;
      final cells = <List<DocxTextRun>>[];
      final tcRegex = RegExp(r'<w:tc(?:\s[^>]*)?>.*?</w:tc>', dotAll: true);
      for (final tcMatch in tcRegex.allMatches(trXml)) {
        final tcXml = tcMatch.group(0)!;
        final cellRuns = <DocxTextRun>[];
        final pRegex = RegExp(r'<w:p(?:\s[^>]*)?>.*?</w:p>', dotAll: true);
        bool firstP = true;
        for (final pMatch in pRegex.allMatches(tcXml)) {
          final pRuns = _extractRuns(pMatch.group(0)!);
          final pText = pRuns.map((r) => r.text).join().trim();
          if (pText.isNotEmpty) {
            if (!firstP) cellRuns.add(const DocxTextRun('\n'));
            cellRuns.addAll(pRuns);
            firstP = false;
          }
        }
        cells.add(cellRuns);
      }
      if (cells.any((c) => c.any((r) => r.text.trim().isNotEmpty))) {
        rows.add(cells);
      }
    }
    if (rows.isEmpty) return null;
    return DocxTableBlock(rows);
  }
}
