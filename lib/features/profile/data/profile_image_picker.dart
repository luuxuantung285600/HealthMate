import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_appearance.dart';
import '../models/profile_failure.dart';

final profileImagePickerProvider = Provider<ProfileImagePicker>(
  (ref) => DeviceProfileImagePicker(ImagePicker()),
);

abstract interface class ProfileImagePicker {
  Future<ProfileImage?> pick(ProfileImageSlot slot);
}

class DeviceProfileImagePicker implements ProfileImagePicker {
  DeviceProfileImagePicker(this._picker);
  final ImagePicker _picker;

  @override
  Future<ProfileImage?> pick(ProfileImageSlot slot) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      if (await file.length() > 8 * 1024 * 1024) {
        throw const ProfileFailure('Ảnh quá lớn. Hãy chọn ảnh dưới 8 MB.');
      }
      return await prepareProfileImage(await file.readAsBytes(), slot);
    } on ProfileFailure {
      rethrow;
    } catch (_) {
      throw const ProfileFailure(
        'Chưa thể mở ảnh. Hãy cho phép chọn ảnh hoặc thử một ảnh khác.',
      );
    }
  }
}

/// Center-crop, resize and re-encode pixels. No filename, location or EXIF is saved.
Future<ProfileImage> prepareProfileImage(
  Uint8List input,
  ProfileImageSlot slot,
) async {
  if (input.isEmpty || input.length > 8 * 1024 * 1024) {
    throw const ProfileFailure('Ảnh không hợp lệ hoặc lớn hơn 8 MB.');
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? source;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(input);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width > 20000 ||
        descriptor.height > 20000 ||
        descriptor.width * descriptor.height > 40000000) {
      throw const ProfileFailure(
        'Độ phân giải ảnh quá lớn. Hãy chọn ảnh nhỏ hơn.',
      );
    }
    final decodeScale = math.min(
      1.0,
      math.max(slot.width / descriptor.width, slot.height / descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * decodeScale).round()),
      targetHeight: math.max(1, (descriptor.height * decodeScale).round()),
    );
    source = (await codec.getNextFrame()).image;
    final sourceSize = Size(source.width.toDouble(), source.height.toDouble());
    final destinationSize = Size(slot.width.toDouble(), slot.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, destinationSize);
    final crop = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & sourceSize,
    );
    for (var attempt = 0; attempt < 9; attempt++) {
      final scale = math.pow(.78, attempt).toDouble();
      final width = math.max(24, (slot.width * scale).round());
      final height = math.max(24, (slot.height * scale).round());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        source,
        crop,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final output = await picture.toImage(width, height);
      try {
        final encoded = await output.toByteData(format: ui.ImageByteFormat.png);
        if (encoded != null && encoded.lengthInBytes <= ProfileImage.maxBytes) {
          return ProfileImage.fromPng(
            encoded.buffer.asUint8List(
              encoded.offsetInBytes,
              encoded.lengthInBytes,
            ),
          );
        }
      } finally {
        output.dispose();
        picture.dispose();
      }
    }
    throw const ProfileFailure('Chưa thu nhỏ được ảnh. Hãy chọn ảnh khác.');
  } on ProfileFailure {
    rethrow;
  } catch (_) {
    throw const ProfileFailure(
      'Không đọc được ảnh này. Hãy chọn ảnh JPG hoặc PNG khác.',
    );
  } finally {
    source?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
