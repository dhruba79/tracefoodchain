import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';

import '../widgets/shared_widgets.dart';

ValueNotifier<bool> rebuildInbox = ValueNotifier<bool>(false);

class InboxScreen extends StatefulWidget {
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text("INBOX"),
        ),
        body: ValueListenableBuilder(
            valueListenable: rebuildInbox,
            builder: (context, bool value, child) {
              rebuildInbox.value = false;
              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final container = inbox[index];
                        dynamic results;
                        return _buildContainerItem(container); //!results
                      },
                      childCount: inbox.length,
                    ),
                  ),
                ],
              );
            }));
  }

  Widget _buildContainerItem(Map<String, dynamic> container) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getContainedItems(container["identity"]["UID"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final contents = snapshot.data ?? [];
        if (contents.isEmpty) {
          return _buildEmptyCard(container);
        }

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(container, contents),
              ...contents.map((item) => _buildContentItem(item)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item) {
    final itemType = item['template']['RALType'];
    if (itemType != 'coffee') {
      return _buildNestedContainer(item);
    } else {
      return _buildCoffeeItem(item);
    }
  }

  Widget _buildNestedContainer(Map<String, dynamic> container) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _databaseHelper.getContainedItems(container["identity"]["UID"]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          final nestedContents = snapshot.data ?? [];
          return ExpansionTile(
            // leading: Icon(Icons.inbox, color: Colors.black54),
            title: _buildCardHeader(container, nestedContents),
            children: [
              Column(
                children: nestedContents
                    .map((item) => _buildContentItem(item))
                    .toList(),
              )
            ],
          );
        });
  }

  Widget _buildCoffeeItem(Map<String, dynamic> coffee) {
    final appState = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          // Icon positioned at the top-left
          Padding(
              padding: const EdgeInsets.only(top: 6.0, right: 16.0),
              child: Image.asset(
                'assets/images/cappuccino.png',
                width: 24, // You can adjust the size here
                height: 24,
              )
              //  Icon(FontAwesomeIcons.seedling, color: Colors.brown, size: 24),
              ),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Coffee',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '[${getSpecificPropertyfromJSON(coffee, "species")}]',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w100,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Amount: ${getSpecificPropertyfromJSON(coffee, "amount")} ${getSpecificPropertyUnitfromJSON(coffee, "amount")}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Processing step: ${getSpecificPropertyfromJSON(coffee, "processingState")}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                FutureBuilder<Map<String, dynamic>>(
                  future: _databaseHelper.getFirstSale(coffee),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF35DB00),
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red, fontSize: 12));
                    }
                    final content = snapshot.data ?? {};
                    if (content.isEmpty) {
                      return Text("No plot found",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 12));
                    }
                    final field = content["inputObjects"][1];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "bought on ${formatTimestamp(content["existenceStarts"]) ?? "unknown"}",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          'from plot: ${truncateUID(field["identity"]["alternateIDs"][0]["UID"])}',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: Color(0xFF35DB00),
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('Error'),
        subtitle: Text(error),
      ),
    );
  }

  Widget _buildEmptyCard(Map<String, dynamic> container) {
    final appState = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: ListTile(
          // leading:
          title: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: getContainerIcon(container["template"]["RALType"]),
                ),
                SizedBox(width: 12),
                Text(
                    '${getContainerTypeName(container["template"]["RALType"], context)} ${container["identity"]["alternateIDs"][0]["UID"]}\nis empty'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      Map<String, dynamic> container, List<Map<String, dynamic>> contents) {
    final databaseHelper = DatabaseHelper();
    final appState = Provider.of<AppState>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 0, 0),
          child: Row(
            children: [
              SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                        child:
                            getContainerIcon(container["template"]["RALType"]),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${getContainerTypeName(container["template"]["RALType"], context)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  Text(
                    '[ID: ${truncateUID(container["identity"]["alternateIDs"][0]["UID"])}]',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w100,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF35DB00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              showChangeContainerDialog(context, container);
              String ownerUID = FirebaseAuth.instance.currentUser!.uid;
              ownerUID = "OSOHGLJtjwaGU2PCqajgfaqE5fI2"; //!REMOVE
              inbox = await databaseHelper.getInboxItems(ownerUID);
              inboxCount.value = inbox.length;
              rebuildInbox.value = true;
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.output, size: 24),
                SizedBox(width: 8),
                Text(
                  "move to container",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: Color(0xFF35DB00),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget getContainerIcon(String containerType) {
    switch (containerType) {
      case "bag":
        return Icon(Icons.shopping_bag);
      case "container":
        return Icon(Icons.inventory_2);
      case "building":
        return Icon(Icons.business);
      case "transportVehicle":
        return Icon(Icons.local_shipping);

      default:
        return Icon(Icons.help);
    }
  }

  String getContainerTypeName(String containerType, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (containerType) {
      case "bag":
        return l10n.bag;
      case "container":
        return l10n.container;
      case "building":
        return l10n.building;
      case "transportVehicle":
        return l10n.transportVehicle;

      default:
        return l10n.container;
    }
  }
}
