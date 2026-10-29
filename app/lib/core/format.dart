String maskEmail(String email) {
  final at = email.indexOf('@');
  final name = at < 0 ? email : email.substring(0, at);
  final domain = at < 0 ? '' : email.substring(at);
  final shown = name.substring(0, name.length < 4 ? (name.isEmpty ? 0 : 1) : 2);
  return '$shown•••••$domain';
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 || value >= 100 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatRate(int bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 B/s';
  final size = formatBytes(bytesPerSecond);
  return '$size/s';
}

String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
