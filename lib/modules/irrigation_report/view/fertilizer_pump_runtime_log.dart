import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/preview_screen.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import '../../../Widgets/custom_buttons.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';


class FertilizerPumpRuntimeLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FertilizerPumpRuntimeLog({super.key, required this.userData});

  @override
  State<FertilizerPumpRuntimeLog> createState() => _FertilizerPumpRuntimeLogState();
}

class _FertilizerPumpRuntimeLogState extends State<FertilizerPumpRuntimeLog> {
  DateTime? selectedDate;
  String _selectedDate = '';
  String _dateCount = '';
  String _range = '';
  String _rangeCount = '';
  DateRange? selectedDateRange;

  Map<String, dynamic> data = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        // getData();
      }
    });
  }

  String _formatNumber(int number) {
    // Add leading zero if the number is less than 10
    return number.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: data.isEmpty ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10,
              children: [
                const SizedBox(height: 1,),
                for(var i = 0; i < 3;i++)
                  Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: customBoxShadow
                  ),
                  child: Row(
                    spacing: 20,
                    children: [
                      Container(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        child: Image.asset(
                            'assets/Images/Png/objectId_${AppConstants.boosterObjectId}.png',
                          width: 70,
                          height: 100,
                        ),
                        padding: EdgeInsets.all(5),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            getTitleValue(title: 'Zone 001', value: 'FERT PUMP1'),
                            getTitleValue(title: 'Total Flow', value: '1368 Lts', valueColor: Colors.black45),
                            getTitleValue(title: 'Start Time', value: '10:53:15', valueColor: Colors.black45),
                            getTitleValue(title: 'End Time', value: '14:58:01', valueColor: Colors.black45),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ) : Center(
        child: Text('There is no data in $_selectedDate'),
      ),
    );
  }

  Widget getTitleValue({required String title, required String value, Color? titleColor, Color? valueColor, double? fontSize}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize ?? 13, color: titleColor ?? Colors.black),),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize ?? 13, color: valueColor ?? Colors.black),),
      ],
    );
  }

  Widget getDivider({Color? color}){
    return SizedBox(
      height: 30,
      child: VerticalDivider(
        thickness: 1,
        color: color ?? Colors.black,
      ),
    );
  }

}
