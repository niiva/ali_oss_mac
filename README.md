### 个人练习项目, 基于`Flutter`的`mac`端 阿里云 oss(listObjects&postObject)

- 基于阿里云 `OSS REST API` 做的 `mac` 端(移动端也能跑起来, 没做适配)
- 纯个人练习项目, 如果能碰巧帮助到需要的朋友, 那我甚是开心^ ^
- 今天是学习 `Flutter` 的第 `23` 天, 纪念一下;

![图1](https://images.jindu.link/aliyunoss_mac1.png)
![图2](https://images.jindu.link/aliyunoss_mac2.png)

### 食用指南@.@

- `main_page.dart` 中初始化如下字段:

  ```dart
  // 初始化AliyunOSS
  String accessKeyID = '<your access key id>';
  String accessKeySecret = '<your access key secret>';
  String bucketName = '<your bucket>';
  String endPoint = '<your end point>'; // 例oss-cn-beijing.aliyuncs.com
  String privateDomain = '<your private domain>';// 例https://images.xxxx.com

  // privateDomain指的是阿里云oss绑定的个人域名
  // 非必填字段
  // 非空的时候 图片url为privateDomain/imgName.type
  // 为空的时候 图片url为https://bucketName.endPoint/imgName.type
  ```

- `macos`配置
  - `DebugProfile.entitlements`和`Release.entitlements`中都需要加入:
    ```xml
    <!-- 网络请求client权限 -->
    <key>com.apple.security.network.client</key>
    <true/>
    <!-- 文件读取权限 -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    ```

### 使用的包和参考的代码

- 三方库
  ```yaml
  dio: ^3.0.10 # dio网络请求
  crypto: ^3.0.0 # 加密算法包
  intl: ^0.17.0 # 时间日期格式化工具
  xml: ^5.0.2 # xml解析工具
  flutter_easyloading: ^3.0.0 # loading组件
  file_picker_cross: ^4.3.0 # 文件选择组件
  ```
- 参考代码:
  - [阿里云 OSS SDK Node.js](https://github.com/ali-sdk/ali-oss?spm=a2c4g.11186623.2.10.531526fd0vHN4r)
  - [阿里云 OSS SDK Python](https://github.com/aliyun/aliyun-oss-python-sdk?spm=a2c4g.11186623.2.4.910f46a1BYLLM4)
  - [一位前辈写的 Demo](https://github.com/luozhang002/postflutter-demo)

### 一些遗留问题

- 阿里云上传文件目前使用`post`方式, 个人觉得`put`方式更合适, 不过一直没有调通, 希望有大神指点!
- 图片缓存问题, 这个开始加了, 后来发现自己有替换图片的需求, 图片缓存本地存储, 还要做刷新, 就去掉了, 等想一套完整的解决方案再加上;
- 调试卡顿的问题, 小项目页面主要是`GridView`, 调试的时候快速滑动有卡顿的问题, 后来`flutter build macos`看`release`版的时候又很流畅#.#, 百思不得其解;

### 更新日志:

- 2021-03-30 新增删除功能(deleteObject)
