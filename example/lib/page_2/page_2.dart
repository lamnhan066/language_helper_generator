import 'package:example/resources/language_helper/language_data.dart';
import 'package:language_helper/language_helper.dart';

final text1 = "Hello, world! 3".tr;
final text2 = 'This is a "quoted" string 3'.trT(LanguageCodes.aa);
final text3 = "This is a 'quoted' string 4".trP({'param': 'value'});
final text4 =
    'This is a string with @{num} parameters 4'.trF(params: {'num': 2});

final text5 = languageHelper.translate('This is a "quoted" string 5');
final text51 =
    languageHelper.translate('This is a "quoted" string 5', params: {});
final text6 = languageHelper.translate("This is a 'quoted' string 5");
final text61 =
    languageHelper.translate("This is a 'quoted' string 5", params: {});
