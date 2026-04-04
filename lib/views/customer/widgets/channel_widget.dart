import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/duration_notifier.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../utils/constants.dart';

class ChannelWidget extends StatelessWidget {
  final Channel channel;
  final int cIndex, channelLength;
  final List<Agitator> agitator;
  final String siteSno;
  final bool isMobile;

  const ChannelWidget({super.key, required this.channel, required this.cIndex,
    required this.channelLength, required this.agitator, required this.siteSno,
    required this.isMobile});

  int _safeParseInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  double _safeParseDouble(String? value) {
    if (value == null || value.isEmpty || value == '-') return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getChannelOnOffStatus(channel.sNo.toString()),
        provider.getChannelOtherData(channel.sNo.toString()),
      ),
      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        final hasValidPayload = status != null && other != null && other.isNotEmpty;

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          channel.status = int.tryParse(statusParts[1]) ?? 0;
        }

        final otherParts = other?.split(',') ?? [];
        if (otherParts.isNotEmpty) {
          if (otherParts.length > 1) channel.frtMethod = otherParts[1];
          if (otherParts.length > 2) channel.duration = otherParts[2];
          if (otherParts.length > 3) channel.completedDrQ = otherParts[3];
          if (otherParts.length > 4) channel.onTime = otherParts[4];
          if (otherParts.length > 5) channel.offTime = otherParts[5];
          if (otherParts.length > 6) channel.flowRateLpH = otherParts[6];
        }

        final hasOnOffTime = _safeParseInt(channel.onTime) > 0 || _safeParseInt(channel.offTime) > 0;
        final flowRate = _safeParseDouble(channel.flowRateLpH);
        final onTime = _safeParseInt(channel.onTime);
        final offTime = _safeParseInt(channel.offTime);

        final shouldRun = channel.status == 1 && hasValidPayload &&
            channel.completedDrQ != channel.duration;

        return ChangeNotifierProvider(
          create: (_) => IncreaseDurationNotifier(
            channel.duration,
            channel.completedDrQ,
            flowRate,
            onTime: onTime,
            offTime: offTime,
            frtMethod: channel.frtMethod,
            externalStatus: channel.status,
            hasValidPayload: hasValidPayload,
          ),
          child: Consumer<IncreaseDurationNotifier>(
            builder: (context, durationNotifier, _) {
              // Use Future.microtask to avoid calling during build
              Future.microtask(() {
                durationNotifier.updateExternalStatus(channel.status, hasValidPayload);
              });

              final displayStatus = (shouldRun && channel.frtMethod == '3' && hasOnOffTime)
                  ? durationNotifier.currentStatus
                  : channel.status;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 70,
                    height: 120,
                    child: Stack(
                      children: [
                        Image.asset(
                          AppConstants.getFertilizerChannelImage(
                              cIndex,
                              displayStatus,
                              channelLength,
                              agitator,
                              isMobile
                          ),
                        ),

                        Positioned(
                          top: 52,
                          left: 6,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.teal.shade100,
                            child: Text('${cIndex+1}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 50,
                          left: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            width: 60,
                            child: Center(
                              child: Text(
                                channel.duration,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 65,
                          left: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            width: 60,
                            child: Center(
                              child: Text(
                                '${channel.flowRateLpH != '-' ? channel.flowRateLpH : '0'}-lph',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if ((shouldRun || durationNotifier.isCompleted) && channel.completedDrQ !='00:00:00')
                          Positioned(
                            top: 97,
                            left: 0,
                            child: Container(
                              width: 55,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: const BorderRadius.all(Radius.circular(2)),
                                border: Border.all(color: Colors.grey, width: .50,),
                              ),
                              child: Center(
                                child: Text(
                                  durationNotifier.onCompletedDrQ,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (!isMobile && kIsWeb) ...[
                    const SizedBox(height: 4),
                    Container(width: 70, height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 3.5),
                    Container(width: 70, height: 1, color: Colors.grey.shade300),
                  ]
                ],
              );
            },
          ),
        );
      },
    );
  }
}


/*
class ChannelWidget extends StatelessWidget {
  final Channel channel;
  final int cIndex, channelLength;
  final List<Agitator> agitator;
  final String siteSno;
  final bool isMobile;
  const ChannelWidget({super.key, required this.channel, required this.cIndex,
    required this.channelLength, required this.agitator, required this.siteSno,
    required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Selector<MqttPayloadProvider, Tuple2<String?, String?>>(
      selector: (_, provider) => Tuple2(
        provider.getChannelOnOffStatus(channel.sNo.toString()),
        provider.getChannelOtherData(channel.sNo.toString()),
      ),

      builder: (_, data, __) {
        final status = data.item1;
        final other = data.item2;

        print("status:$status");
        print("other:$other");

        final statusParts = status?.split(',') ?? [];
        if (statusParts.length > 1) {
          channel.status = int.tryParse(statusParts[1]) ?? 0;
        }

        final otherParts = other?.split(',') ?? [];
        if (otherParts.isNotEmpty) {
          channel.frtMethod = otherParts[1];
          channel.duration = otherParts[2];
          channel.completedDrQ = otherParts[3];
          channel.onTime = otherParts[4];
          channel.offTime = otherParts[5];
          channel.flowRateLpH = otherParts[6];
        }

        final shouldBlink = channel.status == 1 && channel.frtMethod == '3';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              height: 120,
              child: Stack(
                children: [
                  Image.asset(AppConstants.getFertilizerChannelImage(cIndex, channel.status,
                      channelLength, agitator, isMobile)),
                  Positioned(
                    top: 52,
                    left: 6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.teal.shade100,
                      child: Text('${cIndex+1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      width: 60,
                      child: Center(
                        child: Text(channel.duration, style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 65,
                    left: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      width: 60,
                      child: Center(
                        child: Text('${channel.flowRateLpH}-lph', style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                    ),
                  ),
                  channel.status == 1 && channel.completedDrQ !='00:00:00' ?
                  Positioned(
                    top: 97,
                    left: 0,
                    child: Container(
                      width: 55,
                      decoration: BoxDecoration(
                        color:Colors.greenAccent,
                        borderRadius: const BorderRadius.all(Radius.circular(2)),
                        border: Border.all(color: Colors.grey, width: .50,),
                      ),
                      child: ChangeNotifierProvider(
                        create: (_) => IncreaseDurationNotifier(channel.duration,
                            channel.completedDrQ, double.parse(channel.flowRateLpH)),
                        child: Stack(
                          children: [
                            Consumer<IncreaseDurationNotifier>(
                              builder: (context, durationNotifier, _) {
                                return Center(
                                  child: Text(channel.frtMethod=='1' || channel.frtMethod=='3'?
                                  durationNotifier.onCompletedDrQ :
                                  '${durationNotifier.onCompletedDrQ} L',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ):
                  const SizedBox(),
                ],
              ),
            ),

            if(!isMobile)...[
              if(kIsWeb)...[
                const SizedBox(height: 4),
                Container(width: 70, height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 3.5),
                Container(width: 70, height: 1, color: Colors.grey.shade300),
              ]
            ]
          ],
        );
      },
    );
  }
}*/
