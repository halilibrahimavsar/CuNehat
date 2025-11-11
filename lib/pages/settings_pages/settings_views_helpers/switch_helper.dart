// Ayar öğesi (açma/kapama anahtarlı)
import 'package:flutter/material.dart';

class SettingsSwitchItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchItem({
    super.key,
    required this.title,
    required this.icon,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<SettingsSwitchItem> createState() => _SettingsSwitchItemState();
}

class _SettingsSwitchItemState extends State<SettingsSwitchItem> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      secondary:
          Icon(widget.icon, color: Theme.of(context).colorScheme.secondary),
      value: _value,
      onChanged: (newValue) {
        setState(() {
          _value = newValue;
        });
        widget.onChanged(newValue);
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
