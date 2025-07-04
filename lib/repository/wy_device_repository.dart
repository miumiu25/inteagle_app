import 'package:inteagle_app/models/device.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class WyDeviceRepository {
  WyDeviceRepository();

  get database async {
    await DeviceDatabase().database;
  }

  Future<void> saveDevice(Device device) async {
    final db = await DeviceDatabase().database;

    final result = await db.insert(
      'device',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Device saved with id: $result");
  }

  Future<List<Device>> getSavedDevices() async {
    final db = await DeviceDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query('device');

    return List.generate(maps.length, (i) {
      return Device.fromMap(maps[i]);
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    final db = await DeviceDatabase().database;

    var result = await db.delete(
      'device',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    print("Device deleted with id: $result");
  }

  // Future<WyDeviceAttribute> getDeviceAttributes(String deviceId) async {
  //   String errorMsg = "";
  //   try {
  //     var result = await HttpUtil.instance.client.get('/attribute');

  //     if (result.data != null) {
  //       if (result.data['data'] != null && result.data['data']['shared'] != null) {
  //         final shared = result.data['data']['shared'];

  //         // debugPrint("Device attribute data: ${json.encode(shared)}");
  //         try {
  //           WyDeviceAttribute deviceAttribute = WyDeviceAttribute.fromJson(
  //               shared);
  //           debugPrint("Device attribute data==>: ${deviceAttribute.toJson()}");

  //           // 缓存设备属性到数据库
  //           await _cacheDeviceAttribute(deviceId,deviceAttribute);

  //           //测试代码块
  //           if (kDebugMode) {
  //             try {
  //               final cachedAttribute = await _getCachedDeviceAttribute(deviceId);
  //               if (cachedAttribute==null){
  //                 debugPrint("缓存的设备属性失败，取值为空");
  //               }else if (cachedAttribute.toJson().toString() != deviceAttribute.toJson().toString()) {
  //                 debugPrint("缓存的设备属性与保存的属性不一致");
  //                 debugPrint("cached: ${cachedAttribute.toJson()}");
  //               }
  //             } catch (cacheError) {
  //               debugPrint("Error reading cached device attribute: $cacheError");
  //             }
  //           }

  //           return deviceAttribute;
  //         }catch (e) {
  //           debugPrint("Error parsing device attribute data: $e");
  //           throw Exception('Failed to parse device attribute data');
  //         }

  //       }
  //     }
  //     throw Exception('Failed to parse device attribute data');
  //   } catch (e) {
  //     print(e);
  //     errorMsg = e.toString();

  //     // HTTP请求失败时，尝试从数据库获取缓存的设备属性
  //     try {
  //       final cachedAttribute = await _getCachedDeviceAttribute(deviceId);
  //       if (cachedAttribute != null) {
  //         debugPrint("Using cached device attribute data");
  //         return cachedAttribute;
  //       }
  //     } catch (cacheError) {}

  //     throw Exception('Request error: $errorMsg');
  //   }
  // }

  // /// 缓存设备属性到数据库
  // Future<void> _cacheDeviceAttribute(String deviceId,WyDeviceAttribute deviceAttribute) async {
  //   try {
  //     final db = await DeviceDatabase().database;
  //     final attributeJson = json.encode(deviceAttribute.toJson());
  //     // 由于 WyDeviceAttribute 是个复杂的对象类型，目前是将其作为 json 整体存取
  //     await db.insert(
  //       'device_attribute',
  //       {
  //         'device_id': deviceId,
  //         'key': 'device_attribute_cache',
  //         'value': attributeJson,
  //         'type': 'json',
  //         'update_time': DateTime.now().millisecondsSinceEpoch,
  //       },
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   } catch (e) {
  //     debugPrint("Error caching device attribute: $e");
  //   }
  // }

  // /// 从数据库获取缓存的设备属性
  // Future<WyDeviceAttribute?> _getCachedDeviceAttribute(String deviceId) async {
  //   try {
  //     final db = await DeviceDatabase().database;
  //     final List<Map<String, dynamic>> maps = await db.query(
  //       'device_attribute',
  //       where: 'device_id = ? AND key = ?',
  //       whereArgs: [deviceId, 'device_attribute_cache'],
  //       limit: 1,
  //     );

  //     if (maps.isNotEmpty) {
  //       final cachedData = maps.first;
  //       final attributeJson = cachedData['value'] as String;
  //       final attributeMap = json.decode(attributeJson) as Map<String, dynamic>;

  //       return WyDeviceAttribute.fromJson(attributeMap);
  //     }

  //     return null;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // WyDeviceStatus _parseDeviceStatus(String status) {
  //   switch (status) {
  //     case '0':
  //       return WyDeviceStatus.initializing;
  //     case '1':
  //       return WyDeviceStatus.measuring;
  //     case '2':
  //       return WyDeviceStatus.idle;
  //     case '3':
  //       return WyDeviceStatus.testing;
  //     default:
  //       return WyDeviceStatus.idle;
  //   }
  // }

  // Future<void> saveDeviceAttribute(key, value) async {

  //   //这里使用json包装
  //   Map map = new Map<String, dynamic>();
  //   map['method'] = 'wySetAttributes';
  //   map['params'] = {key:value};

  //   var result = await HttpUtil.instance.client.post('/rpc', data: map);
  //   print("data =>>>>>>>>>>>.${result}");

  // }

  // Future<void> saveDeviceAttributes(WyDeviceAttribute attribute) async {

  //   //这里使用json包装
  //   Map map = new Map<String, dynamic>();
  //   map['method'] = 'wySetAttributes';
  //   map['params'] = attribute;

  //   var result = await HttpUtil.instance.client.post('/rpc', data: map);
  //   print("data =>>>>>>>>>>>.${result}");

  // }

  // Future<dynamic> startFactoryCalibration(FactoryCalibration param) async {
  //   try {
  //     debugPrint("startFactoryCalibration param => ${param.toMap()}");

  //     final map = <String, dynamic>{
  //       'method': 'wyFactoryCalibration',
  //       'params': param.toMap(),
  //     };

  //     final result = await HttpUtil.instance.client.post('/rpc', data: map);
  //     debugPrint("Factory calibration response: ${result.data}");
  //     return result.data;
  //   } catch (e) {
  //     String errorMessage = e is DioException
  //         ? (e.response?.data != null
  //         ? (e.response?.data['msg'] ?? e.response?.data.toString())
  //         : e.message ?? e.toString())
  //         : e.toString();
  //     throw Exception("$errorMessage");
  //   }
  // }

  // Future<Map<int, List<String>>> loadHistoryImage(deviceId) async {
  //   final Map<int, List<String>> history =  {};

  //   final directory = await getApplicationDocumentsDirectory();

  //   String savePath = "${directory.path}/cameraImage/$deviceId";
  //   var dir = Directory(savePath);
  //   // 检查目录是否存在
  //   if (await dir.exists()) {
  //     List<String> subDirectories = [];
  //     try {
  //       await for (var entity in dir.list()) {
  //         if (entity is Directory) {
  //           // 目录名为摄像头id
  //           String folderName = entity.path.split('/').last;
  //           subDirectories.add(folderName);

  //           // 解析时间戳
  //           int cameraId;
  //           try {
  //             cameraId = int.parse(folderName);
  //           } catch (e) {
  //             debugPrint("无法解析时间戳: $folderName");
  //             continue;
  //           }

  //           List<String> cameraImages = [];
  //           Directory cameraIdDir = Directory("$savePath/$folderName");

  //           await for (var file in cameraIdDir.list()) {
  //             if (file is File) {
  //               String fileName = file.path.split('/').last;
  //               RegExp regExp = RegExp(r'_image_(\d+)\.jpg');
  //               var match = regExp.firstMatch(fileName);
  //               if (match != null) {
  //                 cameraImages.add(file.path) ;
  //               }
  //             }
  //           }
  //           if (cameraImages.isNotEmpty) {
  //             history[cameraId] = cameraImages;
  //           }
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint("读取目录时出错: $e");
  //     }
  //   }

  //   return history;

  // }
}
