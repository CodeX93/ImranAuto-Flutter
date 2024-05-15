import 'package:flutter/material.dart';

class AddItemPage extends StatelessWidget {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _availableQuantityController = TextEditingController();
  final TextEditingController _nameInUrduController = TextEditingController();
  final TextEditingController _miniUnitController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();
  final TextEditingController _purchaseRateController = TextEditingController();
  final TextEditingController _saleRateController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _addedEditDateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pictureController = TextEditingController();

  void _addItem(BuildContext context) {
    // Get values from text controllers
    String id = _idController.text;
    String name = _nameController.text;
    String brand = _brandController.text;
    int availableQuantity = int.tryParse(_availableQuantityController.text) ?? 0;
    String nameInUrdu = _nameInUrduController.text;
    String miniUnit = _miniUnitController.text;
    String packaging = _packagingController.text;
    double purchaseRate = double.tryParse(_purchaseRateController.text) ?? 0.0;
    double saleRate = double.tryParse(_saleRateController.text) ?? 0.0;
    int minStock = int.tryParse(_minStockController.text) ?? 0;
    String addedEditDate = _addedEditDateController.text;
    String location = _locationController.text;
    String picture = _pictureController.text;

    // Add item to database or perform other actions
    // For demonstration purposes, print the values
    print('ID: $id');
    print('Name: $name');
    print('Brand: $brand');
    print('Available Quantity: $availableQuantity');
    print('Name in Urdu: $nameInUrdu');
    print('Mini Unit: $miniUnit');
    print('Packaging: $packaging');
    print('Purchase Rate: $purchaseRate');
    print('Sale Rate: $saleRate');
    print('Min Stock: $minStock');
    print('Added/Edit Date: $addedEditDate');
    print('Location: $location');
    print('Picture: $picture');

    // You can also navigate back to the previous screen after adding the item
    Navigator.pop(context); // Pop the current route (AddItemPage) off the navigation stack
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Add New Item'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _idController,
            decoration: InputDecoration(labelText: 'ID'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _brandController,
            decoration: InputDecoration(labelText: 'Brand'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _availableQuantityController,
            decoration: InputDecoration(labelText: 'Available Quantity'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _nameInUrduController,
            decoration: InputDecoration(labelText: 'Name in Urdu'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _miniUnitController,
            decoration: InputDecoration(labelText: 'Mini Unit'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _packagingController,
            decoration: InputDecoration(labelText: 'Packaging'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _purchaseRateController,
            decoration: InputDecoration(labelText: 'Purchase Rate'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _saleRateController,
            decoration: InputDecoration(labelText: 'Sale Rate'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _minStockController,
            decoration: InputDecoration(labelText: 'Min Stock'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _addedEditDateController,
            decoration: InputDecoration(labelText: 'Added/Edit Date'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Location'),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _pictureController,
            decoration: InputDecoration(labelText: 'Picture'),
          ),
          SizedBox(height: 32.0),
          ElevatedButton(
            onPressed: () => _addItem(context),
            child: Text('Add Item'),
          ),
        ],
      ),
    ),
  );
}

}
