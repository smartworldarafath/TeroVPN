import 'package:flutter/material.dart';

class VpnProfile {
  final String id;
  final String name;
  final String subtitle;
  final String colorHex;
  final int iconCodePoint;
  final String iconFontFamily;
  final String connectionType; // 'Standard', 'Secure Core', 'P2P'
  final String countryCode; // 'US', 'DE', 'fastest', etc.
  final String countryName;
  final String netShield; // 'Malware, ads & trackers', 'Malware only', 'Off'
  final String protocol; // 'Smart (Automatic)', 'WireGuard', 'Stealth', 'OpenVPN'
  final String natType; // 'Strict', 'Moderate'
  final bool lanConnections;
  final bool connectOnLaunch;
  final bool customDns;
  final String? customDnsPrimary;
  final String? customDnsSecondary;
  final bool isDefault;

  const VpnProfile({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.colorHex,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    required this.connectionType,
    required this.countryCode,
    required this.countryName,
    this.netShield = 'Malware, ads & trackers',
    this.protocol = 'Smart (Automatic)',
    this.natType = 'Strict',
    this.lanConnections = true,
    this.connectOnLaunch = false,
    this.customDns = false,
    this.customDnsPrimary,
    this.customDnsSecondary,
    this.isDefault = false,
  });

  Color get color {
    final clean = colorHex.replaceAll('#', '');
    final intVal = int.tryParse('FF$clean', radix: 16) ?? 0xFF6B42FF;
    return Color(intVal);
  }

  static const List<IconData> availableIcons = [
    Icons.bolt_rounded,
    Icons.smart_display_rounded,
    Icons.shield_rounded,
    Icons.visibility_off_rounded,
    Icons.security_rounded,
    Icons.terminal_rounded,
    Icons.sports_esports_rounded,
    Icons.folder_rounded,
    Icons.work_rounded,
    Icons.shopping_cart_rounded,
    Icons.lock_rounded,
    Icons.language_rounded,
    Icons.play_arrow_rounded,
  ];

  IconData get iconData {
    for (final ic in availableIcons) {
      if (ic.codePoint == iconCodePoint) return ic;
    }
    return Icons.bolt_rounded;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'colorHex': colorHex,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'connectionType': connectionType,
        'countryCode': countryCode,
        'countryName': countryName,
        'netShield': netShield,
        'protocol': protocol,
        'natType': natType,
        'lanConnections': lanConnections,
        'connectOnLaunch': connectOnLaunch,
        'customDns': customDns,
        'customDnsPrimary': customDnsPrimary,
        'customDnsSecondary': customDnsSecondary,
        'isDefault': isDefault,
      };

  factory VpnProfile.fromJson(Map<String, dynamic> json) => VpnProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#6B42FF',
        iconCodePoint: json['iconCodePoint'] as int? ?? Icons.bolt_rounded.codePoint,
        iconFontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
        connectionType: json['connectionType'] as String? ?? 'Standard',
        countryCode: json['countryCode'] as String? ?? 'fastest',
        countryName: json['countryName'] as String? ?? 'Fastest country',
        netShield: json['netShield'] as String? ?? 'Malware, ads & trackers',
        protocol: json['protocol'] as String? ?? 'Smart (Automatic)',
        natType: json['natType'] as String? ?? 'Strict',
        lanConnections: json['lanConnections'] as bool? ?? true,
        connectOnLaunch: json['connectOnLaunch'] as bool? ?? false,
        customDns: json['customDns'] as bool? ?? false,
        customDnsPrimary: json['customDnsPrimary'] as String?,
        customDnsSecondary: json['customDnsSecondary'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  static List<VpnProfile> get protonDefaults => [
        VpnProfile(
          id: 'streaming_us',
          name: 'Streaming US',
          subtitle: 'United States',
          colorHex: '#6B42FF',
          iconCodePoint: Icons.play_arrow_rounded.codePoint,
          connectionType: 'Standard',
          countryCode: 'US',
          countryName: 'United States',
          netShield: 'Malware, ads & trackers',
          protocol: 'Smart (Automatic)',
          isDefault: true,
        ),
        VpnProfile(
          id: 'gaming',
          name: 'Gaming',
          subtitle: 'Fastest country',
          colorHex: '#3B82F6',
          iconCodePoint: Icons.sports_esports_rounded.codePoint,
          connectionType: 'Standard',
          countryCode: 'fastest',
          countryName: 'Fastest country',
          netShield: 'Off',
          protocol: 'WireGuard',
          natType: 'Moderate',
          isDefault: true,
        ),
        VpnProfile(
          id: 'anti_censorship',
          name: 'Anti-censorship',
          subtitle: 'Fastest country (excluding my country)',
          colorHex: '#10B981',
          iconCodePoint: Icons.visibility_off_rounded.codePoint,
          connectionType: 'Standard',
          countryCode: 'fastest',
          countryName: 'Fastest country (excluding my country)',
          netShield: 'Malware, ads & trackers',
          protocol: 'Stealth',
          isDefault: true,
        ),
        VpnProfile(
          id: 'max_security',
          name: 'Max security',
          subtitle: 'via Secure Core',
          colorHex: '#EF4444',
          iconCodePoint: Icons.shield_rounded.codePoint,
          connectionType: 'Secure Core',
          countryCode: 'IS',
          countryName: 'Iceland via Secure Core',
          netShield: 'Malware, ads & trackers',
          protocol: 'WireGuard',
          isDefault: true,
        ),
        VpnProfile(
          id: 'work_school',
          name: 'Work/School',
          subtitle: 'Fastest country',
          colorHex: '#F97316',
          iconCodePoint: Icons.work_rounded.codePoint,
          connectionType: 'Standard',
          countryCode: 'fastest',
          countryName: 'Fastest country',
          netShield: 'Malware only',
          protocol: 'Smart (Automatic)',
          isDefault: true,
        ),
      ];
}
