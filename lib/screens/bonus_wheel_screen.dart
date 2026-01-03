import 'dart:async';

import 'package:bonus_wheel/screens/settings_screen.dart';
import 'package:bonus_wheel/widgets/bonus_wheel_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BonusWheelScreen extends StatefulWidget {
  const BonusWheelScreen({super.key, required this.title});

  final String title;

  @override
  State<BonusWheelScreen> createState() => _BonusWheelScreenState();
}

class _BonusWheelScreenState extends State<BonusWheelScreen> {
  final StreamController<int> _selected = StreamController<int>();
  final List<String> _layouts = ['Default'];
  String _selectedLayout = 'Default';
  String _selectedValue = '';

  @override
  void initState() {
    super.initState();
    _loadLayouts();
  }

  Future<void> _loadLayouts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      _layouts.clear();
      _layouts.add('Default');
      _layouts.addAll(keys.where((key) => key != 'flutter.version'));
      if (!_layouts.contains(_selectedLayout)) {
        _selectedLayout = 'Default';
      }
    });
  }

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadLayouts());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _selectedLayout,
                  items: _layouts.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLayout = newValue!;
                      _selectedValue = '';
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _selectedLayout == 'Default'
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SettingsScreen(layoutName: _selectedLayout)),
                          ).then((_) => _loadLayouts());
                        },
                ),
              ],
            ),
            if (_selectedValue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Selected: $_selectedValue',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            Expanded(
              child: BonusWheelWidget(
                selected: _selected,
                selectedLayout: _selectedLayout,
                onItemSelected: (value) {
                  setState(() {
                    _selectedValue = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
