import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/models/bills.dart';
import 'package:namer_app/models/customer.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/services/bills.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillsPage extends StatefulWidget {
  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final BillService _billService = BillService();
  List<Bill> _bills = [];
  bool _isLoading = true;
  Map<String, Customer> _customers = {};
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchRole();
    _fetchBills();
  }

  Future<void> _fetchRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role');
    });
  }

  Future<void> _fetchBills() async {
    final bills = await _billService.getBills();
    for (var bill in bills) {
      final customer = await _billService.getCustomerById(bill.customerId);
      _customers[bill.customerId] = customer;
    }
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
  }

  void _showAddEditBillDialog({Bill? bill}) {
    showDialog(
      context: context,
      builder: (context) => AddEditBillDialog(
        bill: bill,
        onBillSaved: _fetchBills,
      ),
    );
  }

  Future<void> _deleteBill(String id) async {
    await _billService.deleteBill(id);
    _fetchBills();
  }

  void _showBillItems(Bill bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Items for Bill ID: ${bill.id}'),
        content: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Sale Rate')),
              DataColumn(label: Text('Total')),
            ],
            rows: bill.items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.name)),
                  DataCell(Text(item.quantity.toString())),
                  DataCell(Text('\$${item.saleRate.toStringAsFixed(2)}')),
                  DataCell(Text('\$${item.total.toStringAsFixed(2)}')),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(Bill bill) async {
    if (_role == 'admin') {
      setState(() {
        bill.status = bill.status == 'Completed' ? 'Non Completed' : 'Completed';
      });
      await _billService.updateBill(bill.id, bill);
      _fetchBills();
    }
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
              decoration: AppTheme.inputDecoration('Search bills...'),
              onChanged: (value) {
                // Implement search logic here
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Bill ID')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Total Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _bills.map((bill) {
                  final customer = _customers[bill.customerId];
                  final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));
                  return DataRow(
                    cells: [
                      DataCell(Text(bill.id)),
                      DataCell(Text(customer != null ? customer.name : '')),
                      DataCell(Text('\$${bill.totalAmount.toStringAsFixed(2)}')),
                      DataCell(
                        GestureDetector(
                          onTap: () => _toggleStatus(bill),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: bill.status == 'Completed' ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bill.status,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(formattedDate)),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditBillDialog(bill: bill),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBill(bill.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.list, color: Colors.green),
                            onPressed: () => _showBillItems(bill),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBillDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditBillDialog extends StatefulWidget {
  final Bill? bill;
  final VoidCallback onBillSaved;

  const AddEditBillDialog({Key? key, this.bill, required this.onBillSaved}) : super(key: key);

  @override
  _AddEditBillDialogState createState() => _AddEditBillDialogState();
}

class _AddEditBillDialogState extends State<AddEditBillDialog> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final BillService _billService = BillService();
  bool _isLoading = false;

  List<Customer> _customers = [];
  List<Item> _items = [];
  List<Bill> _previousBills = [];
  Map<String, List<BillItem>> _itemPreviousRates = {};
  String? _selectedCustomerId;
  Customer? _selectedCustomer;
  List<BillItem> _selectedItems = [];
  String _selectedStatus = 'Non Completed';
  double _totalAmount = 0;
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchRole();
    _fetchItems();
    _fetchCustomers();
    if (widget.bill != null) {
      _selectedCustomerId = widget.bill!.customerId;
      _dateController.text = widget.bill!.date;
      _selectedItems = widget.bill!.items;
      _totalAmountController.text = widget.bill!.totalAmount.toString();
      _selectedStatus = widget.bill!.status;
      _calculateTotalAmount();
      _fetchCustomerDetails();
    }
  }

  Future<void> _fetchRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role');
    });
  }

  Future<void> _fetchCustomers() async {
    final customers = await _billService.getCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<void> _fetchItems() async {
    final items = await _billService.getItems();
    setState(() {
      _items = items;
    });
  }

  Future<void> _fetchCustomerDetails() async {
    if (_selectedCustomerId != null) {
      final customer = await _billService.getCustomerById(_selectedCustomerId!);
      final previousBills = await _billService.getBillsByCustomerId(_selectedCustomerId!);
      setState(() {
        _selectedCustomer = customer;
        _previousBills = previousBills.take(5).toList(); // Get only the recent 5 bills
        _balanceController.text = customer.balance.toString();
      });
    }
  }

  Future<void> _fetchItemPreviousRates(String itemId) async {
    final itemRates = await _billService.getItemRatesById(itemId);
    setState(() {
      _itemPreviousRates[itemId] = itemRates;
    });
  }

  void _addItemToBill(Item item) async {
    if (item.availableQuantity > 0) {
      await _fetchItemPreviousRates(item.id);
      setState(() {
        _selectedItems.add(BillItem(
          itemId: item.id,
          name: item.name,
          quantity: 1,
          saleRate: item.saleRate,
          purchaseRate: item.purchaseRate,
          total: item.saleRate,
        ));
        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected item is out of stock')),
      );
    }
  }

  void _removeItemFromBill(BillItem item) {
    setState(() {
      _selectedItems.remove(item);
      _calculateTotalAmount();
    });
  }

  void _updateItemQuantity(BillItem item, int quantity) {
    if (quantity <= _items.firstWhere((i) => i.id == item.itemId).availableQuantity) {
      setState(() {
        item.quantity = quantity;
        item.total = item.saleRate * quantity;
        _calculateTotalAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity exceeds available stock')),
      );
    }
  }

  void _updateItemRateForBill(BillItem item, double saleRate) {
    setState(() {
      item.saleRate = saleRate;
      item.total = item.saleRate * item.quantity;
      _calculateTotalAmount();
    });
  }

  void _calculateTotalAmount() {
    double total = 0;
    for (var item in _selectedItems) {
      total += item.total;
    }
    setState(() {
      _totalAmount = total;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final date = _dateController.text;

    if (widget.bill == null) {
      await _billService.addBill(Bill(
        id: '',
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        status: _selectedStatus,
      ));
    } else {
      await _billService.updateBill(widget.bill!.id, Bill(
        id: widget.bill!.id,
        customerId: _selectedCustomerId!,
        date: date,
        items: _selectedItems,
        totalAmount: _totalAmount,
        status: _selectedStatus,
      ));
    }

    await _billService.updateCustomerBalance(_selectedCustomerId!, _selectedCustomer!.balance + _totalAmount);

    setState(() {
      _isLoading = false;
    });

    widget.onBillSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      child: Container(
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.bill == null ? 'Add Bill' : 'Edit Bill', style: AppTheme.headline6),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 400,
                          child: TypeAheadFormField<Customer>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _customerController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Customer',
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              return _customers.where((customer) => customer.name.toLowerCase().contains(pattern.toLowerCase()) || customer.id.contains(pattern));
                            },
                            itemBuilder: (context, Customer suggestion) {
                              return ListTile(
                                title: Text(suggestion.name),
                                subtitle: Text(suggestion.id),
                              );
                            },
                            onSuggestionSelected: (Customer suggestion) {
                              setState(() {
                                _selectedCustomerId = suggestion.id;
                                _selectedCustomer = suggestion;
                                _customerController.text = "${suggestion.id} - ${suggestion.name}";
                                _balanceController.text = suggestion.balance.toString();
                                _fetchCustomerDetails();
                              });
                            },
                            noItemsFoundBuilder: (context) => Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No customers found.'),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _balanceController,
                          readOnly: true,
                          label: 'Balance',
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Date',
                          ),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        TypeAheadFormField<Item>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: _itemController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Items',
                            ),
                          ),
                          suggestionsCallback: (pattern) {
                            return _items.where((item) => item.name.toLowerCase().contains(pattern.toLowerCase()));
                          },
                          itemBuilder: (context, Item suggestion) {
                            return ListTile(
                              title: Text(suggestion.name),
                            );
                          },
                          onSuggestionSelected: (Item suggestion) {
                            _addItemToBill(suggestion);
                            _itemController.clear();
                          },
                          noItemsFoundBuilder: (context) => Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No items found.'),
                          ),
                        ),
                        SizedBox(height: 16),
                        Column(
                          children: _selectedItems.map((item) {
                            return SizedBox(
                              width: 400,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  if (_itemPreviousRates.containsKey(item.itemId)) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Previous Rates:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    for (var rate in _itemPreviousRates[item.itemId]!.take(5)) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Customer: ${rate.customerName}'),
                                          Text('Sale: \$${rate.saleRate.toStringAsFixed(2)}'),
                                          Text('Purchase: \$${rate.purchaseRate.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ],
                                  ],
                                  SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: TextEditingController(text: item.quantity.toString()),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Qty',
                                          ),
                                          onChanged: (value) {
                                            int? quantity = int.tryParse(value);
                                            if (quantity != null && quantity > 0) {
                                              _updateItemQuantity(item, quantity);
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: TextEditingController(text: item.saleRate.toStringAsFixed(2)),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Sale Rate',
                                          ),
                                          onChanged: (value) {
                                            double? saleRate = double.tryParse(value);
                                            if (saleRate != null && saleRate > 0) {
                                              _updateItemRateForBill(item, saleRate);
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: TextEditingController(text: item.purchaseRate.toStringAsFixed(2)),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Purchase Rate',
                                          ),
                                          onChanged: (value) {
                                            double? purchaseRate = double.tryParse(value);
                                            if (purchaseRate != null && purchaseRate > 0) {
                                              _updateItemRateForBill(item, item.saleRate);
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeItemFromBill(item),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _totalAmountController,
                          label: 'Total Amount',
                          keyboardType: TextInputType.number,
                          readOnly: true,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          hint: Text('Select Status'),
                          onChanged: (value) {
                            if (_role == 'admin') {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            }else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('You are not authorized to change the status')),
                              );
                            }
                          },
                          items: ['Completed', 'Non Completed'].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Status',
                          ),
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
                  SizedBox(width: 16),
                  if (_selectedCustomer != null) ...[
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer Details', style: AppTheme.headline6),
                              SizedBox(height: 8),
                              Table(
                                children: [
                                  TableRow(children: [
                                    Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Tour', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  TableRow(children: [
                                    Text(_selectedCustomer!.name),
                                    Text(_selectedCustomer!.phoneNumber),
                                    Text(_selectedCustomer!.address),
                                    Text(_selectedCustomer!.tour),
                                    Text('\$${_selectedCustomer!.balance.toStringAsFixed(2)}'),
                                  ]),
                                ],
                              ),
                              if (_previousBills.isNotEmpty) ...[
                                SizedBox(height: 16),
                                Text('Previous Bills', style: AppTheme.headline6),
                                SizedBox(height: 8),
                                Table(
                                  children: [
                                    TableRow(children: [
                                      Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ]),
                                    for (var bill in _previousBills) ...[
                                      TableRow(children: [
                                        Text(DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date))),
                                        Text('\$${bill.totalAmount.toStringAsFixed(2)}'),
                                        Text(bill.status),
                                      ]),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
