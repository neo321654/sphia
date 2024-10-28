import 'package:flutter/material.dart';
import 'package:sphia/view/card/dashboard_card/chart.dart';
import 'package:sphia/view/card/dashboard_card/dark_mode.dart';
import 'package:sphia/view/card/dashboard_card/dns.dart';
import 'package:sphia/view/card/dashboard_card/local_port.dart';
import 'package:sphia/view/card/dashboard_card/proxy.dart';
import 'package:sphia/view/card/dashboard_card/rule_group.dart';
import 'package:sphia/view/card/dashboard_card/running_cores.dart';
import 'package:sphia/view/card/dashboard_card/running_server.dart';
import 'package:sphia/view/card/dashboard_card/traffic.dart';

const cardHorizontalSpacing = 40.0;
const cardVerticalSpacing = 20.0;
const cardChartHeight = 120.0;

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(48.0, 50.0, 48.0, 50.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        DarkModeCard(),
                        SizedBox(height: cardVerticalSpacing),
                        Flexible(
                          flex: 1,
                          child: LocalPortCard(),
                        ),
                        SizedBox(height: cardVerticalSpacing),
                        Flexible(
                          flex: 1,
                          child: RunningServerCard(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: cardHorizontalSpacing),
                  Flexible(
                    child: Column(
                      children: [
                        Flexible(
                          flex: 2,
                          child: RunningCoresCard(),
                        ),
                        SizedBox(height: cardVerticalSpacing),
                        RuleGroupCard(),
                        SizedBox(height: cardVerticalSpacing),
                        Flexible(
                          flex: 3,
                          child: ProxyCard(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: cardHorizontalSpacing),
                  Flexible(
                    child: Column(
                      children: [
                        Flexible(
                          flex: 1,
                          child: TrafficCard(),
                        ),
                        SizedBox(height: cardVerticalSpacing),
                        Flexible(
                          flex: 1,
                          child: DnsCard(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: cardVerticalSpacing * 2),
            SizedBox(
              height: cardChartHeight,
              child: NetworkChart(),
            ),
          ],
        ),
      ),
    );
  }
}
