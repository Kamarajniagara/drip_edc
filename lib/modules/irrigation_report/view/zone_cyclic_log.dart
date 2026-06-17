import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_date_range_picker/flutter_date_range_picker.dart';
import 'package:oro_drip_irrigation/Constants/data_convertion.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import '../../../Widgets/custom_buttons.dart';
import '../repository/irrigation_repository.dart';
import 'log_home.dart';


class ZoneCyclicLog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ZoneCyclicLog({super.key, required this.userData});

  @override
  State<ZoneCyclicLog> createState() => _ZoneCyclicLogState();
}

class _ZoneCyclicLogState extends State<ZoneCyclicLog> {
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
                // for(var programData in data["data"]["motorCyclic"])
                zoneCyclicBox(zoneCyclicData: {})
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

  Widget zoneCyclicBox({
    required Map<String, dynamic> zoneCyclicData,
  }){
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        spacing: 8,
        children: [
          getTitleValue(title: 'Date', value: "15-09-2025", titleColor: Colors.white, valueColor: Colors.white),
          getTitleValue(title: 'Cyclic duration', value: "06:29:42", titleColor: Colors.white, valueColor: Colors.white),
          getTitleValue(title: 'Cyclic flow', value: '0', titleColor: Colors.white, valueColor: Colors.white),
          Column(
            spacing: 10,
            children: [
              for(var i = 0; i < 3; i++)
                programBox(programData: {})
            ],
          ),
        ],
      ),
    );
  }

  String getCyclicDuration({required Map<String, dynamic> programData,}){
    DataConvert dataConvert = DataConvert();
    int totalSeconds = 0;
    for(var zoneData in programData['zoneList']){
      totalSeconds += dataConvert.parseTimeString(zoneData["duration"]);
    }
    return dataConvert.formatTime(totalSeconds);
  }

  String getCyclicFlow({required Map<String, dynamic> programData,}){
    double totalFlow = 0;
    for(var zoneData in programData['zoneList']){
      totalFlow += double.parse(zoneData["flow"]);
    }
    return totalFlow.toString();
  }

  Widget programBox({
    required Map<String, dynamic> programData,
  }){
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          color: Theme.of(context).primaryColorDark,
          child: Row(
            children: [
              Expanded(child: getTitleValue(title: 'Program', value: "1", titleColor: Colors.white, valueColor: Colors.white)),
              Expanded(child: Container())
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5))
          ),
          child: Column(
            spacing: 10,
            children: [
              Row(
                children: [
                  Expanded(child: getTitleValue(title: 'Set Time', value: '00:00:00', fontSize : 12, titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(child: getTitleValue(title: 'Run Time', value: '00:00:00', fontSize : 12, titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(child: getTitleValue(title: 'Set Flow', value: '0', fontSize : 12, titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(child: getTitleValue(title: 'Run Flow', value: '0', fontSize : 12, titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(child: getTitleValue(title: 'Start Time', value: '00:00:00', fontSize : 12, titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(child: getTitleValue(title: 'End Time', value: '00:00:00', fontSize : 12, titleColor: Colors.black54))
                ],
              ),
              Row(
                children: [
                  Expanded(child: getTitleValue(title: 'Level', value: '0.00 F', fontSize : 12, titleColor: Colors.black54)),
                  getDivider(),
                  Expanded(child: getTitleValue(title: 'Percentage', value: '0 %', fontSize : 12, titleColor: Colors.black54))
                ],
              ),
            ],
          ),
        ),

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
