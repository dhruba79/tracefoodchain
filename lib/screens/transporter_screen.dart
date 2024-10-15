import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class TransporterScreen extends StatefulWidget {
  const TransporterScreen({super.key});

  @override
  _TransporterScreenState createState() => _TransporterScreenState();
}

class _TransporterScreenState extends State<TransporterScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n!.transporterActions),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n!.activeDeliveries),
              Tab(text: l10n!.deliveryHistory),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveDeliveries(context),
            _buildDeliveryHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveries(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getActiveDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final deliveries = snapshot.data ?? [];
        if (deliveries.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)!.noActiveDeliveries));
        }
        return ListView.builder(
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: ListTile(
                title: Text(
                    '${delivery['pickup_location']} to ${delivery['delivery_location']}'),
                subtitle: Text('Status: ${delivery['status']}'),
                trailing: ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.updateStatus),
                  onPressed: () => _showUpdateStatusDialog(context, delivery),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryHistory(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getDeliveryHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final deliveries = snapshot.data ?? [];
        if (deliveries.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)!.noDeliveryHistory));
        }
        return ListView.builder(
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            final pickupDate = DateTime.parse(delivery['pickup_date']);
            final deliveryDate = DateTime.parse(delivery['delivery_date']);
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: ListTile(
                title: Text(
                    '${delivery['pickup_location']} to ${delivery['delivery_location']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${DateFormat.yMd().format(pickupDate)}'),
                    Text('Delivery: ${DateFormat.yMd().format(deliveryDate)}'),
                    Text('Status: ${delivery['status']}'),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateStatusDialog(
      BuildContext context, Map<String, dynamic> delivery) {
    final l10n = AppLocalizations.of(context)!;
    String newStatus = delivery['status'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n!.updateDeliveryStatus),
        content: DropdownButton<String>(
          value: newStatus,
          items: ['in_transit', 'delivered', 'completed'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_getStatusText(value, l10n)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                newStatus = value;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _databaseHelper.updateDeliveryStatus(
                    delivery['id'], newStatus);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n!.statusUpdatedSuccessfully)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(l10n!.confirm),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'in_transit':
        return l10n!.inTransit;
      case 'delivered':
        return l10n!.delivered;
      case 'completed':
        return l10n!.completed;
      default:
        return status;
    }
  }
}
