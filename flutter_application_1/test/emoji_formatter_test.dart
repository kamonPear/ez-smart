import 'package:flutter/services.dart';
import 'package:flutter_application_1/widgets/ez_form_field.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _v(String t) =>
    TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));

void main() {
  test('NoEmojiFormatter strips emoji but keeps symbols/Thai/English', () {
    var rejected = 0;
    final f = NoEmojiFormatter(onRejected: () => rejected++);

    expect(f.formatEditUpdate(_v(''), _v('IB (H120)-@#/. นิวคาสเซิล')).text,
        'IB (H120)-@#/. นิวคาสเซิล');
    expect(rejected, 0);

    expect(f.formatEditUpdate(_v(''), _v('ยา😀A❤️B👍🏽')).text, 'ยาAB');
    expect(rejected, 1);
  });
}
