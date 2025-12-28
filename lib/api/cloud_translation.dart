import 'dart:convert';

import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';
import 'package:edit_srt_for_youtube/extension/fp_list.dart';
import 'package:edit_srt_for_youtube/fp/task_either.dart';
import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:http/http.dart' as http;

TaskEither<Exception, Iterable<SrtRecord>> translateSrt(
  Iterable<SrtRecord> srts,
  String apiKey,
) => srts
    .map((srt) => srt.text)
    .chunk(50)
    .map((lines) => translateTextLines(lines, apiKey))
    .pipe(TaskEither.sequence)
    .map((ss) => ss.flatten())
    .map((translatedLines) => _editTranslatedSrts(srts, translatedLines));

Iterable<SrtRecord> _editTranslatedSrts(
  Iterable<SrtRecord> srts,
  List<String> translatedLines,
) => srts.zipWith(translatedLines, (srt, line) => srt.copyWith(text: line));

TaskEither<Exception, List<String>> translateTextLines(
  List<String> textLines,
  String apiKey,
) => TaskEither.tryCatch(
  () => _translate(textLines, apiKey),
  (e) => e as Exception,
);

Future<List<String>> _translate(List<String> phrases, String apiKey) async {
  final res = await _callApi(phrases, apiKey);
  _checkStatusCode(res);
  return parseResponseJson(res.body);
}

Future<http.Response> _callApi(List<String> phrases, String apiKey) {
  const String url = 'https://translation.googleapis.com/language/translate/v2';

  final Map<String, String> headers = {
    'x-goog-api-key': apiKey,
    'Content-Type': 'application/json; charset=utf-8',
  };

  return http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(_editRequestBody(phrases)),
  );
}

void _checkStatusCode(http.Response res) {
  if (res.statusCode != 200) {
    throw Exception(
      'Failed to translate SRT to Japanese :'
      'Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

Map<String, dynamic> _editRequestBody(List<String> phrases) => {
  'source': 'en',
  'target': 'ja',
  'format': 'text',
  'q': phrases,
};

List<String> parseResponseJson(String jsonString) {
  List<dynamic> getTranslations(dynamic json) => switch (json) {
    {'data': {'translations': final List<dynamic> translations}} =>
      translations,
    _ => throw Exception("Invalid response format as the translated texts"),
  };
  String getTranslatedText(dynamic json) => switch (json) {
    {'translatedText': final String text} => text,
    _ => throw Exception("Invalid response format as the translated texts"),
  };

  final json = jsonDecode(jsonString);

  return getTranslations(json).map(getTranslatedText).toList();
}
