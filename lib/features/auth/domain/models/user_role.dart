enum UserRole {
  user,
  admin,
  agent;

  bool get isAdmin => this == UserRole.admin;
  bool get isAgent => this == UserRole.agent;
}
