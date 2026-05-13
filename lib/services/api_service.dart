import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.2:5000';

  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
      if (data['name'] != null) await prefs.setString('name', data['name']);
      if (data['email'] != null) await prefs.setString('email', data['email']);
      if (data['phone'] != null) await prefs.setString('phone', data['phone']);
      if (data['profileImage'] != null) {
        await prefs.setString('profileImage', data['profileImage']);
      }
      return null;
    }

    return data['message'] ?? 'Login failed';
  }

  static Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendOtp(String phone, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'email': email,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> resetPassword(
    String email,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getAnimals(
    String category, [
    String search = '',
    String adType = 'all',
  ]) async {
    try {
      final uri = Uri.parse('$baseUrl/api/animals').replace(
        queryParameters: {
          'category': category,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (adType != 'all') 'adType': adType,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<String?> getCurrentUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImage');
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['name'] != null) await prefs.setString('name', data['name']);
      if (data['email'] != null) await prefs.setString('email', data['email']);
      if (data['phone'] != null) await prefs.setString('phone', data['phone']);
      if (data['role'] != null) await prefs.setString('role', data['role']);
      if (data['profileImage'] != null) {
        await prefs.setString('profileImage', data['profileImage']);
      }
      return data;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getPublicUserProfile(
      String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String name,
    required String phone,
    File? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/auth/me'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['phone'] = phone;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', image.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['name'] != null) await prefs.setString('name', data['name']);
      if (data['phone'] != null) await prefs.setString('phone', data['phone']);
      if (data['email'] != null) await prefs.setString('email', data['email']);
      if (data['role'] != null) await prefs.setString('role', data['role']);
      if (data['profileImage'] != null) {
        await prefs.setString('profileImage', data['profileImage']);
      }
      return data;
    }

    return null;
  }

  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('profileImage');
  }

  static Future<bool> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await clearLocalSession();
      return true;
    }

    return false;
  }

  static Future<List<dynamic>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<void> markNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    await http.patch(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    await http.delete(
      Uri.parse('$baseUrl/api/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<String?> sendChatbotMessage({
    String? text,
    File? image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://maribeth-complimentary-denita.ngrok-free.dev/interact'),
      );

      if (text != null && text.trim().isNotEmpty) {
        request.fields['message'] = text.trim();
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['reply']?.toString() ?? '';
      }

      return 'Chatbot is unavailable right now.';
    } catch (_) {
      return 'Could not reach the chatbot service.';
    }
  }

  static Future<List<dynamic>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> deleteConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> getMyPets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/pets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<Map<String, dynamic>?> getPetDetails(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/pets/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> markPetMealDone(String id, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/pets/$id/meal-done'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'label': label}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> markPetVaccineDone(
    String id,
    String label, {
    String nextVaccineDate = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/pets/$id/vaccine-done'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'label': label,
        'nextVaccineDate': nextVaccineDate,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> addPet({
    required String name,
    required String type,
    String breed = '',
    String age = '',
    String weight = '',
    String gender = 'unknown',
    int mealsPerDay = 1,
    List<String> foodReminderTimes = const [],
    String vaccineReminderDate = '',
    String notes = '',
    File? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/pets'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['breed'] = breed;
    request.fields['age'] = age;
    request.fields['weight'] = weight;
    request.fields['gender'] = gender;
    request.fields['mealsPerDay'] = mealsPerDay.toString();
    request.fields['foodReminderTimes'] = jsonEncode(foodReminderTimes);
    request.fields['vaccineReminderDate'] = vaccineReminderDate;
    request.fields['notes'] = notes;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 201;
  }

  static Future<bool> updatePet({
    required String id,
    required String name,
    required String type,
    String breed = '',
    String age = '',
    String weight = '',
    String gender = 'unknown',
    int mealsPerDay = 1,
    List<String> foodReminderTimes = const [],
    String vaccineReminderDate = '',
    String notes = '',
    File? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/pets/$id'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['breed'] = breed;
    request.fields['age'] = age;
    request.fields['weight'] = weight;
    request.fields['gender'] = gender;
    request.fields['mealsPerDay'] = mealsPerDay.toString();
    request.fields['foodReminderTimes'] = jsonEncode(foodReminderTimes);
    request.fields['vaccineReminderDate'] = vaccineReminderDate;
    request.fields['notes'] = notes;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    return streamedResponse.statusCode == 200;
  }

  static Future<bool> deletePet(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/pets/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<bool?> toggleFavorite(String adId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/$adId/favorite'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isFavorite'];
    }

    return null;
  }

  static Future<bool> reportAd(String adId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/$adId/report'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> startConversation(String adId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'adId': adId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<Map<String, dynamic>?> sendMessage(
    String conversationId,
    String text, {
    File? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/messages'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['text'] = text;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/api/chat/conversations/$conversationId/messages/$messageId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> editMessage(
    String conversationId,
    String messageId,
    String text,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/api/chat/conversations/$conversationId/messages/$messageId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> blockUserInConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/block'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<bool> unblockUserInConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/unblock'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<bool> reportUserInConversation(
    String conversationId,
    String reason,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/report-user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> rateUserInConversation(
    String conversationId, {
    required int score,
    String comment = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/conversations/$conversationId/rate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'score': score,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<Map<String, dynamic>> getUserRatings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'average': 0.0, 'count': 0, 'ratings': []};
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/ratings/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {'average': 0.0, 'count': 0, 'ratings': []};
  }

  static Future<Map<String, dynamic>> getMyRatingSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'average': 0.0, 'count': 0, 'ratings': []};
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/ratings/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {'average': 0.0, 'count': 0, 'ratings': []};
  }

  static Future<List<dynamic>> getMyAds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<List<dynamic>> getPendingAds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/api/ads/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<void> approveAd(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.put(
      Uri.parse('$baseUrl/api/ads/$id/approve'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<void> rejectAd(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.put(
      Uri.parse('$baseUrl/api/ads/$id/reject'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<bool> addAd({
    required String name,
    required String description,
    String? price,
    required String category,
    required List<File> images,
    required File idCard,
    bool isAdoption = false,
    String? age,
    bool? vaccinated,
    String? healthStatus,
    String? location,
  }) async {
    final uri = Uri.parse('$baseUrl/api/ads');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('NO TOKEN FOUND');
      return false;
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['isAdoption'] = isAdoption.toString();

    if (price != null) {
      request.fields['price'] = price;
    }

    if (age != null) request.fields['age'] = age;
    if (vaccinated != null) {
      request.fields['vaccinated'] = vaccinated.toString();
    }
    if (healthStatus != null) request.fields['healthStatus'] = healthStatus;
    if (location != null) request.fields['location'] = location;

    for (final img in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', img.path),
      );
    }

    request.files.add(
      await http.MultipartFile.fromPath('idCard', idCard.path),
    );

    final response = await request.send();
    print('ADD AD STATUS: ${response.statusCode}');

    return response.statusCode == 201;
  }

  static Future<bool> updateAd({
    required String id,
    required String name,
    required String description,
    String? price,
    required String category,
    required List existingImages,
    required List<File> newImages,
    bool? isAdoption,
    String? age,
    bool? vaccinated,
    String? healthStatus,
    String? location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/ads/$id'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['existingImages'] = jsonEncode(existingImages);

    if (price != null) {
      request.fields['price'] = price;
    }

    if (isAdoption != null) {
      request.fields['isAdoption'] = isAdoption.toString();
    }

    if (age != null) request.fields['age'] = age;
    if (vaccinated != null) {
      request.fields['vaccinated'] = vaccinated.toString();
    }
    if (healthStatus != null) request.fields['healthStatus'] = healthStatus;
    if (location != null) request.fields['location'] = location;

    for (final img in newImages) {
      request.files.add(
        await http.MultipartFile.fromPath('images', img.path),
      );
    }

    final response = await request.send();
    print('UPDATE AD STATUS: ${response.statusCode}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteAd(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/ads/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> markAdUnavailable(String id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/ads/$id/availability'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getAdStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/api/ads/stats'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {};
  }

  static Future<List<dynamic>> getApprovedAds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/api/ads/approved'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<List> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<List<dynamic>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> getAdminReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return {'adReports': [], 'userReports': []};

    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/reports'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return {'adReports': [], 'userReports': []};
  }

  static Future<bool> reviewAdReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/reports/ads/$reportId/review'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 200;
  }

  static Future<bool> reviewUserReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/reports/users/$reportId/review'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 200;
  }

  static Future<bool> toggleBan(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$userId/ban'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 200;
  }

  static Future<bool> changeRole(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$userId/role'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'role': role}),
    );

    return res.statusCode == 200;
  }
}
