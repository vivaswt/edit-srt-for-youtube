import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';
import 'package:edit_srt_for_youtube/extension/fp_list.dart';
import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/fp/task_either.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:http/http.dart' as http;

TaskEither<Exception, Iterable<SrtRecord>> translateSrt(
  Iterable<SrtRecord> srts,
  String apiKey,
) => srts
    .map((srt) => srt.text)
    .chunk(30)
    .map((lines) => translateTextLines(lines, apiKey))
    .pipe(TaskEither.sequence)
    .map((ss) => ss.flatten())
    .map(
      (translatedLines) => srts.zipWith(
        translatedLines,
        (srt, line) => srt.copyWith(text: line),
      ),
    );

TaskEither<Exception, List<String>> translateTextLines(
  List<String> textLines,
  String apiKey,
) => TaskEither.tryCatch(
  () => _translate(textLines, apiKey),
  (e) => e as Exception,
);

Future<List<String>> _translate(List<String> textLines, String apiKey) async {
  const String url =
      'https://generativelanguage.googleapis.com/'
      'v1beta/models/gemini-2.5-flash:generateContent';

  final Map<String, String> headers = {
    'x-goog-api-key': apiKey,
    'Content-Type': 'application/json',
  };

  final res = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(_editRequestBody(textLines)),
  );

  if (res.statusCode != 200) {
    throw Exception(
      'Failed to translate SRT to Japanese :'
      'Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }

  final lines = res.body.pipe(extractGeminiResponse).pipe(parseResponseJson);

  if (lines.length != textLines.length) {
    throw Exception('unmatched translated lines length');
  }

  return lines;
}

Map<String, dynamic> _editRequestBody(List<String> textLines) => {
  "system_instruction": {
    "parts": [
      {'text': _translateSystemInstruction},
    ],
  },
  "generationConfig": {
    "responseMimeType": "application/json",
    "responseJsonSchema": {
      "type": "array",
      "items": {"type": "string"},
    },
  },
  "contents": [
    {
      "parts": [
        {"text": jsonEncode(textLines)},
      ],
    },
  ],
};

List<String> parseResponseJson(String jsonString) =>
    switch (jsonDecode(jsonString)) {
      List<dynamic> ls when ls.every((s) => s is String) => ls.cast<String>(),
      _ => throw Exception("Invalid response format as the translated texts"),
    };

String extractGeminiResponse(String responseBody) {
  final json = jsonDecode(responseBody);
  final resultText = pick(
    json,
    'candidates',
    0,
    'content',
    'parts',
    0,
    'text',
  ).asStringOrNull();

  if (resultText == null) {
    final blockReason = pick(
      json,
      'promptFeedback',
      'blockReason',
    ).asStringOrNull();
    throw Exception(
      'Fail to get Gemini response text on translating srt - reason: $blockReason',
    );
  }

  return resultText;
}

const String _translateSystemInstruction = '''
Role: You are a professional subtitle translator.
Task: Translate the English subtitle lines into natural Japanese suitable for on-screen reading.
Constraints:
1. You will receive a JSON array of strings.
2. You must return a valid JSON array of strings.
3. The number of items in the output array MUST be exactly the same as the input array.
4. Do not merge multiple input lines into one output line.
5. Do not split one input line into multiple output lines.
6. Translate strictly line-by-line.
7. Output strictly the JSON, no markdown formatting (like ```json), no intro text.
''';
