import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Constants/constants.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../Widgets/HoursMinutesSeconds.dart';

class CustomNativeTimePicker extends StatelessWidget {
  final String initialValue;
  final int modelId;
  final bool is24HourMode;
  final Function(String) onChanged;
  final TextStyle? style;
  final bool isNewTimePicker;

  const CustomNativeTimePicker({super.key,
    required this.initialValue,
    required this.is24HourMode,
    required this.onChanged,
    this.style,
    this.isNewTimePicker = false, required this.modelId
  });

  @override
  Widget build(BuildContext context) {
    final overAllPvd = Provider.of<OverAllUse>(context);
    return InkWell(
      child: Text(
        Constants.showHourAndMinuteOnly(initialValue, modelId),
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: () async {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: HoursMinutesSeconds(
                  initialTime: initialValue,
                  onPressed: () {
                    onChanged('${overAllPvd.hrs.toString().padLeft(2, '0')}:${overAllPvd.min.toString().padLeft(2, '0')}:${overAllPvd.sec.toString().padLeft(2, '0')}');
                    Navigator.pop(context);
                  }, modelId: modelId,
                ),
              );
            });
      },
    );
  }
}
