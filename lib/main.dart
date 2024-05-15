import 'package:flutter/material.dart';
import './screens/itemmanagement.dart'; // Import the ItemManagementPage
import './screens/add_item_page.dart'; // Import the AddItemPage

class ItemManagementPage extends StatefulWidget {
  @override
  _ItemManagementPageState createState() => _ItemManagementPageState();
}

class _ItemManagementPageState extends State<ItemManagementPage> {
  List<Map<String, dynamic>> _items = [
    {
      'id': 1,
      'name': 'Product A',
      'brand': 'Brand X',
      'availableQuantity': 10,
    },
    {
      'id': 2,
      'name': 'Product B',
      'brand': 'Brand Y',
      'availableQuantity': 20,
    },
    // Add more items as needed
  ]; // Replace this with actual data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Management'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to AddItemPage when the button is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddItemPage()),
                  );
                },
                child: Text('Add New Item'),
              ),
            ),
            DataTable(
              columns: [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Brand')),
                DataColumn(label: Text('Available Quantity')),
                DataColumn(label: Text('Action')),
              ],
              rows: _items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item['id'].toString())),
                        DataCell(Text(item['name'])),
                        DataCell(Text(item['brand'])),
                        DataCell(Text(item['availableQuantity'].toString())),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              // Implement action when button is pressed
                            },
                            child: Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Application 1',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to ItemManagementPage when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ItemManagementPage()),
            );
          },
          child: Text('Go to Item Management Page'),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
