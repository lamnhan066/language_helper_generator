import 'package:language_helper/language_helper.dart';

final tr = r"""This is the same text""".tr;
final tr1 = """
        This is the same text
        """
    .tr;
const variable = '';
final tr2 = """This is a $variable text""".tr;
final tr3 = r"""This is a
          multi-lines text
          """
    .tr;
