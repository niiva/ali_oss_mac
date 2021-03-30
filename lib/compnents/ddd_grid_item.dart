import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class DDDGridItem extends StatelessWidget {
  final String imgUrl; // 图片url
  final String name; // 图片名称
  final String lastModified; // 上传时间(阿里云解释是最后修改时间)
  final ValueChanged deleteCallback; // 点击删除callback

  DDDGridItem({
    @required this.imgUrl,
    @required this.name,
    @required this.lastModified,
    @required this.deleteCallback,
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
              _widgetImage(),
              _widgetInfo(),
              _widgetDelete(),
            ],
          ),
        ),
      ),
    );
  }

  /// 图片
  Widget _widgetImage() {
    return Center(
      child: Container(
        color: Colors.black,
        child: Visibility(
          visible: imgUrl.length > 0,
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/images/placeholder.png',
            // 阿里云图片处理获取缩略图(宽高200, fit)
            image: '$imgUrl?x-oss-process=image/resize,mLfit,h_200,w_200',
          ),
          replacement: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 文字说明
  Widget _widgetInfo() {
    return Positioned(
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
    );
  }

  /// 右上角删除按钮
  Widget _widgetDelete() {
    return Positioned(
      top: 0,
      right: 0,
      child: PopupMenuButton(
        tooltip: '删除',
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.topRight,
          padding: EdgeInsets.only(
            top: 10,
            right: 10,
          ),
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 0, 0.8),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
            ),
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.red,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    '确认删除',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              value: true,
            ),
          ];
        },
        onSelected: (value) {
          deleteCallback(name);
        },
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
