import 'package:flutter/material.dart';
import 'package:namer_app/models/item.dart'; // Ensure this matches the path to your Item model
import 'package:namer_app/services/items.dart'; // Ensure this matches the path to your Item service
import 'package:namer_app/theme/theme.dart';

import '../components/input_field.dart'; // Ensure this matches the path to your theme

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemService _itemService = ItemService();
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final items = await _itemService.getItems();
    setState(() {
      _items = items;
      _filteredItems = items;
      _isLoading = false;
    });
  }

  void _showAddEditItemDialog({Item? item}) {
    showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(
        item: item,
        onItemSaved: _fetchItems,
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await _itemService.deleteItem(id);
    _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: AppTheme.inputDecoration('Search items...'),
              onChanged: (value) {
                setState(() {
                  _filteredItems = _items.where((item) {
                    return item.name.toLowerCase().contains(value.toLowerCase()) ||
                        item.brand.toLowerCase().contains(value.toLowerCase());
                  }).toList();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Brand: ${item.brand}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditItemDialog(item: item),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditItemDialog extends StatefulWidget {
  final Item? item;
  final VoidCallback onItemSaved;

  const AddEditItemDialog({Key? key, this.item, required this.onItemSaved}) : super(key: key);

  @override
  _AddEditItemDialogState createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchaseRateController = TextEditingController();
  final TextEditingController _saleRateController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final ItemService _itemService = ItemService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _brandController.text = widget.item!.brand;
      _quantityController.text = widget.item!.availableQuantity.toString();
      _purchaseRateController.text = widget.item!.purchaseRate.toString();
      _saleRateController.text = widget.item!.saleRate.toString();
      _minStockController.text = widget.item!.minStock.toString();
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final brand = _brandController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final purchaseRate = double.tryParse(_purchaseRateController.text) ?? 0;
    final saleRate = double.tryParse(_saleRateController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;

    if (widget.item == null) {
      await _itemService.addItem(Item(
        id: '', // Placeholder, ID will be generated by backend
        name: name,
        brand: brand,
        availableQuantity: quantity,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: DateTime.now(),
      ));
    } else {
      await _itemService.updateItem(widget.item!.id, Item(
        id: widget.item!.id,
        name: name,
        brand: brand,
        availableQuantity: quantity,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: widget.item!.addedEditDate,
      ));
    }

    setState(() {
      _isLoading = false;
    });

    widget.onItemSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.item == null ? 'Add Item' : 'Edit Item', style: AppTheme.headline6),
            SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'Item Name',
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _brandController,
              label: 'Brand',
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _quantityController,
              label: 'Available Quantity',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _purchaseRateController,
              label: 'Purchase Rate',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _saleRateController,
              label: 'Sale Rate',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _minStockController,
              label: 'Min Stock',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleSave,
              style: AppTheme.elevatedButtonStyle,
              child: Text('Save', style: AppTheme.button),
            ),
          ],
        ),
      ),
    );
  }
}
