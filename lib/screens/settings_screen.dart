
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String? layoutName;

  const SettingsScreen({super.key, this.layoutName});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _layoutNameController = TextEditingController();
  final List<FortuneItem> _items = [];
  final _textControllers = <TextEditingController>[];

  final Map<String, Color> _colorMap = {
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Yellow': Colors.yellow,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Teal': Colors.teal,
    'Cyan': Colors.cyan,
    'Amber': Colors.amber,
    'Brown': Colors.brown,
    'Grey': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    if (widget.layoutName != null) {
      _layoutNameController.text = widget.layoutName!;
      _loadLayoutData(widget.layoutName!);
    } else {
      _items.addAll([
        const FortuneItem(child: Text('Default 1')),
        const FortuneItem(child: Text('Default 2')),
      ]);
      for (var item in _items) {
        _textControllers
            .add(TextEditingController(text: (item.child as Text).data));
      }
    }
  }

  Future<void> _loadLayoutData(String layoutName) async {
    final prefs = await SharedPreferences.getInstance();
    final layoutDataString = prefs.getString(layoutName);
    if (layoutDataString != null) {
      final layoutData = json.decode(layoutDataString) as List;
      setState(() {
        _items.clear();
        _textControllers.clear();
        for (var itemData in layoutData) {
          final item = FortuneItem(
            child: Text(itemData['text']),
            style: FortuneItemStyle(
              color: Color(itemData['color']),
            ),
          );
          _items.add(item);
          _textControllers.add(TextEditingController(text: itemData['text']));
        }
      });
    }
  }

  void _addItem() {
    if (_items.length < 20) {
      setState(() {
        const newItem = FortuneItem(child: Text('New Item'));
        _items.add(newItem);
        _textControllers.add(TextEditingController(text: 'New Item'));
      });
    }
  }

  void _removeItem(int index) {
    if (_items.length > 2) {
      setState(() {
        _textControllers[index].dispose();
        _textControllers.removeAt(index);
        _items.removeAt(index);
      });
    }
  }

  void _pickColor(int index) {
    Color? selectedColor = _items[index].style?.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: DropdownButton<Color>(
          value: selectedColor != null && _colorMap.containsValue(selectedColor)
              ? selectedColor
              : null,
          hint: const Text("Select a color"),
          items: _colorMap.entries.map((entry) {
            return DropdownMenuItem<Color>(
              value: entry.value,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 20,
                    color: entry.value,
                  ),
                  const SizedBox(width: 10),
                  Text(entry.key),
                ],
              ),
            );
          }).toList(),
          onChanged: (Color? newColor) {
            if (newColor != null) {
              setState(() {
                final currentItem = _items[index];
                final currentStyle =
                    currentItem.style ?? const FortuneItemStyle();
                _items[index] = FortuneItem(
                  child: currentItem.child,
                  style: FortuneItemStyle(
                    color: newColor,
                    borderColor: currentStyle.borderColor,
                    borderWidth: currentStyle.borderWidth,
                    textAlign: currentStyle.textAlign,
                    textStyle: currentStyle.textStyle,
                  ),
                );
              });
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _saveLayout() async {
    final layoutName = _layoutNameController.text;
    if (layoutName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layout name cannot be empty')),
        );
      }
      return;
    }
    if (layoutName == 'Default') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot overwrite default layout')),
        );
      }
      return;
    }
    if (_items.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layout must have at least 2 items')),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final layoutData = List.generate(_items.length, (index) {
      final item = _items[index];
      final text = _textControllers[index].text;
      final color = item.style?.color.value ?? Colors.blue.value;
      return {'text': text, 'color': color};
    }).toList();

    await prefs.setString(layoutName, json.encode(layoutData));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Layout "$layoutName" saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLayout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _layoutNameController,
              decoration: const InputDecoration(
                labelText: 'Layout Name',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Item ${index + 1}',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.color_lens,
                                color: _items[index].style?.color ?? Colors.grey),
                            onPressed: () => _pickColor(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addItem,
              child: const Text('Add Item'),
            )
          ],
        ),
      ),
    );
  }
}
