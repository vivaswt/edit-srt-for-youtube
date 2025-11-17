String sanitizeFileName(String fileName) {
  // Define a set of characters that are not allowed in file names on most operating systems.
  final invalidChars = RegExp(r'[<>:"/\\|?*]');

  // Replace invalid characters with an underscore.
  // The `replaceAll` method is a good choice for this task.
  String sanitizedName = fileName.replaceAll(invalidChars, '_');

  // Also handle leading/trailing spaces and dots, which can be problematic.
  sanitizedName = sanitizedName.trim();
  if (sanitizedName.isNotEmpty && sanitizedName.startsWith('.')) {
    sanitizedName = '_${sanitizedName.substring(1)}';
  }

  // Ensure the sanitized name is not empty.
  if (sanitizedName.isEmpty) {
    return 'untitled';
  }

  return sanitizedName;
}
