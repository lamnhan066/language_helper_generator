String todoComment(String code) => '// TODO: Add `$code` language translation';

bool containsTodoComment(String line) => line.contains('// TODO:');
