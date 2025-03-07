import 'package:flutter/material.dart';
import 'package:hands_user_app/main.dart';
import 'package:hands_user_app/models/revenue_chart_data.dart';
import 'package:hands_user_app/provider/utils/configs.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
            enableDoubleTapZooming: true,
            zoomMode: ZoomMode.xy,
            enablePinching: true,
            enablePanning: true),
        enableAxisAnimation: true,
        legend: Legend(
          isVisible: true,
          isResponsive: true,
          orientation: LegendItemOrientation.auto,
          position: LegendPosition.top,
          legendItemBuilder: (legendText, series, point, seriesIndex) {
            if (appStore.selectedLanguageCode == 'en')
              return Text(
                      '${languages.monthly} $legendText ${appStore.selectedLanguageCode == 'en' ? 'in' : ''} ${appStore.currencySymbol}',
                      style: boldTextStyle())
                  .paddingBottom(8);

            return Text(
                    '$legendText  -  ${languages.monthly} ${appStore.selectedLanguageCode == 'en' ? 'in' : ''} ${appStore.currencySymbol}',
                    style: boldTextStyle())
                .paddingBottom(8);
          },
        ),
        margin: EdgeInsets.fromLTRB(16, 4, 16, 16),
        title: ChartTitle(
          textStyle: secondaryTextStyle(),
        ),
        backgroundColor: primaryColor,
        primaryYAxis: NumericAxis(
            numberFormat: NumberFormat.compactCurrency(
                symbol: appStore.currencySymbol, decimalDigits: 2)),
        primaryXAxis: CategoryAxis(
          placeLabelsNearAxisLine: true,
          labelPlacement: LabelPlacement.onTicks,
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
        ),
        crosshairBehavior: CrosshairBehavior(
          activationMode: ActivationMode.singleTap,
          lineType: CrosshairLineType.horizontal,
          enable: true,
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          borderWidth: 1.5,
          color: context.cardColor,
          textStyle: secondaryTextStyle(color: context.iconColor),
        ),
        series: <CartesianSeries>[
          SplineSeries<RevenueChartData, String>(
            name: languages.lblRevenue,
            dataSource: chartData,
            enableTooltip: true,
            color: Colors.white,
            legendIconType: LegendIconType.diamond,
            splineType: SplineType.monotonic,
            yValueMapper: (RevenueChartData sales, _) => sales.revenue,
            xValueMapper: (RevenueChartData sales, _) => sales.month,
          ),
        ],
      ),
    );
  }
}
