import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:http/http.dart' as http;

Future<List<String>> translateSrt(Iterable<SrtRecord> srts, String apiKey) =>
    requestForTranslation(
      srts,
      apiKey,
    ).then(extractGeminiResponse).then((resText) => resText.split('\n'));

Future<String> requestForTranslation(
  Iterable<SrtRecord> srts,
  String apiKey,
) async {
  const String url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final Map<String, String> headers = {
    'x-goog-api-key': apiKey,
    'Content-Type': 'application/json',
  };

  final body = {
    "system_instruction": {
      "parts": [
        {'text': _translateSystemInstruction},
      ],
    },
    "contents": [
      {
        "parts": [
          {
            "text": srtRecordsToStrings(
              srts.toList(),
            ).pipe((ls) => ls.join('\n')),
          },
        ],
      },
    ],
  };

  final res = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to translate SRT to Japanese Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

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
  Translate the following English SRT file into Japanese. Follow these rules strictly:
  1. Maintain the *EXACT* same timestamps. Do not change the timestamps at all.
  2. Maintain the same SRT file structure (sequence number, timestamp, text).
  3. Translate the English text into natural, grammatically correct Japanese.
  4. Output ONLY the translated SRT file. Do not include any extra text.
  5. Finally, you must confirm that the IDs and timestamps of the English and Japanese SRT records are the same.
  6. Your response should only consist of SRT records and should exclude other elements, such as comments, analysis or commentaries.
''';
