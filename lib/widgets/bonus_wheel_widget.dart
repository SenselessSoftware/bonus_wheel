import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BonusWheelWidget extends StatelessWidget {
  final StreamController<int> selected;
  final String selectedLayout;
  final Function(String) onItemSelected;

  const BonusWheelWidget({
    super.key,
    required this.selected,
    required this.selectedLayout,
    required this.onItemSelected,
  });

  Future<List<FortuneItem>> _getFortuneItemsForLayout(String layoutName) async {
    if (layoutName == 'Default') {
      return const [
        FortuneItem(child: Text('Option 1')),
        FortuneItem(child: Text('Option 2')),
        FortuneItem(child: Text('Option 3')),
      ];
    }

    final prefs = await SharedPreferences.getInstance();
    final layoutDataString = prefs.getString('layout_$layoutName');
    if (layoutDataString == null) {
      return [];
    }

    final layoutData = json.decode(layoutDataString) as List;
    return layoutData.map((itemData) {
      return FortuneItem(
        child: Text(itemData['text']),
        style: FortuneItemStyle(
          color: Color(itemData['color']),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _getFortuneItemsForLayout(selectedLayout).then((items) {
          if (items.isNotEmpty) {
            final selectedIndex = Fortune.randomInt(0, items.length);
            final selectedItem = items[selectedIndex];
            final selectedValue = (selectedItem.child as Text).data!;
            onItemSelected(selectedValue);
            selected.add(selectedIndex);
          }
        });
      },
      child: FutureBuilder<List<FortuneItem>>(
        future: _getFortuneItemsForLayout(selectedLayout),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return FortuneWheel(
              selected: selected.stream,
              items: snapshot.data!,
              onAnimationEnd: () {
                // You can also get the value here, after the animation ends
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading layout'));
          } else if (selectedLayout != 'Default' &&
              (!snapshot.hasData || snapshot.data!.isEmpty)) {
            return const Center(child: Text('Layout not found'));
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
