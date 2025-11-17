import 'package:edit_srt_for_youtube/model/word.dart';
import 'package:xml/xml.dart';
import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';

/// Parses the content of an srv2 subtitle file into a list of [Word] objects.
///
/// The srv2 format is an XML-based format. This function expects the raw
/// string content of that file.
///
/// Throws an [ArgumentError] if the XML is malformed or the expected
/// structure is not found.
List<Word> parseSrv2(String xmlContent) {
  final document = XmlDocument.parse(xmlContent);
  final elements = document.findAllElements('text').map(_toRecord);

  return elements
      .zipAllWith(
        elements.skip(1),
        _toWord,
        ifLonger: (r) => Word(start: r.t, end: r.t + r.d, text: r.text.trim()),
      )
      .where((w) => w.text.isNotEmpty)
      .toList();
}

typedef Srv2Text = ({int t, int d, int? append, String text});

Word _toWord(Srv2Text current, Srv2Text next) =>
    Word(text: current.text.trim(), start: current.t, end: next.t);

Srv2Text _toRecord(XmlElement element) {
  final t = _attributeAsInt(element, 't');
  final d = _attributeAsInt(element, 'd');
  final append = _attributeAsNullableInt(element, 'append');
  final text = _decodeEscapedCharacters(element.innerText);
  return (t: t, d: d, append: append, text: text);
}

String _decodeEscapedCharacters(String text) =>
    text.replaceAllMapped(RegExp(r'&#(\d+?);'), (match) {
      final int code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    });

int _attributeAsInt(XmlElement e, String name) {
  final value = e.getAttribute(name);
  if (value == null && name == 'd') return 10;
  if (value == null) {
    throw Exception('attribute $name not found in subtitles file');
  }
  return int.parse(value);
}

int? _attributeAsNullableInt(XmlElement e, String name) {
  final hasAttribute = e.attributes.any((a) => a.name.local == name);
  return hasAttribute
      ? int.parse(e.attributes.firstWhere((a) => a.name.local == name).value)
      : null;
}
