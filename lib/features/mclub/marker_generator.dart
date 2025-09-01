import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  static Future<BitmapDescriptor> fromWidget(
    Widget widget, {
    required Size size,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      window: WidgetsBinding.instance.window,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        size: size,
        devicePixelRatio: WidgetsBinding.instance.window.devicePixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner();
    renderView.attach(pipelineOwner);
    pipelineOwner.rootNode = renderView;

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(root);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(
      pixelRatio: WidgetsBinding.instance.window.devicePixelRatio,
    );
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(
      bytes!.buffer.asUint8List(),
      size: size,
    );
  }
}

