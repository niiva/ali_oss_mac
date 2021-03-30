import 'package:ali_oss_mac/compnents/ddd_grid_item.dart';
import 'package:ali_oss_mac/network/aliyun_oss.dart';
import 'package:file_picker_cross/file_picker_cross.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScrollController _controller;
  AliyunOSS _aliyunOSS;
  List<OSSObjectInfo> _resultList;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();

    // 初始化EasyLoading
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.cubeGrid
      ..maskColor = Color.fromRGBO(0, 0, 0, 0.8);

    // 初始化AliyunOSS
    String accessKeyID = '<your access key id>';
    String accessKeySecret = '<your access key secret>';
    String bucketName = '<your bucket>';
    String endPoint = '<your end point>'; // 例oss-cn-beijing.aliyuncs.com
    String privateDomain = '<your private domain>'; // 例https://images.xxxx.com

    _aliyunOSS = AliyunOSS(
      accessKeyID: accessKeyID,
      accessKeySecret: accessKeySecret,
      endPoint: endPoint,
      bucketName: bucketName,
      privateDomain: privateDomain,
    );

    // 初始化_resultList
    _resultList = [];

    // 请求资源列表
    _listObjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          '当前bucket:<${_aliyunOSS.bucketName}>'
          '(文件总数${_resultList.length})',
          style: TextStyle(
            color: Colors.black38,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _selectFile();
            },
            icon: Icon(
              Icons.upload_file,
              color: Colors.black38,
            ),
            tooltip: '上传文件',
          ),
        ],
      ),
      body: Scrollbar(
        isAlwaysShown: true,
        controller: _controller,
        child: Container(
          margin: EdgeInsets.all(10),
          child: GridView.builder(
            controller: _controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _resultList.length,
            itemBuilder: (context, index) {
              OSSObjectInfo info = _resultList[index];
              return Container(
                alignment: Alignment.center,
                child: DDDGridItem(
                  imgUrl: info.url,
                  name: info.name,
                  lastModified: info.lastModified,
                  deleteCallback: (name) {
                    _deleteObject(name);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 请求资源列表
  void _listObjects() async {
    EasyLoading.show(status: '正在加载资源...');
    await _aliyunOSS.listObjects().then(
      (value) {
        setState(() {
          _resultList = value;
        });
        EasyLoading.dismiss();
      },
    );
  }

  /// 上传图片
  void _uploadObject(FilePickerCross file) async {
    await _aliyunOSS
        .postObject(
      file,
    )
        .then(
      (value) {
        OSSObjectInfo info = _resultList.firstWhere(
          (element) {
            return element.name == value.name;
          },
        );
        info.name = value.name;
        info.lastModified = value.lastModified;
        info.url = value.url;
        setState(() {});
      },
    );
  }

  /// 删除
  void _deleteObject(String objName) async {
    await _aliyunOSS
        .deleteObject(
      objName,
    )
        .then(
      (value) {
        _resultList.removeWhere(
          (element) {
            return element.name == value;
          },
        );
        setState(() {});
        EasyLoading.showSuccess('$value已永久删除');
      },
    );
  }

  /// 选择图片
  void _selectFile() async {
    await FilePickerCross.importMultipleFromStorage(
      type: FileTypeCross.image,
      fileExtension: 'JPG,JPEG,PNG,BMP,GIF,WebP,TIFF',
    ).then(
      (value) {
        List sameNameList = [];
        List tooLargeList = [];
        for (var i = 0; i < value.length; i++) {
          FilePickerCross file = value[i];

          // 重名校验
          for (var j = 0; j < _resultList.length; j++) {
            OSSObjectInfo info = _resultList[j];
            if (file.fileName == info.name) {
              sameNameList.add(file.path);
            }
          }

          // 文件过大校验
          if (file.length > 20 * 1024 * 1024) {
            tooLargeList.add(file.path);
          }
        }
        if (sameNameList.length > 0) {
          EasyLoading.showToast(
            '以下文件与服务器文件名称重复, 请改名后再次选择上传:\n'
            '${sameNameList.join('\n')}',
            duration: Duration(minutes: 1),
            maskType: EasyLoadingMaskType.custom,
            dismissOnTap: true,
          );
          return;
        }

        if (tooLargeList.length > 0) {
          EasyLoading.showToast(
            '以下文件过大(超过20M), 不能上传:\n'
            '${tooLargeList.join('\n')}',
            duration: Duration(minutes: 1),
            maskType: EasyLoadingMaskType.custom,
            dismissOnTap: true,
          );
          return;
        }

        for (var i = 0; i < value.length; i++) {
          FilePickerCross file = value[i];
          OSSObjectInfo info = OSSObjectInfo(
            name: file.fileName,
            lastModified: '',
            url: '',
          );
          this.setState(() {
            _resultList.insert(0, info);
          });
          _uploadObject(file);
        }
      },
    ).onError(
      (error, stackTrace) {
        print('取消选择');
      },
    );
  }
}
