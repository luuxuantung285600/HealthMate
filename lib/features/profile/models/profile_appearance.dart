import 'dart:convert';
import 'dart:typed_data';

enum ProfileImageSlot {
  avatar('Ảnh đại diện', 160, 160),
  cover('Ảnh bìa', 640, 240),
  background('Ảnh nền hồ sơ', 400, 640);

  const ProfileImageSlot(this.label, this.width, this.height);
  final String label;
  final int width, height;
}

/// A small re-encoded thumbnail, never an original file, URL or EXIF payload.
class ProfileImage {
  ProfileImage._(this.encoded, this.bytes);
  static const maxBytes = 64 * 1024;
  static const maxEncodedLength = 87384;
  final String encoded;
  final Uint8List bytes;

  factory ProfileImage.fromPng(Uint8List bytes) {
    if (bytes.length < 24 ||
        bytes.length > maxBytes ||
        !const [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ].asMap().entries.every((entry) => bytes[entry.key] == entry.value)) {
      throw const FormatException(
        'Ảnh không hợp lệ hoặc vượt dung lượng cho phép.',
      );
    }
    final header = ByteData.sublistView(bytes);
    final width = header.getUint32(16), height = header.getUint32(20);
    if (width < 1 || height < 1 || width > 1024 || height > 1024) {
      throw const FormatException('Kích thước ảnh không hợp lệ.');
    }
    final copy = Uint8List.fromList(bytes).asUnmodifiableView();
    return ProfileImage._(base64Encode(copy), copy);
  }

  static ProfileImage? tryDecode(Object? value) {
    if (value is! String || value.length > maxEncodedLength) return null;
    try {
      return ProfileImage.fromPng(base64Decode(value));
    } on FormatException {
      return null;
    }
  }
}

class ProfileAppearance {
  const ProfileAppearance({this.avatar, this.cover, this.background});
  final ProfileImage? avatar, cover, background;

  factory ProfileAppearance.fromMap(Object? value) {
    if (value is! Map) return const ProfileAppearance();
    return ProfileAppearance(
      avatar: ProfileImage.tryDecode(value['avatar']),
      cover: ProfileImage.tryDecode(value['cover']),
      background: ProfileImage.tryDecode(value['background']),
    );
  }

  ProfileImage? image(ProfileImageSlot slot) => switch (slot) {
    ProfileImageSlot.avatar => avatar,
    ProfileImageSlot.cover => cover,
    ProfileImageSlot.background => background,
  };

  ProfileAppearance replace(ProfileImageSlot slot, ProfileImage? value) =>
      ProfileAppearance(
        avatar: slot == ProfileImageSlot.avatar ? value : avatar,
        cover: slot == ProfileImageSlot.cover ? value : cover,
        background: slot == ProfileImageSlot.background ? value : background,
      );

  Map<String, Object?> toMap() => {
    'avatar': avatar?.encoded,
    'cover': cover?.encoded,
    'background': background?.encoded,
  };

  bool sameAs(ProfileAppearance other) => ProfileImageSlot.values.every(
    (slot) => image(slot)?.encoded == other.image(slot)?.encoded,
  );
}

class ProfileIdentityDraft {
  const ProfileIdentityDraft({
    required this.displayName,
    required this.appearance,
  });
  final String displayName;
  final ProfileAppearance appearance;
}
