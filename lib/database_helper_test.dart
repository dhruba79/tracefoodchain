// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:trace_foodchain_app/helpers/database_helper.dart';
// import 'package:trace_foodchain_app/services/api_service.dart';

// class MockApiService extends Mock implements ApiService {}

// void main() {
//   group('DatabaseHelper', () {
//     late DatabaseHelper databaseHelper;
//     late MockApiService mockApiService;

//     setUp(() {
//       mockApiService = MockApiService();
//       databaseHelper = DatabaseHelper();
//       databaseHelper._apiService = ApiService('https://your-api-url.com');
//     });

//     test('syncData success', () async {
//       final localData = {
//         'harvests': [
//           {'id': 1, 'crop_type': 'Wheat', 'quantity': 100},
//         ],
//         'inventory': [],
//         'transactions': [],
//         'deliveries': [],
//         'orders': [],
//       };

//       final serverData = {
//         'harvests': [
//           {'id': 1, 'crop_type': 'Wheat', 'quantity': 100},
//           {'id': 2, 'crop_type': 'Corn', 'quantity': 200},
//         ],
//         'inventory': [],
//         'transactions': [],
//         'deliveries': [],
//         'orders': [],
//       };

//       when(mockApiService.syncData(localData)).thenAnswer((_) async => serverData);

//       await databaseHelper.syncData();

//       // Verify that the local database was updated with the server data
//       final updatedHarvests = await databaseHelper.getHarvests();
//       expect(updatedHarvests.length, 2);
//       expect(updatedHarvests[1]['crop_type'], 'Corn');
//     });

//     test('syncData API error', () async {
//       when(mockApiService.syncData(any)).thenThrow(ApiException('API error'));

//       expect(() async => await databaseHelper.syncData(), throwsA(isA<DatabaseException>()));
//     });

//     test('addHarvest and getHarvests', () async {
//       final harvest = {
//         'crop_type': 'Tomato',
//         'quantity': 50,
//         'unit': 'kg',
//         'harvest_date': '2023-05-01',
//       };

//       await databaseHelper.insertHarvest(harvest);

//       final harvests = await databaseHelper.getHarvests();
//       expect(harvests.length, 1);
//       expect(harvests[0]['crop_type'], 'Tomato');
//       expect(harvests[0]['quantity'], 50);
//     });

//     // Add more tests for other CRUD operations and business logic
//   });
// }
