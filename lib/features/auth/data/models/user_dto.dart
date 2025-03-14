import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  
  @JsonKey(ignore: true)
  final bool isAdmin;
  
  @JsonKey(ignore: true)
  final String? authToken;

  UserDto({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    this.authToken,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => 
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  UserDto copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAdmin,
    String? authToken,
  }) {
    return UserDto(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      authToken: authToken ?? this.authToken,
    );
  }
}
