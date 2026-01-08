import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

// SECURITY: Comprehensive input validation, rate limiting, and audit logging
// PoW: 14/04/1980
class SecurityValidator {
  // ===== RATE LIMITING =====
  static final Map<String, List<DateTime>> _requestLog = {};
  static const int maxRequestsPerMinute = 60;
  static const int maxRequestsPerSecond = 10;
  
  // ===== AUDIT LOGGING =====
  static final List<AuditLog> _auditLogs = [];
  static const int maxAuditLogs = 1000;

  // Input validation
  static bool isValidBarcode(String barcode) {
    if (barcode.isEmpty || barcode.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(barcode);
  }

  static bool isValidName(String name) {
    if (name.isEmpty || name.length > 255) return false;
    return RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name);
  }

  static bool isValidPosition(String position) {
    if (position.isEmpty || position.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9\s\-]+$').hasMatch(position);
  }

  static bool isValidCompanyCode(String code) {
    if (code.isEmpty || code.length > 30) return false;
    return RegExp(r'^[A-Z0-9\-_]+$').hasMatch(code);
  }

  static bool isValidServerUrl(String url) {
    if (url.isEmpty || url.length > 500) return false;
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // File validation
  static bool isValidImageFile(String fileName, int fileSize) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    const allowedFormats = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    
    if (fileSize > maxSize) return false;
    
    final ext = fileName.split('.').last.toLowerCase();
    return allowedFormats.contains(ext);
  }

  static bool isValidExcelFile(String fileName, int fileSize) {
    const maxSize = 10 * 1024 * 1024; // 10MB
    const allowedFormats = ['xlsx', 'xls'];
    
    if (fileSize > maxSize) return false;
    
    final ext = fileName.split('.').last.toLowerCase();
    return allowedFormats.contains(ext);
  }

  // CSV validation
  static bool isValidCsvFile(String fileName, int fileSize, int rowCount) {
    const maxSize = 10 * 1024 * 1024; // 10MB
    const maxRows = 10000;
    
    if (fileSize > maxSize || rowCount > maxRows) return false;
    
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'csv';
  }

  // Path traversal prevention
  static bool isValidFilePath(String path) {
    // Prevent directory traversal
    if (path.contains('..') || path.contains('~')) return false;
    // Prevent absolute paths
    if (path.startsWith('/') || (path.length > 1 && path[1] == ':')) return false;
    return true;
  }

