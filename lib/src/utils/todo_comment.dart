/// Generate the `TODO` comment
String todoComment(String code) => '// TODO: Add `$code` language translation';

/// Check if [line] contains `TODO`
bool containsTodoComment(String line) => line.contains('// TODO:');
