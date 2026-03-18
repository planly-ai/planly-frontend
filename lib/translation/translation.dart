import 'package:get/get.dart';
import 'package:planly_ai/translation/en_us.dart';
import 'package:planly_ai/translation/zh_cn.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': EnUs().messages,
    'zh_CN': ZhCN().messages,
  };
}

