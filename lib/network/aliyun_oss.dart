import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class AliyunOSS {
  final String accessKeyID;
  final String accessKeySecret;
  final String endPoint;
  final String bucketName;
  // privateDomain指的是阿里云oss绑定的个人域名
  // 非必填字段
  // 非空的时候 图片url为privateDomain/imgName.type
  // 为空的时候 图片url为https://bucketName.endPoint/imgName.type
  final String privateDomain;

  AliyunOSS({
    @required this.accessKeyID,
    @required this.accessKeySecret,
    @required this.endPoint,
    @required this.bucketName,
    this.privateDomain = '',
  });

  /// 列举bucket下文件
  Future<List<OSSObjectInfo>> listObjects() async {
    List<OSSObjectInfo> resultList;
    await _listObjects().then(
      (value) {
        // 返回结果按时间倒序
        // 即新上传的排在前面
        resultList = value;
        resultList.sort((a, b) {
          DateTime at = DateTime.parse(a.lastModified);
          DateTime bt = DateTime.parse(b.lastModified);
          return Comparable.compare(bt, at);
        });
      },
    );

    return resultList;
  }

  /// 上传文件
  ///
  /// 这里用的post方法上传, put方法一直没调通
  Future<OSSObjectInfo> postObject(FilePickerCross file) async {
    OSSObjectInfo info;

    String policyText = '{"expiration": "2120-01-01T12:00:00.000Z",'
        '"conditions": [["content-length-range", 0, 1048576000]]}';
    List<int> uPolicyText = utf8.encode(policyText);
    String bPolicyText = base64.encode(uPolicyText);
    List<int> policy = utf8.encode(bPolicyText);

    // 利用accessKeySecret签名Policy
    List<int> keyM = utf8.encode(accessKeySecret);
    List<int> signaturePre = new Hmac(sha1, keyM).convert(policy).bytes;
    String signature = base64.encode(signaturePre);

    Dio dio = Dio();
    // 构建formData数据
    FormData data = new FormData.fromMap({
      'key': file.fileName,
      'policy': bPolicyText,
      'OSSAccessKeyId': accessKeyID,
      'signature': signature,
      'file': MultipartFile.fromBytes(file.toUint8List()),
    });
    try {
      await dio
          .post(
        'https://$bucketName.$endPoint',
        data: data,
      )
          .then(
        (value) {
          info = OSSObjectInfo(
            name: file.fileName,
            lastModified:
                DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now()),
            url: privateDomain.length > 0
                ? '$privateDomain/${file.fileName}'
                : 'https://$bucketName.$endPoint/${file.fileName}',
          );
        },
      );
    } on DioError catch (e) {
      if (null != e.response) {
        print(e.response.data);
      }
    }

    return info;
  }

  // putObject方法没有调通
  // put的时候data: MultipartFile.fromBytes(file.toUint8List()),
  // 传上去 文件缺失
  //
  // Future putObject(FilePickerCross file) async {
  //   String date = _gmtTime();
  //   String sign = _sign(
  //     requestType: 'PUT',
  //     gmtTime: date,
  //     resource: '/$bucketName/${file.fileName}',
  //     contentType: 'application/octet-stream',
  //   );

  //   Dio dio = Dio()
  //     ..options.headers = {
  //       'Host': '$bucketName.$endPoint',
  //       'Date': '$date',
  //       'Authorization': 'OSS $accessKeyID:$sign',
  //       'Content-Type': 'application/octet-stream',
  //     };

  //   try {
  //     await dio.put(
  //       'https://$bucketName.$endPoint/${file.fileName}',
  //       data: MultipartFile.fromBytes(file.toUint8List()),
  //       onSendProgress: (count, total) {
  //         print(count / total);
  //       },
  //     ).then((value) {
  //       print('upload res:$value');
  //     });
  //   } on DioError catch (e) {
  //     if (null != e.response) {
  //       print(e.response.data);
  //     }
  //   }
  // }

  /// 删除object
  Future<String> deleteObject(String objName) async {
    String deleteSucceedName = '';
    String date = _gmtTime();
    String sign = _sign(
      requestType: 'DELETE',
      gmtTime: date,
      resource: '/$bucketName/$objName',
    );

    Dio dio = Dio()
      ..options.headers = {
        'Host': '$bucketName.$endPoint',
        'Date': '$date',
        'Authorization': 'OSS $accessKeyID:$sign',
      };

    try {
      await dio
          .delete(
        'https://$bucketName.$endPoint/$objName',
      )
          .then(
        (value) {
          deleteSucceedName = objName;
        },
      );
    } catch (e) {
      print(e.response.data);
    }

    return deleteSucceedName;
  }

  /// 请求结果可能需要递归
  ///
  /// 所以这里做了个私有方法
  Future<List<OSSObjectInfo>> _listObjects([String nextMaker = '']) async {
    List<OSSObjectInfo> resultList = [];
    String date = _gmtTime();
    String sign = _sign(
      requestType: 'GET',
      gmtTime: date,
      resource: '/$bucketName/',
    );

    Dio dio = Dio()
      ..options.headers = {
        'Host': '$bucketName.$endPoint',
        'Date': '$date',
        'Authorization': 'OSS $accessKeyID:$sign',
      };

    Map<String, dynamic> params = {};
    params['max-keys'] = 100;
    if (nextMaker.length > 0) {
      params['marker'] = nextMaker;
    }

    try {
      await dio
          .get(
        'https://$bucketName.$endPoint',
        queryParameters: params,
      )
          .then(
        (response) async {
          resultList = _infoListFromXML(xml: response.toString());
          // 阿里云oss的listObjects返回结果不支持排序
          // 如果需要按时间排序就要把所有结果都取回来本地处理
          String marker = _nextMaker(xml: response.toString());
          if (marker.length > 0) {
            await _listObjects(marker).then(
              (value) {
                resultList.addAll(value);
              },
            );
          }
        },
      );
    } on DioError catch (e) {
      if (null != e.response) {
        print(e.response.data);
      }
    }

    return resultList;
  }

  /// 生成GMT时间
  ///
  /// 需要localizations支持
  ///
  /// https://flutter.dev/docs/development/accessibility-and-localization/internationalization
  String _gmtTime() {
    String formatter = "EEE, dd MMM yyyy HH:mm:ss 'GMT'";
    DateTime utcTime = DateTime.now().toUtc();
    return DateFormat(formatter, 'en').format(utcTime);
  }

  /// 生成签名
  String _sign({
    @required String requestType,
    @required String gmtTime,
    @required String resource,
    String contentType = '',
  }) {
    // 待签名字符串
    // Signature = base64(hmac-sha1(AccessKeySecret,
    //    VERB + "\n"
    //    + Content-MD5 + "\n"
    //    + Content-Type + "\n"
    //    + Date + "\n"
    //    + CanonicalizedOSSHeaders
    //    + CanonicalizedResource))
    // 注意阿里云的文档里没写, Content-MD5和Content-Type为空时, \n需要保留
    String preSign = '$requestType\n\n$contentType\n$gmtTime\n$resource';
    List<int> uPreSign = utf8.encode(preSign);
    List<int> uSecret = utf8.encode(accessKeySecret);

    List<int> uSign = Hmac(sha1, uSecret).convert(uPreSign).bytes;
    String bSign = base64.encode(uSign);

    return bSign;
  }

  /// 解析xml
  List<OSSObjectInfo> _infoListFromXML({@required String xml}) {
    XmlDocument data = XmlDocument.parse(xml.toString());
    Iterable<XmlElement> contents = data.findAllElements('Contents');
    return contents.map((node) {
      String key = node.findElements('Key').single.text;
      String url = privateDomain.length > 0
          ? '$privateDomain/$key'
          : 'https://$bucketName.$endPoint/$key';
      String lastModified = node.findElements('LastModified').single.text;

      // 阿里云返回的时间是UTC时间
      // 需要计算本地时间与其差值
      // 加到返回结果才是 北京时间
      Duration timeOffSet = DateTime.now().timeZoneOffset;
      DateTime dt = DateTime.parse(lastModified).add(timeOffSet);
      String lm = DateFormat('yyyy-MM-dd hh:mm:ss').format(dt);

      return OSSObjectInfo(name: key, lastModified: lm, url: url);
    }).toList();
  }

  /// nextMarker
  ///
  /// 阿里云oss的listObjects结果不支持分页
  ///
  /// 需要自己指定marker
  ///
  /// https://help.aliyun.com/document_detail/31965.html?spm=a2c4g.11174283.6.1627.4e137da2I2wlwO#title-y1u-i17-jos
  String _nextMaker({@required String xml}) {
    XmlDocument data = XmlDocument.parse(xml.toString());
    String nextMarker;
    try {
      nextMarker = data.findAllElements('NextMarker').single.text;
    } catch (e) {
      nextMarker = '';
    }

    return nextMarker;
  }
}

class OSSObjectInfo {
  String name;
  String lastModified;
  String url;

  OSSObjectInfo({
    @required this.name,
    @required this.lastModified,
    @required this.url,
  });
}
