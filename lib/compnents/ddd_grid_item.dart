import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class DDDGridItem extends StatelessWidget {
  final String imgUrl; // 图片url
  final String name; // 图片名称
  final String lastModified; // 上传时间(阿里云解释是最后修改时间)

  DDDGridItem({
    @required this.imgUrl,
    @required this.name,
    @required this.lastModified,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        _copyImgUrl();
      },
      onTap: () {
        _showOriginalImage(context);
      },
      child: Tooltip(
        message: '单击查看大图, 双击复制链接',
        child: Card(
          color: Colors.black,
          elevation: 5,
          child: Stack(
            children: [
              Center(
                child: Container(
                  color: Colors.black,
                  child: Visibility(
                    visible: imgUrl.length > 0,
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/placeholder.png',
                      // 阿里云图片处理获取缩略图(宽高200, fit)
                      image:
                          '$imgUrl?x-oss-process=image/resize,mLfit,h_200,w_200',
                    ),
                    replacement: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name',
                        style: TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        '$lastModified',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 复制到剪切板
  void _copyImgUrl() {
    if (imgUrl.length > 0) {
      Clipboard.setData(
        ClipboardData(text: imgUrl),
      );
      EasyLoading.showToast('图片链接已复制到剪切板\n$imgUrl');
    }
  }

  /// 显示大图
  void _showOriginalImage(BuildContext context) {
    if (imgUrl.length > 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              child: Image.network('$imgUrl'),
            ),
          );
        },
      );
    }
  }
}
