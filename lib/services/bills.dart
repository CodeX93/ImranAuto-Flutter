import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BillService {
  final String apiUrl = 'http://localhost:3000';

  Future<List<Bill>> getBills() async {
    final response = await http.get(Uri.parse('$apiUrl/bills'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => Bill.fromJson(bill)).toList();
    } else {
      throw Exception('Failed to load bills');
    }
  }

  void reduceItemsQuantity(List<BillItem> items) async {
    for (var item in items) {
      final response = await http.put(
        Uri.parse('$apiUrl/items/${item.itemId}/quantity'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': item.quantity}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reduce item quantity');
      }
    }
  }

  Future<void> addBill(Bill bill) async {
    final response = await http.post(
      Uri.parse('$apiUrl/bills'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add bill');
    }
  }

  Future<void> updateBill(String id, Bill bill) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.put(
      Uri.parse('$apiUrl/bills/$id'),
      headers: {'Content-Type': 'application/json',
        'Authorization': '${prefs.get('token')}'
      },
      body: json.encode(bill.toJson()),
    );
    if (response.statusCode != 200) {
      print('error ${response.body}');
      throw Exception('Failed to update bill');
    }
  }

  Future<void> deleteBill(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/bills/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bill');
    }
  }

  Future<List<Customer>> getCustomers() async {
    final response = await http.get(Uri.parse('$apiUrl/customers'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((customer) => Customer.fromJson(customer)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    final response = await http.get(Uri.parse('$apiUrl/customers/$id'));
    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load customer');
    }
  }

  Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse('$apiUrl/items'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Item.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> updateCustomerBalance(String customerId, double newBalance) async {
    final response = await http.put(
      Uri.parse('$apiUrl/customers/$customerId/balance'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'balance': newBalance}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer balance');
    }
  }

  Future<List<Bill>> getBillsByCustomerId(String customerId) async {
    final response = await http.get(Uri.parse('$apiUrl/customers/$customerId/bills'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((bill) => Bill.fromJson(bill)).toList();
    } else {
      print(response.body);
      print(response.statusCode);
      throw Exception('Failed to load bills for customer');
    }
  }

  Future<List<BillItem>> getItemRatesById(String itemId) async {
    final response = await http.get(Uri.parse('$apiUrl/items/$itemId/rates'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print(data);
      return data.map((item) => BillItem.fromJson(item)).toList().reversed.toList();
    } else {
      throw Exception('Failed to load item rates');
    }
  }
}
