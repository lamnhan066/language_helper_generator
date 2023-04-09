import 'dart:io';

List<FileSystemEntity> listAllFiles(
  Directory dir,
  List<FileSystemEntity> fileList,
) {
  final files = dir.listSync(recursive: false);

  for (FileSystemEntity file in files) {
    if (file is File) {
      fileList.add(file);
    } else if (file is Directory) {
      fileList = listAllFiles(file, fileList);
    }
  }

  return fileList;
}
