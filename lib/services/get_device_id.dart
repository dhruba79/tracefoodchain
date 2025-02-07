export 'get_device_id_stub.dart'
    if (dart.library.html) 'get_device_id_web.dart'
    if (dart.library.io) 'get_device_id_mobile.dart';
