import 'package:get/get.dart';
import 'package:planly_ai/translation/ar_ar.dart';
import 'package:planly_ai/translation/de_de.dart';
import 'package:planly_ai/translation/en_us.dart';
import 'package:planly_ai/translation/es_es.dart';
import 'package:planly_ai/translation/fa_ir.dart';
import 'package:planly_ai/translation/fr_fr.dart';
import 'package:planly_ai/translation/it_it.dart';
import 'package:planly_ai/translation/ko_kr.dart';
import 'package:planly_ai/translation/pl_pl.dart';
import 'package:planly_ai/translation/ru_ru.dart';
import 'package:planly_ai/translation/zh_cn.dart';
import 'package:planly_ai/translation/zh_tw.dart';
import 'package:planly_ai/translation/tr_tr.dart';
import 'package:planly_ai/translation/vi_vn.dart';
import 'package:planly_ai/translation/pt_pt.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ru_RU': RuRu().messages,
    'en_US': EnUs().messages,
    'zh_CN': ZhCN().messages,
    'zh_TW': ZhTw().messages,
    'fa_IR': FaIr().messages,
    'ar_AR': ArAr().messages,
    'es_ES': EsEs().messages,
    'fr_FR': FrFr().messages,
    'de_DE': DeDe().messages,
    'it_IT': ItIt().messages,
    'tr_TR': TrTr().messages,
    'vi_VN': ViVn().messages,
    'ko_KR': KoKr().messages,
    'pt_PT': PtPt().messages,
    'pl_PL': PlPl().messages,
  };
}
