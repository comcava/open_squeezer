import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// C function signatures
typedef _CVersionFunc = ffi.Pointer<Utf8> Function();
typedef _CLaplacianBlurFunc = ffi.Float Function(ffi.Pointer<Utf8>);

// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
typedef _LaplacianBlurFunc = double Function(ffi.Pointer<Utf8>);

// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib = Platform.isAndroid
    ? ffi.DynamicLibrary.open('libnative_opencv.so')
    : ffi.DynamicLibrary.process();

// Looking for the functions
final _VersionFunc _version =
    _lib.lookup<ffi.NativeFunction<_CVersionFunc>>('version').asFunction();
final _LaplacianBlurFunc _laplacianBlur = _lib
    .lookup<ffi.NativeFunction<_CLaplacianBlurFunc>>('laplacian_blur')
    .asFunction();

String opencvVersion() {
  ffi.Pointer<Utf8> versionStr = _version();
  return versionStr.toDartString();
}

double laplacianBlur(String inputPath) {
  var inputPathStr = inputPath.toNativeUtf8();
  var value = _laplacianBlur(inputPathStr);

  if (value == -1) {
    throw Exception("Error processing $inputPath");
  }

  return value;
}
