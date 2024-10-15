import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trace_foodchain_app/main.dart';

//! ONLY TEST: DISPLAY ALL STOCK ITEMS (bought by the trader)

class SalesTable extends StatefulWidget {
  @override
  _SalesTableState createState() => _SalesTableState();
}

class _SalesTableState extends State<SalesTable> {
  late Future<List<Map<String, dynamic>>> filteredSales;

  @override
  void initState() {
    super.initState();
    filteredSales =
        getFilteredAndSortedSales(owner: 'xyz', objectType: 'coffee');
    //ToDo: better solution: Have a seller object and look at its methodHistory for buying coffee - doing so also enables to display past stuff
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: filteredSales,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Nothing in stock.');
        } else {
          return DataTable(
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('Coffee Type')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Actions')),
            ],
            rows: snapshot.data!.map((sale) {
              return DataRow(
                cells: [
                  DataCell(Text(sale['existenceStarts'])),
                  DataCell(Text(sale['owner'])),
                  DataCell(Text(sale[
                      'coffeeType'])), // Angenommen, dies ist das Feld für die Kaffee-Art
                  DataCell(Text(sale['amount']
                      .toString())), // Angenommen, dies ist das Feld für die Menge
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        _showMoreOptions(context);
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              leading: Icon(Icons.sell),
              title: Text('Sell Coffee'),
              onTap: () {
                Navigator.pop(context);
                // Hier die Logik zum Verkauf von Kaffee hinzufügen
              },
            ),
            // Weitere Optionen hinzufügen, wenn nötig
          ],
        );
      },
    );
  }
}

Future<List<Map<String, dynamic>>> getFilteredAndSortedSales({
  required String owner,
  required String objectType,
}) async {
  List<Map<dynamic, dynamic>> sales = localStorage.values
      .where((sale) =>
          sale['template']["RALType"] ==
          "changeOwner") //Optimieren: Alle Kaufs/Verkaufsprozesse, wo der User beteiligt war
      .toList();

  List<Map<String, dynamic>> sortedAndFilteredSales = [];
  for (dynamic sale in sales) {
    Map<String, dynamic> sale2 = Map<String, dynamic>.from(sale);
    //ToDo: Nur die Käufe reinnehmen, d.h. Prozesse wo der User der neue Owner ist (sonst ist es ja ein Verkauf)
    sortedAndFilteredSales.add(sale2);
  }
  // Sortieren nach 'existenceStarts' in absteigender Reihenfolge
  sales.sort((a, b) {
    DateTime dateA = DateTime.parse(a['existenceStarts']);
    DateTime dateB = DateTime.parse(b['existenceStarts']);
    return dateB.compareTo(dateA); // Absteigende Reihenfolge
  });

  return sortedAndFilteredSales;
}
