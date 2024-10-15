import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/models/harvest_model.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/widgets/sales_table.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  _StorageScreenState createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _showActiveItems = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: customTheme,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.storage)),
        body: Column(
          children: [
            _buildToggleButtons(context),
            Expanded(
              child: _showActiveItems
                  ? _buildActiveItemsList(context)
                  : _buildPastItemsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ToggleButtons(
      isSelected: [_showActiveItems, !_showActiveItems],
      onPressed: (index) {
        setState(() {
          _showActiveItems = index == 0;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n!.activeItems),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n!.pastItems),
        ),
      ],
    );
  }

  Widget _buildActiveItemsList(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.userRole;

    switch (userRole) {
      case 'Farmer':
      case 'Farm Manager':
        return _buildHarvestList(context);
      case 'Trader':
        return SalesTable();
       case 'Processor':
        return SalesTable();       
      case 'Seller':
        return _buildInventoryList(context);
      case 'Transporter':
        return _buildActiveDeliveriesList(context);
      case 'Buyer':
        return _buildShoppingCartList(context);
      default:
        return Center(
            child: Text(AppLocalizations.of(context)!.noDataAvailable));
    }
  }

  Widget _buildPastItemsList(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.userRole;

    switch (userRole) {
      case 'Farmer':
      case 'Farm Manager':
      case 'Trader':
      case 'Seller':
        return _buildTransactionHistoryList(context);
      case 'Transporter':
        return _buildDeliveryHistoryList(context);
      case 'Buyer':
        return _buildOrderHistoryList(context);
      default:
        return Center(
            child: Text(AppLocalizations.of(context)!.noDataAvailable));
    }
  }

  Widget _buildOrderHistoryList(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getOrdersForBuyer(appState.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              title: Text('Order #${order['id']}'),
              subtitle: Text(
                  '${order['order_date']} - ${AppLocalizations.of(context)!.total}: ${order['total_price']}'),
              trailing: Text(order['status']),
            );
          },
        );
      },
    );
  }

  Widget _buildHarvestList(BuildContext context) {
    return FutureBuilder<List<HarvestModel>>(
      future: _databaseHelper.getHarvests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final harvests = snapshot.data ?? [];
        return ListView.builder(
          itemCount: harvests.length,
          itemBuilder: (context, index) {
            final harvest = harvests[index];
            return ListTile(
              title: Text(
                  '${harvest.cropType} - ${harvest.quantity} ${harvest.unit}'),
              subtitle: Text(harvest.harvestDate as String),
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final inventory = snapshot.data ?? [];
        return ListView.builder(
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            return ListTile(
              title: Text(
                  '${item['crop_type']} - ${item['quantity']} ${item['unit']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveDeliveriesList(BuildContext context) {
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
        return ListView.builder(
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return ListTile(
              title: Text(
                  '${delivery['pickup_location']} to ${delivery['delivery_location']}'),
              subtitle: Text('Status: ${delivery['status']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildShoppingCartList(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getShoppingCart(appState.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final cartItems = snapshot.data ?? [];
        return ListView.builder(
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            final item = cartItems[index];
            return ListTile(
              title: Text(
                  '${item['crop_type']} - ${item['quantity']} ${item['unit']}'),
              subtitle: Text(
                  '${AppLocalizations.of(context)!.price}: ${item['price']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionHistoryList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getTransactionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final transactions = snapshot.data ?? [];
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Text(
                  '${transaction['crop_type']} - ${transaction['quantity']} ${transaction['unit']}'),
              subtitle: Text('${transaction['type']} - ${transaction['date']}'),
              trailing: Text(
                  '${AppLocalizations.of(context)!.price}: ${transaction['price']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryHistoryList(BuildContext context) {
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
          return ListView.builder(
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                return ListTile(
                  title: Text(
                      '${delivery['pickup_location']} to ${delivery['delivery_location']}'),
                  subtitle: Text(
                      '${delivery['pickup_date']} - ${delivery['delivery_date']}'),
                );
              });
        });
  }
}
