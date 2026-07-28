import 'package:flutter/material.dart';

class AqelCheckbox extends StatefulWidget {
  final bool value;
  final double size;
  final double iconSize;
  final Color? selectedColor;
  final Color? selectedIconColor;
  final ValueChanged<bool>? onChanged;
  AqelCheckbox({
    super.key,
    this.value = false,
    this.size = 30,
    this.iconSize = 20,
    this.selectedColor,
    this.selectedIconColor,
    this.onChanged,
  });

  @override
  _AqelCheckboxState createState() => _AqelCheckboxState();
}

class _AqelCheckboxState extends State<AqelCheckbox> {
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
          widget.onChanged?.call(_isSelected);
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.fastLinearToSlowEaseIn,
        decoration: BoxDecoration(
          color: _isSelected
              ? widget.selectedColor ?? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          ),
        ),
        width: widget.size,
        height: widget.size,
        child: _isSelected
            ? Icon(
                Icons.check,
                color: widget.selectedIconColor ?? Colors.white,
                size: widget.iconSize,
              )
            : null,
      ),
    );
  }
}