  // Safe error messages (no sensitive data)
  static String getSafeErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('database')) {
      return 'Database operation failed. Please try again.';
    } else if (message.contains('file')) {
      return 'File operation failed. Please check the file.';
    } else if (message.contains('network') || message.contains('socket')) {
      return 'Network error. Please check your connection.';
    } else if (message.contains('permission')) {
      return 'Permission denied. Please check access rights.';
    } else if (message.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // Wrapper methods for backward compatibility - return error message or null
  static String? validateBarcode(String barcode) {
    if (barcode.isEmpty) return 'Barcode cannot be empty';
    if (barcode.length > 100) return 'Barcode is too long (max 100 characters)';
    if (!isValidBarcode(barcode)) return 'Barcode contains invalid characters. Only alphanumeric, hyphens, and underscores allowed';
    return null;
  }

  static String? validateName(String name) {
    if (name.isEmpty) return 'Name cannot be empty';
    if (name.length > 255) return 'Name is too long (max 255 characters)';
    if (!isValidName(name)) return 'Name contains invalid characters';
    return null;
  }

  static String? validatePosition(String position) {
    if (position.isEmpty) return null;
    if (position.length > 100) return 'Position is too long (max 100 characters)';
    if (!isValidPosition(position)) return 'Position contains invalid characters';
    return null;
  }

  static String? validateImageFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 'Image file does not exist';
      final size = file.lengthSync();
      if (size > 5 * 1024 * 1024) return 'Image is too large (max 5MB)';
      final ext = filePath.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
      if (!allowedExtensions.contains(ext)) return 'Invalid image format. Allowed: JPG, PNG, GIF, BMP';
      return null;
    } catch (e) {
      return 'Invalid image file';
    }
  }

  // Password/hash utilities
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String generateSecureToken(String input) {
    return sha256.convert(utf8.encode(input + DateTime.now().toString())).toString();
  }

  // Rate limiting check
  static bool checkRateLimit(String userId) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    _requestLog[userId] ??= [];
    
    // Remove old requests
    _requestLog[userId]!.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    if (_requestLog[userId]!.length >= maxRequestsPerMinute) {
      return false; // Rate limit exceeded
    }
    
    _requestLog[userId]!.add(now);
    return true;
  }

  // ===== DATA SANITIZATION & ENCODING =====
  static String sanitize(String input) {
    return input
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll(';', '')
        .replaceAll('\\', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
  }

  // Safe JSON encoding (prevents injection)
  static String safeJsonEncode(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      print('❌ JSON encoding error: $e');
      return '{}';
    }
  }

  // ===== ADVANCED RATE LIMITING =====
  static bool checkSecondRateLimit(String userId) {
    final now = DateTime.now();
    final oneSecondAgo = now.subtract(const Duration(seconds: 1));
    
    _requestLog[userId] ??= [];
    _requestLog[userId]!.removeWhere((time) => time.isBefore(oneSecondAgo));
    
    if (_requestLog[userId]!.length >= maxRequestsPerSecond) {
      logAudit('RATE_LIMIT_EXCEEDED_SEC', userId, 'Exceeded $maxRequestsPerSecond req/sec', false);
      return false;
    }
    
    _requestLog[userId]!.add(now);
    return true;
  }

  // ===== AUDIT LOGGING =====
  static void logAudit(String action, String userId, String details, bool success) {
    final log = AuditLog(
      timestamp: DateTime.now(),
      action: action,
      userId: userId,
      details: sanitize(details),
      success: success,
    );
    
    _auditLogs.add(log);
    
    // Keep only last 1000 logs
    if (_auditLogs.length > maxAuditLogs) {
      _auditLogs.removeAt(0);
    }
    
    // Print to console for debugging
    final status = success ? '✅' : '❌';
    print('$status AUDIT: [$action] User: $userId | ${log.details}');
  }

  static List<AuditLog> getAuditLogs() => List.unmodifiable(_auditLogs);

  static void clearAuditLogs() => _auditLogs.clear();

  // ===== INPUT VALIDATION ENHANCEMENTS =====
  static bool isValidEmail(String email) {
    if (email.isEmpty || email.length > 255) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty || phone.length > 20) return false;
    return RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phone);
  }

  static bool isValidTimestamp(DateTime timestamp) {
    // Prevent timestamps from the future (more than 1 minute ahead)
    final now = DateTime.now();
    return timestamp.isBefore(now.add(const Duration(minutes: 1)));
  }

  // ===== SQL INJECTION PREVENTION =====
  static String sanitizeSqlInput(String input) {
    return input
        .replaceAll("'", "''")  // Escape single quotes
        .replaceAll('"', '""')  // Escape double quotes
        .replaceAll(';', '')    // Remove semicolons
        .replaceAll('--', '')   // Remove SQL comments
        .replaceAll('/*', '')   // Remove comment start
        .replaceAll('*/', '')   // Remove comment end
        .trim();
  }

  // ===== XSS PREVENTION =====
  static String sanitizeHtml(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // ===== DATA ENCRYPTION (HMAC-SHA256) =====
  static String encryptDataWithHmac(String data, String secret) {
    try {
      final bytes = utf8.encode(data);
      final secretBytes = utf8.encode(secret);
      // Note: For proper AES encryption, use 'encrypt' package
      // This is HMAC for integrity verification
      return Hmac(sha256, secretBytes).convert(bytes).toString();
    } catch (e) {
      print('❌ Encryption error: $e');
      return '';
    }
  }

  static bool verifyDataWithHmac(String data, String signature, String secret) {
    try {
      final computed = encryptDataWithHmac(data, secret);
      return computed == signature;
    } catch (e) {
      print('❌ Verification error: $e');
      return false;
    }
  }

  // ===== SSL CERTIFICATE PINNING HELPER =====
  static Map<String, String> getSecureHeaders(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return {
      'Content-Type': 'application/json',
      'X-Client-Version': '1.0.0',
      'X-Timestamp': timestamp,
      'X-Request-Id': _generateRequestId(),
      'X-User-Id': _hashSensitiveData(userId),
      'User-Agent': 'VoxelAttendanceManager/1.0',
    };
  }

  static String _generateRequestId() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  static String _hashSensitiveData(String data) {
    return sha256.convert(utf8.encode(data)).toString().substring(0, 32);
  }

  // SQL injection prevention (parameterized queries already in DB)
  static String escapeSql(String input) {
    return input.replaceAll("'", "''");
  }

  // Data encryption (basic)
  static String encryptData(String data) {
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }

  static String decryptData(String encrypted) {
    try {
      final bytes = base64Decode(encrypted);
      return utf8.decode(bytes);
    } catch (e) {
      return '';
    }
  }
}

class AuditLog {
  final DateTime timestamp;
  final String action;
  final String userId;
  final String details;
  final bool success;

  AuditLog({
    required this.timestamp,
    required this.action,
    required this.userId,
    required this.details,
    required this.success,
  });

  @override
  String toString() => '$timestamp | $action | $userId | $details | ${success ? '✅' : '❌'}';
}

// SSL/TLS certificate pinning
class CertificatePinning {
  static const List<String> pinnedCertificates = [
    // Add your server certificate SHA-256 hashes here
  ];

  static bool validateCertificate(String certificateHash) {
    return pinnedCertificates.contains(certificateHash);
  }
}
