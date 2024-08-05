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

import 'item_selection_dialog.dart';


class BillsDataSource extends DataTableSource {
  final List<Bill> bills;
  final Map<String, Customer> customers;
  final void Function(Bill) onEdit;
  final void Function(String) onDelete;
  final void Function(Bill) toggleStatus;
  final void Function(Bill) showBillItems;
  final BuildContext context;
  List<Bill> filteredBills;

  BillsDataSource({
    required this.bills,
    required this.customers,
    required this.onEdit,
    required this.onDelete,
    required this.toggleStatus,
    required this.showBillItems,
    required this.context,
  }) : filteredBills = List.from(bills);

  void filterBills(String query) {
    final lowerQuery = query.toLowerCase();
    filteredBills
      ..clear()
      ..addAll(bills.where((bill) {
        final customer = customers[bill.customerId];
        final customerName = customer?.name.toLowerCase() ?? '';
        final itemNames = bill.items.map((item) => item.name.toLowerCase()).join(' ');
        final totalAmount = bill.totalAmount.toString();
        return customerName.contains(lowerQuery) ||
            itemNames.contains(lowerQuery) ||
            totalAmount.contains(lowerQuery);
      }));
    notifyListeners();
  }

  void sortBills<T>(Comparable<T> Function(Bill bill) getField, bool ascending) {
    filteredBills.sort((a, b) {
      if (!ascending) {
        final Bill c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final bill = filteredBills[index];
    final customer = customers[bill.customerId];
    final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bill.date));
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text((index + 1).toString())),
        DataCell(Text(bill.id)),
        DataCell(Text(customer != null ? customer.name : '')),
        DataCell(Text('\$${bill.totalAmount.toStringAsFixed(2)}')),
        DataCell(
          GestureDetector(
            onTap: () => toggleStatus(bill),
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
              onPressed: () => onEdit(bill),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(bill.id),
            ),
            IconButton(
              icon: Icon(Icons.list, color: Colors.green),
              onPressed: () => showBillItems(bill),
            ),
          ],
        )),
      ],
    );
  }

  @override
  int get rowCount => filteredBills.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class BillsPage extends StatefulWidget {
  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final BillService _billService = BillService();
  List<Bill> _bills = [];
  BillsDataSource? _dataSource;
  bool _isLoading = true;
  Map<String, Customer> _customers = {};
  String? _role;
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

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
      _dataSource = BillsDataSource(
        bills: _bills,
        customers: _customers,
        onEdit: _showAddEditBillDialog,
        onDelete: _deleteBill,
        toggleStatus: _toggleStatus,
        showBillItems: _showBillItems,
        context: context,
      );
      _isLoading = false;
    });
  }

  void _showAddEditBillDialog([Bill? bill]) {
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

  void _onSearch(String query) {
    setState(() {
      _dataSource?.filterBills(query);
    });
  }

  void _onSort<T>(Comparable<T> Function(Bill bill) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortBills(getField, ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
              color: Colors.white,
            ),
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text('Bills List', style: AppTheme.headline6),
                  Spacer(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchBills,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns: [
                DataColumn(
                  label: Text('S.No'),
                  onSort: (columnIndex, ascending) => _onSort<num>((bill) => _dataSource!.filteredBills.indexOf(bill) + 1, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Bill ID'),
                  onSort: (columnIndex, ascending) => _onSort<String>((bill) => bill.id, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Customer Name'),
                  onSort: (columnIndex, ascending) => _onSort<String>((bill) => _customers[bill.customerId]?.name ?? '', columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Total Amount'),
                  onSort: (columnIndex, ascending) => _onSort<num>((bill) => bill.totalAmount, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Status'),
                  onSort: (columnIndex, ascending) => _onSort<String>((bill) => bill.status, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Date'),
                  onSort: (columnIndex, ascending) => _onSort<DateTime>((bill) => DateTime.parse(bill.date), columnIndex, ascending),
                ),
                DataColumn(label: Text('Actions')),
              ],
              source: _dataSource!,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value!;
                });
              },
              availableRowsPerPage: [5, 10, 20, 30],
              columnSpacing: 20,
              horizontalMargin: 20,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
            ),
          ),
        ),
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
      for (var item in _selectedItems) {
        _fetchItemPreviousRates(item.itemId);
      }
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
        // Check if the item already exists in the selected items
        BillItem? existingItem;
        for (var selectedItem in _selectedItems) {
          if (selectedItem.itemId == item.id) {
            existingItem = selectedItem;
            break;
          }
        }

        if (existingItem != null) {
          existingItem.quantity++;
          existingItem.total = existingItem.saleRate * existingItem.quantity;
        } else {
          _selectedItems.add(BillItem(
            itemId: item.id,
            name: item.name,
            quantity: 1,
            saleRate: item.saleRate,
            purchaseRate: item.purchaseRate,
            total: item.saleRate,
          ));
        }

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

  void _showItemSelectionDialog() async {
    final items = await _billService.getItems(); // Fetch items from your service
    showDialog(
      context: context,
      builder: (context) => ItemSelectionDialog(
        items: items,
        onItemsSelected: (selectedItems) {
          for (var item in selectedItems) {
            _addItemToBill(item);
          }
        },
      ),
    );
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
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue,
                  ),
                  alignment: Alignment.center,
                  width: double.infinity,
                  child: Text(widget.bill == null ? 'Add Bill' : 'Edit Bill', style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ))),
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
                        SizedBox(
                          width: 400,
                          child: TextField(
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
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: 400,
                          child: ElevatedButton(
                            onPressed: _showItemSelectionDialog,
                            child: Text('Add Item'),
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
                        SizedBox(
                          width: 400,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            hint: Text('Select Status'),
                            onChanged: (value) {
                              if (_role == 'admin') {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              } else {
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue[400],
                        ),
                        child: Column(
                          children: [
                            Card(
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
                            if (_selectedItems.isNotEmpty)
                              for (var item in _selectedItems)
                                Card(
                                  margin: EdgeInsets.all(8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: AppTheme.headline6),
                                        SizedBox(height: 8),
                                        Table(
                                          children: [
                                            TableRow(children: [
                                              Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Sales Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Purchase Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ]),
                                            for (var rate in _itemPreviousRates[item.itemId]!.take(5)) ...[
                                              TableRow(children: [
                                                Text(rate.customerName ?? ''),
                                                Text('\$${rate.saleRate.toStringAsFixed(2)}'),
                                                Text('\$${rate.purchaseRate.toStringAsFixed(2)}'),
                                                Text(rate.date ?? ''),
                                              ]),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
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
