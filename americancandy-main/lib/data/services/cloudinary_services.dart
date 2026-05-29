import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../utils/constants/apis.dart';
import '../../utils/constants/keys.dart';

class CloudinaryServices extends GetxController{
  static CloudinaryServices get instance => Get.find();

  /// Variables
  final _dio = dio.Dio();

  /// [UploadImage] - Function to upload Image
  Future<dio.Response> uploadImage(File image, String folderName) async{
    try{

      String api = UApiUrls.uploadApi(UKeys.cloudName);

      final formData = dio.FormData.fromMap({
        'upload_preset' : UKeys.uploadPreset,
        'folder' : folderName,
        'file' : await dio.MultipartFile.fromFile(image.path, filename: image.path.split('/').last)
      });

      dio.Response response = await _dio.post(api, data: formData);

      return response;

    }catch(e){
      throw 'Failed to upload profile picture. Please try again';
    }
  }

  /// [DeleteImage] - Function to delete Image
  Future<dio.Response> deleteImage(String publicId) async{
    try{

      String api = UApiUrls.deleteApi(UKeys.cloudName);

      int timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      String signatureBase = 'public_id=$publicId&timestamp=$timestamp${UKeys.apiSecret}';
      String signature = sha1.convert(utf8.encode(signatureBase)).toString();

      final formData = dio.FormData.fromMap({
        'public_id' : publicId,
        'api_key' : UKeys.apiKey,
        'timestamp' : timestamp,
        'signature': signature
      });

      dio.Response response = await _dio.post(api, data: formData);

      return response;
    }catch(e){
      throw 'Something went wrong. Please try again';
    }
  }
}