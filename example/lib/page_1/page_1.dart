import 'package:example/page_2/page_2.dart';
import 'package:language_helper/language_helper.dart';

final text1 = "Hello, world! 1".tr;
final text2 = 'This is a "quoted" string 1'.trT();
final text3 = "This is a 'quoted' string 1".trP({'param': 'value'});
final text4 =
    'This is a string with @{num} parameters 1'.trF(params: {'num': 2});

final text5 =
    "Hello, wsa fa;senf jb awbdfb hkbkahbfwlbljbwa bjfbenqbfolaejbcfoj oljbnjafjlbqorld! 1"
        .tr;

final text6 = 'Hello, wsa fa;senf jb awbdfrr b hkbkahbfwlbljbwa '
        'bjfbenqbfolaejbcfoj oljbnjafjlbqorld! 1'
    .tr;

final text7 = languageHelper.translate(text6);

const somgthingBehindText7 = 'This thing is behind text 7';

final text8 = 'This text contains variable $text7'.tr;
