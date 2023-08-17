// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:split_view/split_view.dart';

class CrudPage extends StatefulWidget {
  @override
  _CrudPageState createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();
  final TextEditingController _field4Controller = TextEditingController();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _medicineReferencesController =
      TextEditingController();

  String _selectedCollection = 'Medicine';
  List<String> _selectedMedicineReferences = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SkinVisionary CRUD'),
      ),
      body: SplitView(
        viewMode: SplitViewMode.Horizontal,
        indicator: SplitIndicator(viewMode: SplitViewMode.Horizontal),
        controller: SplitViewController(limits: [null, WeightLimit(max: 0.8)]),
        children: [
          // Left Side
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: _selectedCollection,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCollection = newValue!;
                    });
                  },
                  items: ['Medicine', 'SkinDisease']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                TextField(
                  controller: _field1Controller,
                  decoration: InputDecoration(
                      labelText: _selectedCollection == 'Medicine'
                          ? 'Image URL'
                          : 'Cause'),
                ),
                TextField(
                  controller: _field2Controller,
                  decoration: InputDecoration(
                      labelText: _selectedCollection == 'Medicine'
                          ? 'Name'
                          : 'Curement'),
                ),
                TextField(
                  controller: _field3Controller,
                  decoration: InputDecoration(
                      labelText: _selectedCollection == 'Medicine'
                          ? 'Property'
                          : 'Disease Name'),
                ),
                if (_selectedCollection == 'Medicine')
                  TextField(
                    controller: _usageController,
                    decoration: InputDecoration(labelText: 'Usage'),
                  ),
                if (_selectedCollection == 'SkinDisease')
                  TextField(
                    controller: _field4Controller,
                    decoration: InputDecoration(labelText: 'Symptom'),
                  ),
                if (_selectedCollection == 'SkinDisease')
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('Medicine').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        List<Widget> medicineWidgets = [];
                        final medicines = snapshot.data!.docs;

                        for (var medicine in medicines) {
                          String medicineId = medicine.id;
                          String medicineName = medicine['name'];

                          medicineWidgets.add(
                            ListTile(
                              leading: Checkbox(
                                value: _selectedMedicineReferences
                                    .contains(medicineId),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMedicineReferences
                                          .add(medicineId);
                                    } else {
                                      _selectedMedicineReferences
                                          .remove(medicineId);
                                    }
                                  });
                                },
                              ),
                              title: Text(medicineName),
                            ),
                          );
                        }

                        return ListView(
                          children: medicineWidgets,
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addItem,
                      child: Text('Add Item'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ),

          // Right Side
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection(_selectedCollection).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              List<Widget> itemWidgets = [];
              final items = snapshot.data!.docs;

              for (var item in items) {
                Map<String, dynamic> data = item.data() as Map<String, dynamic>;
                String field1 =
                    data[_selectedCollection == 'Medicine' ? 'image' : 'cause'];
                String field2 = data[
                    _selectedCollection == 'Medicine' ? 'name' : 'curement'];
                String field3 = data[_selectedCollection == 'Medicine'
                    ? 'property'
                    : 'disease_name'];
                String field4 =
                    _selectedCollection == 'SkinDisease' ? data['symptom'] : '';
                String medicineReferences = data['medicine_references'] != null
                    ? (data['medicine_references'] as List).join(', ')
                    : '';

                itemWidgets.add(
                  ListTile(
                    leading: _selectedCollection == 'Medicine'
                        ? Image.network(field1)
                        : const Icon(Icons.info),
                    title: Text(
                        _selectedCollection == 'SkinDisease' ? field3 : field2),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Field 3: $field3'),
                        if (_selectedCollection == 'SkinDisease')
                          Text('Field 4: $field4'),
                        if (_selectedCollection == 'SkinDisease')
                          Text('Medicine References: $medicineReferences'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEditPage(item.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteItem(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                children: itemWidgets,
              );
            },
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if (_selectedCollection == 'SkinDisease') {
      List<String> medicineReferences = _selectedMedicineReferences.toList();

      _firestore.collection(_selectedCollection).add({
        'cause': _field1Controller.text,
        'curement': _field2Controller.text,
        'disease_name': _field3Controller.text,
        'symptom': _field4Controller.text,
        'medicine_references': medicineReferences,
      });

      _selectedMedicineReferences.clear();
    } else if (_selectedCollection == 'Medicine') {
      _firestore.collection(_selectedCollection).add({
        'image': _field1Controller.text,
        'name': _field2Controller.text,
        'property': _field3Controller.text,
        'usage': _usageController.text,
      });
    }

    _field1Controller.clear();
    _field2Controller.clear();
    _field3Controller.clear();
    _field4Controller.clear();
  }

  void _editItem(String itemId) {
    if (_selectedCollection == 'SkinDisease') {
      List<String> medicineReferences = _selectedMedicineReferences.toList();

      DocumentReference itemRef =
          _firestore.collection(_selectedCollection).doc(itemId);
      Map<String, dynamic> updatedData = {
        'cause': _field1Controller.text,
        'curement': _field2Controller.text,
        'disease_name': _field3Controller.text,
        'symptom': _field4Controller.text,
        'medicine_references': medicineReferences,
      };
      itemRef.update(updatedData);

      _selectedMedicineReferences.clear();
    } else if (_selectedCollection == 'Medicine') {
      DocumentReference itemRef =
          _firestore.collection(_selectedCollection).doc(itemId);
      Map<String, dynamic> updatedData = {
        'image': _field1Controller.text,
        'name': _field2Controller.text,
        'property': _field3Controller.text,
        'usage': _usageController.text,
      };
      itemRef.update(updatedData);
    }

    _field1Controller.clear();
    _field2Controller.clear();
    _field3Controller.clear();
    _field4Controller.clear();
  }

  void _deleteItem(String itemId) {
    _firestore.collection(_selectedCollection).doc(itemId).delete();
  }

  void _openEditPage(String itemId) async {
    DocumentSnapshot itemSnapshot =
        await _firestore.collection(_selectedCollection).doc(itemId).get();
    String field1 =
        itemSnapshot[_selectedCollection == 'Medicine' ? 'image' : 'cause'];
    String field2 =
        itemSnapshot[_selectedCollection == 'Medicine' ? 'name' : 'curement'];
    String field3 = itemSnapshot[
        _selectedCollection == 'Medicine' ? 'property' : 'disease_name'];
    String field4 =
        _selectedCollection == 'SkinDisease' ? itemSnapshot['symptom'] : '';
    if (_selectedCollection == 'Medicine') {
      String usage = itemSnapshot['usage'] != null ? itemSnapshot['usage'] : '';
      _usageController.text = usage;
    }
    _field1Controller.text = field1;
    _field2Controller.text = field2;
    _field3Controller.text = field3;
    _field4Controller.text = field4;
    if (_selectedCollection == 'SkinDisease') {
      String medicineReferences = itemSnapshot['medicine_references'] != null
          ? (itemSnapshot['medicine_references'] as List).join(', ')
          : '';
      _medicineReferencesController.text = medicineReferences;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _field1Controller,
              decoration: InputDecoration(
                labelText:
                    _selectedCollection == 'Medicine' ? 'Image URL' : 'Cause',
              ),
            ),
            TextField(
              controller: _field2Controller,
              decoration: InputDecoration(
                labelText:
                    _selectedCollection == 'Medicine' ? 'Name' : 'Curement',
              ),
            ),
            TextField(
              controller: _field3Controller,
              decoration: InputDecoration(
                labelText: _selectedCollection == 'Medicine'
                    ? 'Property'
                    : 'Disease Name',
              ),
            ),
            if (_selectedCollection == 'Medicine')
              TextField(
                controller: _usageController,
                decoration: InputDecoration(labelText: 'Usage'),
              ),
            if (_selectedCollection == 'SkinDisease')
              TextField(
                controller: _field4Controller,
                decoration: InputDecoration(labelText: 'Symptom'),
              ),
            if (_selectedCollection == 'SkinDisease')
              TextField(
                controller: _medicineReferencesController,
                decoration: InputDecoration(labelText: 'Medicine References'),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _editItem(itemId);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
