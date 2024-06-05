import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:namer_app/models/item.dart';

class ItemService {
  final String baseUrl = '${dotenv.env['BACKEND_URL']!}/items';

  Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> itemsJson = json.decode(response.body);
      return itemsJson.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> addItem(Item item) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add item');
    }
  }

  Future<void> updateItem(String id, Item item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  Future<void> deleteItem(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }
}
