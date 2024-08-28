import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpinEdit extends StatefulWidget
{
  final int? minValue;
  final int? maxValue;
  final int increment;
  final ValueChanged<int> onChange;
  final int initialValue;
  final String? label;

  const SpinEdit({super.key, required this.onChange, this.increment = 1, this.minValue, this.maxValue, this.initialValue = 0, this.label});

  @override
  State<StatefulWidget> createState() => _SpinEdit();
}

class _SpinEdit extends State<SpinEdit>
{
  final TextEditingController _textEditingController = TextEditingController();

  void increment()
  {
    int? value = int.tryParse(_textEditingController.text);
    if(value != null)
    {
      value += widget.increment;
      setState(() => _textEditingController.text = value.toString());
      widget.onChange(value);
    }
  }

  bool canIncrement()
  {
    bool canIncrement = false;
    int? value = int.tryParse(_textEditingController.text);
    if(value != null)
    {
      if(widget.maxValue == null)
      {
        canIncrement = true;
      }
      else
      {
        canIncrement = value + widget.increment <= widget.maxValue!;
      }
    }
    return canIncrement;
  }

  void decrement()
  {
    int? value = int.tryParse(_textEditingController.text);
    if(value != null)
    {
      value -= widget.increment;
      setState(() => _textEditingController.text = value.toString());
      widget.onChange(value);
    }
  }

  bool canDecrement()
  {
    bool canDecrement = false;
    int? value = int.tryParse(_textEditingController.text);
    if(value != null)
    {
      if(widget.minValue == null)
      {
        canDecrement = true;
      }
      else
      {
        canDecrement = value - widget.increment >= widget.minValue!;
      }
    }
    return canDecrement;
  }

  @override
  void initState() {
    super.initState();

    _textEditingController.text = widget.initialValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextField
    (
      readOnly: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration
      (
        prefix: IconButton
        (
          icon: const Icon(Icons.remove),
          onPressed: canDecrement() ? decrement : null,
        ),
        suffix: IconButton
        (
          icon: const Icon(Icons.add),
          onPressed: canIncrement() ? increment : null,
          
        ),
        border: const OutlineInputBorder(),
        label: Text(widget.label ?? ""),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        isCollapsed: true
      ),
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      controller: _textEditingController,
      inputFormatters: <TextInputFormatter>
      [
        FilteringTextInputFormatter.digitsOnly
      ],
    );
  }
}