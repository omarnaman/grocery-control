import 'package:flutter/material.dart';

class AqelCheckbox extends StatefulWidget {
  final bool value;
  final double size;
  final double iconSize;
  final Color selectedColor;
  final Color selectedIconColor;
  final Function(bool) onChanged;
  AqelCheckbox({Key key, this.value, this.size, this.iconSize, this.selectedColor, this.selectedIconColor, this.onChanged}): super(key: key);

  @override
  _AqelCheckboxState createState() => _AqelCheckboxState();
}

class _AqelCheckboxState extends State<AqelCheckbox> {

  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.value ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
          widget.onChanged(_isSelected);
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.fastLinearToSlowEaseIn,
        decoration: BoxDecoration(
          color: _isSelected ? widget.selectedColor ?? Theme.of(context).accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          )
        ),
        width: widget.size ?? 30,
        height: widget.size ?? 30,
        child: _isSelected ? Icon(
          Icons.check,
          color: widget.selectedIconColor ?? Colors.white,
          size: widget.iconSize ?? 20,
        ) : null,
      ),
    );
  }
}