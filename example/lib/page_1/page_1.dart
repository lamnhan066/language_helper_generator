import 'package:language_helper/language_helper.dart';

final text1 = "Hello, world! 1".tr;
final text2 = 'This is a "quoted" string 1'.trT();
final text3 = "This is a 'quoted' string 1".trP({'param': 'value'});
final text4 =
    'This is a string with @{num} parameters 1'.trF(params: {'num': 2});
