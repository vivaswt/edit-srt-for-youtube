import 'package:flutter_test/flutter_test.dart';
import 'package:edit_srt_for_youtube/api/cloud_translation.dart';

void main() {
  group('test', () {
    test('parseResponseJson', () {
      final jsonString = '''
{
  "data": {
    "translations": [
      {
        "translatedText": "Anthropic は、最先端の AI モデルの動作評価を自動化するオープンソースのエージェント フレームワーク Bloom をリリースしました。"
      },
      {
        "translatedText": "このシステムは、研究者が指定した行動を取得し、その行動が現実的なシナリオでどのくらいの頻度で、どのくらいの強さで現れるかを測定する、対象を絞った評価を構築します。"
      }
    ]
  }
}
''';
      final results = parseResponseJson(jsonString);
      expect(results, [
        'Anthropic は、最先端の AI モデルの動作評価を自動化するオープンソースのエージェント フレームワーク Bloom をリリースしました。',
        'このシステムは、研究者が指定した行動を取得し、その行動が現実的なシナリオでどのくらいの頻度で、どのくらいの強さで現れるかを測定する、対象を絞った評価を構築します。',
      ]);
    });
  });
}
