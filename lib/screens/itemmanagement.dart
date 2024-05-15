import 'package:flutter/material.dart';
import 'add_item_page.dart'; // Import the AddItemPage

class ItemManagementPage extends StatefulWidget {
  @override
  ItemManagementPageState createState() => ItemManagementPageState();
}

class ItemManagementPageState extends State<ItemManagementPage> {
  List<Map<String, dynamic>> _items = []; // Replace this with actual data

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
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddItemPage()),
                              );
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
