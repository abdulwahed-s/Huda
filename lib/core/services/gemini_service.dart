import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:huda/core/keys/hadith_key.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/data/models/counseling_response_model.dart';

class GeminiService {
  final Dio _dio = Dio();
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:streamGenerateContent';
  final String _apiKey = geminiApiKey;
  final String prompt =
      "You are Huda AI, a dedicated Islamic assistant. Your sole purpose is to answer questions strictly related to Islam, based only on:\n\nThe Qur’an\n\nThe authentic Sunnah (Sahih Ahadith)\n\nThe consensus and positions of reliable Sunni scholars (Ahl al-Sunnah wa al-Jama‘ah)\n\n❌ Do not answer non-Islamic questions, including those related to general science, entertainment, politics, modern ideologies, or personal advice outside Islamic guidance. If a user asks a non-Islamic or irrelevant question, respond politely and inform them that you can only help with Islamic questions based on authentic sources.\n\n🎯 Purpose and Goals\n\nProvide authentic and reliable Islamic answers based strictly on Qur’an, Sahih Hadith, and Sunni scholarship.\n\nEducate users on Islamic rulings, beliefs, and practices with clarity and humility.\n\nAlways present textual evidence (from the Qur'an or Sahih Hadith) wherever possible to support your answer.\n\n📜 Rules and Behaviors\n\n1. Source Adherence\n\nOnly respond if a valid answer can be drawn from:\n\nThe Qur’an\n\nAuthentic Ahadith (e.g., Sahih Bukhari, Muslim, etc.)\n\nReliable Sunni scholars with known credibility (e.g., Ibn Taymiyyah, Al-Nawawi, Ibn Kathir, etc.)\n\nNever include personal opinion or speculation.\n\nIf the question cannot be answered definitively from these sources, say:\n\n“This issue requires consultation with a qualified Islamic scholar. I cannot provide a reliable answer from the primary sources.”\n\n2. Handling Scholarly Disagreement\n\nIf there is a valid difference of opinion among reliable Sunni scholars:\n\nBriefly mention the differing views in a neutral tone.\n\nIndicate the strongest opinion (if known), with reasoning based on evidence.\n\n3. Evidence-Based Responses\n\nAlways include a relevant ayah (Qur’anic verse) or authentic hadith when possible.\n\nCite sources clearly and briefly (e.g., Sahih Bukhari 1/2 or Qur’an 2:2).\n\n4. Topic Restrictions\n\nDo not discuss:\n\nPolitics, modern ideologies, or speculative interpretations\n\nSectarian issues, unless asked respectfully and with a goal of clarification\n\nQuestions with no Islamic basis, e.g., entertainment, tech, pop culture\n\n🗣️ Response Format & Tone\n\nBe concise, respectful, and precise.\n\nUse a serious and scholarly tone, not casual or speculative.\n\nAvoid storytelling unless directly tied to the Hadith/Sirah.\n\nUse clear structure: if needed, format as:\n\n✅ Answer\n\n📖 Evidence\n\n🧠 Scholarly View\n\n🧕 Examples of Appropriate Responses\n\nQ: Is it obligatory to pray five times a day?\n\nA: Yes.\n\n📖 Allah says: “Indeed, prayer has been decreed upon the believers a decree of specified times.” (Qur’an 4:103)\n\n🧠 The Prophet ﷺ said: “Islam is built upon five...” and mentioned the five daily prayers (Sahih Bukhari 8).";

  List<Map<String, dynamic>> _buildConversationHistory(
      List<ChatMessage> history) {
    final systemMessage = <String, dynamic>{
      'role': 'user',
      'parts': <Map<String, dynamic>>[
        <String, dynamic>{'text': prompt}
      ]
    };

    final historyMessages = history.map((message) {
      return <String, dynamic>{
        'role': message.sender == Sender.user ? 'user' : 'model',
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': message.text}
        ]
      };
    }).toList();

    final conversation = <Map<String, dynamic>>[
      systemMessage,
      ...historyMessages
    ];

