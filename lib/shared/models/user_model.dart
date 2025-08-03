import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Enum representing the different user roles in the application.
/// 
/// User roles determine the level of access and permissions a user
/// has within the system. This is used for implementing role-based
/// access control (RBAC) throughout the application.
/// 
/// Example usage:
/// ```dart
/// if (user.role == UserRole.admin) {
///   // Show admin-only features
/// } else if (user.role == UserRole.staff) {
///   // Show staff-only features
/// }
/// ```
enum UserRole {
  /// Administrator role with full system access.
  /// 
  /// Users with this role have complete access to all features
  /// including user management, system settings, and all enquiry
  /// operations regardless of assignment.
  admin,
  
  /// Staff role with limited access.
  /// 
  /// Users with this role have access to basic enquiry management
  /// features but are restricted to only viewing and managing
  /// enquiries assigned to them.
  staff,
}

/// Immutable data model representing a user in the application.
/// 
/// This model encapsulates all the essential information about a user
/// including their personal details, contact information, and role
/// within the system. The model is generated using Freezed for
/// immutability, equality comparison, and JSON serialization.
/// 
/// The model is used throughout the application for:
/// - User authentication and authorization
/// - Role-based access control
/// - User profile management
/// - Enquiry assignment and ownership
/// 
/// Example usage:
/// ```dart
/// final user = UserModel(
///   uid: 'user123',
///   name: 'John Doe',
///   email: 'john@example.com',
///   phone: '+1234567890',
///   role: UserRole.admin,
/// );
/// 
/// // Create from JSON (e.g., from Firestore)
/// final userFromJson = UserModel.fromJson(jsonMap);
/// 
/// // Convert to JSON (e.g., for Firestore)
/// final jsonMap = user.toJson();
/// ```
@freezed
class UserModel with _$UserModel {
  /// Creates a [UserModel] instance with the specified user information.
  /// 
  /// All parameters are required except [role], which defaults to [UserRole.staff].
  /// This ensures that new users are created with the most restrictive permissions
  /// by default, following the principle of least privilege.
  /// 
  /// Parameters:
  /// - [uid]: Unique identifier for the user (typically from Firebase Auth)
  /// - [name]: User's full name as displayed in the application
  /// - [email]: User's email address for communication and login
  /// - [phone]: User's phone number for contact purposes
  /// - [role]: User's role in the system (defaults to [UserRole.staff])
  /// 
  /// Returns a new [UserModel] instance with the provided data.
  /// 
  /// Example:
  /// ```dart
  /// final adminUser = UserModel(
  ///   uid: 'admin123',
  ///   name: 'Admin User',
  ///   email: 'admin@company.com',
  ///   phone: '+1234567890',
  ///   role: UserRole.admin,
  /// );
  /// 
  /// final staffUser = UserModel(
  ///   uid: 'staff456',
  ///   name: 'Staff User',
  ///   email: 'staff@company.com',
  ///   phone: '+0987654321',
  ///   // role defaults to UserRole.staff
  /// );
  /// ```
  const factory UserModel({
    /// Unique identifier for the user.
    /// 
    /// This is typically the UID from Firebase Authentication and serves
    /// as the primary key for the user in the database. It should be
    /// unique across all users in the system.
    required String uid,
    
    /// User's full name as displayed in the application.
    /// 
    /// This name is used throughout the UI for displaying user information,
    /// such as in enquiry assignments, user lists, and profile displays.
    required String name,
    
    /// User's email address.
    /// 
    /// This email is used for:
    /// - User authentication (login)
    /// - System communications and notifications
    /// - User identification in the system
    required String email,
    
    /// User's phone number.
    /// 
    /// This phone number is used for:
    /// - Contact information in enquiries
    /// - Emergency communications
    /// - User verification processes
    required String phone,
    
    /// User's role in the application.
    /// 
    /// This role determines the user's permissions and access levels
    /// throughout the system. Defaults to [UserRole.staff] for security.
    @Default(UserRole.staff) UserRole role,
  }) = _UserModel;

  /// Creates a [UserModel] instance from a JSON map.
  /// 
  /// This factory method is used to deserialize user data from JSON
  /// sources such as Firestore documents, API responses, or local storage.
  /// 
  /// Parameters:
  /// - [json]: A [Map<String, dynamic>] containing the user data in JSON format
  /// 
  /// Returns a [UserModel] instance with the data from the JSON map.
  /// 
  /// Throws:
  /// - [FormatException] if the JSON structure is invalid or required fields are missing
  /// 
  /// Example:
  /// ```dart
  /// final jsonMap = {
  ///   'uid': 'user123',
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'phone': '+1234567890',
  ///   'role': 'admin',
  /// };
  /// 
  /// final user = UserModel.fromJson(jsonMap);
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
} 
