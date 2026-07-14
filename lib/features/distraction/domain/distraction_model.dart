class DistractionApp {
  final int id;
  final String packageId;
  final String appName;
  final bool isActive;

  DistractionApp({
    required this.id,
    required this.packageId,
    required this.appName,
    required this.isActive,
  });

  factory DistractionApp.fromJson(Map<String, dynamic> json) {
    return DistractionApp(
      id: json['id'],
      packageId: json['package_id'] ?? '',
      appName: json['name'] ?? json['package_id'] ?? 'Unknown App',
      isActive: json['is_active'] ?? true,
    );
  }
}