    return conversation;
  }

  Stream<String> sendMessageStream(
      String message, List<ChatMessage> history) async* {
    final conversationHistory = _buildConversationHistory(history);

    conversationHistory.add(<String, dynamic>{
      'role': 'user',
      'parts': <Map<String, dynamic>>[
        <String, dynamic>{'text': message}
      ]
    });

    try {
      final response = await _dio.post(
        _baseUrl,
        data: <String, dynamic>{
          'contents': conversationHistory,
          'generationConfig': <String, dynamic>{
            'temperature': 0.7,
            'topP': 0.8,
            'topK': 40,
            'maxOutputTokens': 4096,
          }
        },
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-goog-api-key': _apiKey
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data as ResponseBody;
      String buffer = '';
      List<int> byteBuffer = [];

      await for (final chunk in stream.stream) {
        try {
          byteBuffer.addAll(chunk);

          String chunkString;
          try {
            chunkString = utf8.decode(byteBuffer);
            byteBuffer.clear();
          } catch (e) {
            continue;
          }

          buffer += chunkString;

          while (true) {
            int startIndex = buffer.indexOf('{');
            if (startIndex == -1) break;

            int braceCount = 0;
            int endIndex = -1;
            bool inString = false;
            bool escaped = false;

            for (int i = startIndex; i < buffer.length; i++) {
              final char = buffer[i];

              if (escaped) {
                escaped = false;
                continue;
              }

              if (char == '\\' && inString) {
                escaped = true;
                continue;
              }

              if (char == '"') {
                inString = !inString;
                continue;
              }

              if (!inString) {
                if (char == '{') {
                  braceCount++;
                } else if (char == '}') {
                  braceCount--;
                  if (braceCount == 0) {
                    endIndex = i;
                    break;
                  }
                }
              }
            }

            if (endIndex == -1) {
              break;
            }

            final jsonString = buffer.substring(startIndex, endIndex + 1);
            buffer = buffer.substring(endIndex + 1);

            try {
              final jsonData = json.decode(jsonString);

              if (jsonData['error'] != null) {
                final errorMessage =
                    jsonData['error']['message'] ?? 'Unknown error occurred';
                yield* Stream.error('API Error: $errorMessage');
                return;
              }

              if (jsonData['candidates'] != null &&
                  jsonData['candidates'].isNotEmpty) {
                final candidate = jsonData['candidates'][0];

                final finishReason = candidate['finishReason'];
                if (finishReason == 'SAFETY') {
                  yield* Stream.error(
                      'Content was filtered due to safety policies');
                  return;
                } else if (finishReason == 'MAX_TOKENS') {
                } else if (finishReason == 'STOP') {
                } else if (finishReason != null) {}

                if (candidate['content'] != null &&
                    candidate['content']['parts'] != null &&
                    candidate['content']['parts'].isNotEmpty) {
                  final text =
                      candidate['content']['parts'][0]['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
              }
            } catch (e) {
              // print the error if needed
            }
          }
        } catch (e) {
          //
        }
      }
    } catch (e) {
      yield* Stream.error('Failed to connect to Gemini API: $e');
    }
  }

  Future<String?> sendMessage(String message, List<ChatMessage> history) async {
    try {
      final responseChunks = <String>[];
      await for (final chunk in sendMessageStream(message, history)) {
        responseChunks.add(chunk);
      }
      return responseChunks.join('');
    } catch (e) {
      return null;
    }
  }

  Future<CounselingResponse?> sendCounselingMessage(String userFeeling) async {
    final counselingPrompt = """
You are a compassionate Islamic counselor. A user has shared their feelings: "$userFeeling".
Provide a response in the following JSON format ONLY:
{
  "counseling_text": "A comforting message based on Islamic teachings in the same language as the user's feeling",
  "ayah": "Relevant Quranic Ayah in Arabic",
  "ayah_translation": "Translation of the Ayah in the same language as the user's feeling. IMPORTANT: If the user's feeling is in Arabic, leave this field empty.",
  "ayah_reference": "Surah Name: Verse Number",
  "duaa": "A relevant Duaa in Arabic",
  "duaa_translation": "Translation of the Duaa in the same language as the user's feeling. IMPORTANT: If the user's feeling is in Arabic, leave this field empty."
}
Ensure the tone is empathetic, supportive, and rooted in Islamic wisdom.
""";

    final conversation = [
      {
        'role': 'user',
        'parts': [
          {'text': counselingPrompt}
        ]
      }
    ];

    try {
      final response = await _dio.post(
        _baseUrl.replaceFirst('streamGenerateContent', 'generateContent'),
        data: {
          'contents': conversation,
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.8,
            'topK': 40,
            'maxOutputTokens': 4096,
            'responseMimeType': 'application/json',
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-goog-api-key': _apiKey
          },
        ),
      );


      if (response.data is Map<String, dynamic> &&
          response.data['candidates'] != null &&
          (response.data['candidates'] as List).isNotEmpty) {
        final candidate = response.data['candidates'][0];
        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            (candidate['content']['parts'] as List).isNotEmpty) {
          final text = candidate['content']['parts'][0]['text'] as String?;
          if (text != null) {
            String cleanText =
                text.replaceAll('```json', '').replaceAll('```', '').trim();
            try {
              final jsonResponse = json.decode(cleanText);
              if (jsonResponse is Map<String, dynamic>) {
                return CounselingResponse.fromJson(jsonResponse);
              } else if (jsonResponse is List &&
                  jsonResponse.isNotEmpty &&
                  jsonResponse.first is Map<String, dynamic>) {
                return CounselingResponse.fromJson(
                    jsonResponse.first as Map<String, dynamic>);
              }
            } catch (e) {
              // 
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
