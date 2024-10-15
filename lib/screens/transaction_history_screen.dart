import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.transactionHistory),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
              final date = DateTime.parse(transaction['date']);
              final formattedDate = DateFormat.yMd().add_jm().format(date);
              final isBuy = transaction['type'] == 'buy';
              return ListTile(
                leading: Icon(
                  isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isBuy ? Colors.green : Colors.red,
                ),
                title: Text(
                    '${transaction['crop_type']} - ${transaction['quantity']} ${transaction['unit']}'),
                subtitle: Text('${l10n!.price}: ${transaction['price']}'),
                trailing: Text(formattedDate),
              );
            },
          );
        },
      ),
    );
  }
}
