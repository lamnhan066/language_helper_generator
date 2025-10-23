String todoComment(String code) =>
    '// TODO: Translate this text to $code language';

bool containsTodoComment(String line) =>
    line.contains('TODO: Translate this text to');
