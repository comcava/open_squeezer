// TODO: delete this file

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as l_img;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const images = ["city.jpg", "city-blur.jpg", "human-blur.jpg"];

  final selectedImg = images[0];
  Uint8List? _byte;

  double varianceNum = 0;

  @override
  void initState() {
    super.initState();

    _init();
  }

  double mean(Uint8List bytes) {
    int sum = bytes.reduce((value, element) => value += element);
    int n = bytes.length;

    return sum / n;
  }

  // from https://stackoverflow.com/a/47252945/14110680
  double variance(Uint8List bytes) {
    // vec <- c(3, 5, 4, 3, 6, 7, 3, 6, 4, 6, 3, 4, 1, 3, 4, 4)
    // n <- length(vec)
    // average <- mean(vec)
    // differences <- vec - average
    // squared.differences <- differences^2
    // sum.of.squared.differences <-  sum(squared.differences)
    // estimator <- 1/(n - 1)
    // estimated.variance <- estimator * sum.of.squared.differences
    // estimated.variance
    // [1] 2.383333
    // var(vec) == estimated.variance # The "hand calculated" variance equals the variance in the stats package.
    // [1] TRUE

    print("======== bytes: ");
    for (var b in bytes.take(500)) {
      print("  $b");
    }
    print("========");

    var n = bytes.length;
    print("got n: $n");

    var average = mean(bytes);

    print("got average: $average");

    double sq_differences_sum = 0;

    for (var byte in bytes) {
      var diff = byte - average;
      sq_differences_sum += diff * diff;
    }

    print("sq sum: $sq_differences_sum");

    var variance = sq_differences_sum / (n - 1);

    print("got variance: $variance");

    return variance;
  }

// based on https://pyimagesearch.com/2015/09/07/blur-detection-with-opencv/
  _init() async {
    Future<String> saveFile(Uint8List data) async {
      Directory tempDir = await getTemporaryDirectory();

      String tempPath = "${tempDir.path}/$selectedImg";

      await File(tempPath).writeAsBytes(data);

      print("made temp path: $tempPath");

      return tempPath;
    }

    final rawImage = await rootBundle.load("assets/test/$selectedImg");

    print("raw image len: ${rawImage.buffer.lengthInBytes}");

    final bytes =
        await resizeImage(Uint8List.view(rawImage.buffer), width: 200);

    print("resize image len: ${bytes!.lengthInBytes}");

    var smallPath = await saveFile(bytes.buffer.asUint8List());

    var grayBytes = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: smallPath,
      outputType: Cv2.COLOR_BGR2GRAY,
    );

    print("gray bytes len: ${grayBytes!.length}, ${grayBytes.lengthInBytes}");

    var grayPath = await saveFile(grayBytes);

    var filteredBytes = await Cv2.laplacian(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: grayPath,
      depth: 1,
    );

    print(
        "filtered bytes len: ${filteredBytes!.length}, ${filteredBytes.lengthInBytes}");

    var decoded = l_img.decodeImage(filteredBytes);

    var decodedByte = decoded!.getBytes(format: l_img.Format.luminance);

    print("== decoded bytes: ==============");
    for (var b in decodedByte.take(50)) {
      print("  $b");
    }
    print("=============================");

    // _byte = decodedByte;

    print("decoded bytes len: ${decodedByte.length}");

    // setState(() {
    //   _byte;
    // });

    varianceNum = variance(decodedByte);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("blur detector"),
      ),
      body: ListView(
        children: [
          SizedBox(height: 50),
          SizedBox(
            height: 300,
            child: Image.asset("assets/test/$selectedImg"),
          ),
          SizedBox(height: 50),
          Text(
            "variance: $varianceNum",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 50),
          if (_byte != null)
            SizedBox(
              height: 300,
              child: Image.memory(_byte!, fit: BoxFit.contain),
            ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
