/// The type of Odoo user.
enum OdooUserType {
  /// Internal employee user (base.group_user).
  internal,

  /// Portal user (customers/vendors with portal access).
  portal,

  /// Public (unauthenticated or public) user.
  public,
}

/// Represents an authenticated Odoo session.
class OdooSession {
  /// The user's database ID.
  final int uid;

  /// The database name.
  final String db;

  /// The user's display name.
  final String name;

  /// The user's login (username/email).
  final String username;

  /// The user's company ID.
  final int companyId;

  /// The user's partner ID.
  final int partnerId;

  /// The user's context (lang, tz, etc.).
  final Map<String, dynamic> userContext;

  /// Whether the user has admin privileges.
  final bool isAdmin;

  /// Whether the user has system/superuser privileges.
  final bool isSystem;

  /// Whether this is an internal (employee) user.
  final bool isInternalUser;

  /// Whether this is a public (unauthenticated) user.
  final bool isPublic;

  /// The server version string.
  final String serverVersion;

  /// The session ID cookie value.
  final String? sessionId;

  /// The partner's display name (company + name).
  final String? partnerDisplayName;

  /// Map of allowed companies: `{id: {id, name, ...}}`.
  final Map<String, dynamic> allowedCompanies;

  const OdooSession({
    required this.uid,
    required this.db,
    required this.name,
    required this.username,
    required this.companyId,
    required this.partnerId,
    required this.userContext,
    required this.isAdmin,
    required this.isSystem,
    required this.isInternalUser,
    required this.isPublic,
    required this.serverVersion,
    this.sessionId,
    this.partnerDisplayName,
    this.allowedCompanies = const {},
  });

  /// Parses an [OdooSession] from the `/web/session/authenticate` response.
  factory OdooSession.fromJson(Map<String, dynamic> json) {
    final userContext = Map<String, dynamic>.from(
      json['user_context'] as Map? ?? {},
    );

    // Extract company info from user_companies
    final userCompanies = json['user_companies'] as Map?;
    final currentCompany = json['company_id'] as int? ??
        (userCompanies != null
            ? userCompanies['current_company'] as int? ?? 0
            : 0);
    final allowedCompanies = userCompanies != null
        ? Map<String, dynamic>.from(
            userCompanies['allowed_companies'] as Map? ?? {})
        : <String, dynamic>{};

    return OdooSession(
      uid: json['uid'] as int,
      db: json['db'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? json['login'] as String? ?? '',
      companyId: currentCompany,
      partnerId: json['partner_id'] as int? ?? 0,
      userContext: userContext,
      isAdmin: json['is_admin'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      isInternalUser: json['is_internal_user'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? false,
      serverVersion: json['server_version'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      partnerDisplayName: json['partner_display_name'] as String?,
      allowedCompanies: allowedCompanies,
    );
  }

  /// The user's timezone from [userContext], or `null` if not set.
  String? get timezone => userContext['tz'] as String?;

  /// The user's language from [userContext], or `null` if not set.
  String? get language => userContext['lang'] as String?;

  /// The user type derived from session flags.
  OdooUserType get userType {
    if (isInternalUser) return OdooUserType.internal;
    if (isPublic) return OdooUserType.public;
    return OdooUserType.portal;
  }

  /// Whether this user is a portal user (not internal, not public).
  bool get isPortalUser => !isInternalUser && !isPublic;

  /// Creates a copy with updated fields.
  OdooSession copyWith({
    Map<String, dynamic>? userContext,
    String? sessionId,
  }) {
    return OdooSession(
      uid: uid,
      db: db,
      name: name,
      username: username,
      companyId: companyId,
      partnerId: partnerId,
      userContext: userContext ?? this.userContext,
      isAdmin: isAdmin,
      isSystem: isSystem,
      isInternalUser: isInternalUser,
      isPublic: isPublic,
      serverVersion: serverVersion,
      sessionId: sessionId ?? this.sessionId,
      partnerDisplayName: partnerDisplayName,
      allowedCompanies: allowedCompanies,
    );
  }

  @override
  String toString() =>
      'OdooSession(uid: $uid, db: $db, username: $username, type: ${userType.name})';
}
