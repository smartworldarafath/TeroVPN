import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../components/country_flag.dart';
import '../countries/country_manager.dart';
import '../components/top_dock_toast.dart';
import 'profile_model.dart';

class CreateProfileWizard extends StatefulWidget {
  final ValueChanged<VpnProfile> onProfileCreated;

  const CreateProfileWizard({super.key, required this.onProfileCreated});

  @override
  State<CreateProfileWizard> createState() => _CreateProfileWizardState();
}

class _CreateProfileWizardState extends State<CreateProfileWizard> {
  int _currentStep = 0; // 0: Appearance, 1: Server, 2: Settings

  // Step 1: Appearance
  final TextEditingController _nameController = TextEditingController(text: 'My Profile');
  String _selectedColorHex = '#6B42FF';
  int _selectedIconCodePoint = Icons.bolt_rounded.codePoint;
  IconData _selectedIcon = Icons.bolt_rounded;

  static const List<String> _colors = [
    '#6B42FF', // Purple
    '#3B82F6', // Blue
    '#10B981', // Green
    '#EF4444', // Red
    '#F97316', // Orange
    '#EAB308', // Yellow
  ];

  static final List<IconData> _icons = [
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
  ];

  // Step 2: Server & Connection Type
  String _connectionType = 'Standard'; // 'Standard', 'Secure Core', 'P2P'
  String _selectedCountryCode = 'fastest';
  String _selectedCountryName = 'Fastest country';
  final TextEditingController _countrySearchController = TextEditingController();
  String _countrySearchQuery = '';

  // Step 3: Profile Settings
  String _netShield = 'Block malware, ads, & trackers';
  String _protocol = 'Smart (Automatic)';
  String _natType = 'Strict';
  bool _lanConnections = true;
  bool _connectOnLaunch = false;
  bool _customDns = false;
  final TextEditingController _primaryDnsController = TextEditingController(text: '1.1.1.1');
  final TextEditingController _secondaryDnsController = TextEditingController(text: '1.0.0.1');

  @override
  void dispose() {
    _nameController.dispose();
    _countrySearchController.dispose();
    _primaryDnsController.dispose();
    _secondaryDnsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_nameController.text.trim().isEmpty) {
      TopDockToast.show(
        context,
        title: 'Profile Name Required',
        message: 'Please enter a name for your profile',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveProfile() async {
    final profile = VpnProfile(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      subtitle: _selectedCountryCode == 'fastest'
          ? 'Fastest country'
          : (_connectionType == 'Secure Core' ? 'via Secure Core' : _selectedCountryName),
      colorHex: _selectedColorHex,
      iconCodePoint: _selectedIconCodePoint,
      connectionType: _connectionType,
      countryCode: _selectedCountryCode,
      countryName: _selectedCountryName,
      netShield: _netShield,
      protocol: _protocol,
      natType: _natType,
      lanConnections: _lanConnections,
      connectOnLaunch: _connectOnLaunch,
      customDns: _customDns,
      customDnsPrimary: _customDns ? _primaryDnsController.text : null,
      customDnsSecondary: _customDns ? _secondaryDnsController.text : null,
      isDefault: false,
    );

    await AppPreferences.addCustomProfile(jsonEncode(profile.toJson()));
    widget.onProfileCreated(profile);
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'Profile Saved! 🎉',
        message: '${profile.name} is ready to connect',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF00E676),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeManager.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeManager.instance.backgroundColor,
        elevation: 0,
        title: Text(
          'Create profile (${_currentStep + 1}/3)',
          style: ProtonTypography.titleLarge.copyWith(
            fontSize: 18,
            color: ThemeManager.instance.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
          onPressed: _prevStep,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(3, (i) {
                  final active = i <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF6B42FF) : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStepBody(isDark),
                ),
              ),
            ),

            // Bottom Next / Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B42FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == 2 ? 'Save profile' : 'Next',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Appearance(isDark);
      case 1:
        return _buildStep2ServerSelection(isDark);
      case 2:
        return _buildStep3Settings(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Appearance (Name, 6 Colors, 12 Icons)
  Widget _buildStep1Appearance(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(
          'Name and appearance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF161224),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a profile name, icon and color badge',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
          ),
        ),
        const SizedBox(height: 24),

        // Live Profile Preview
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _parseColor(_selectedColorHex).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _parseColor(_selectedColorHex), width: 2),
            ),
            child: Icon(
              _selectedIcon,
              color: _parseColor(_selectedColorHex),
              size: 34,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Name TextField
        TextField(
          controller: _nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: 'Profile name',
            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            filled: true,
            fillColor: isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6B42FF), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Color Picker (6 Colors)
        Text(
          'COLOR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF9D94B8) : const Color(0xFF635B7E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _colors.map((hex) {
            final isSelected = _selectedColorHex == hex;
            final color = _parseColor(hex);
            return GestureDetector(
              onTap: () => setState(() => _selectedColorHex = hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        // Icon Picker (12 Icons Grid)
        Text(
          'ICON',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF9D94B8) : const Color(0xFF635B7E),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _icons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, idx) {
            final icon = _icons[idx];
            final isSelected = _selectedIconCodePoint == icon.codePoint;
            final activeColor = _parseColor(_selectedColorHex);

            return GestureDetector(
              onTap: () => setState(() { _selectedIconCodePoint = icon.codePoint; _selectedIcon = icon; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? activeColor : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : (isDark ? Colors.white60 : Colors.black54),
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 2: Server Selection (Connection Type & Country)
  Widget _buildStep2ServerSelection(bool isDark) {
    final allCountries = CountryManager.instance.countries;
    final filtered = allCountries.where((c) {
      if (_countrySearchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_countrySearchQuery.toLowerCase()) ||
          c.code.toLowerCase().contains(_countrySearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server selection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF161224),
                ),
              ),
              const SizedBox(height: 12),

              // Connection Type Picker Button
              GestureDetector(
                onTap: () => _showConnectionTypeModal(isDark),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6B42FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getConnectionTypeIcon(_connectionType),
                            color: const Color(0xFF6B42FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connection type',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              _connectionType,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF161224),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Country Search Bar
              TextField(
                controller: _countrySearchController,
                onChanged: (val) => setState(() => _countrySearchQuery = val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Countries List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            children: [
              // Fastest Country Option
              _buildCountryOption(
                code: 'fastest',
                name: 'Fastest country',
                isFastest: true,
                isSelected: _selectedCountryCode == 'fastest',
                isDark: isDark,
              ),

              const Divider(height: 16),

              ...filtered.map((c) => _buildCountryOption(
                    code: c.code,
                    name: c.name,
                    isFastest: false,
                    isSelected: _selectedCountryCode == c.code,
                    isDark: isDark,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountryOption({
    required String code,
    required String name,
    required bool isFastest,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCountryCode = code;
          _selectedCountryName = name;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B42FF).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF19142B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B42FF)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            if (isFastest)
              Container(
                width: 32,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF6B42FF), size: 16),
              )
            else
              CountryFlag(countryCode: code, width: 32, height: 22, borderRadius: 4),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF161224),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF6B42FF), size: 20),
          ],
        ),
      ),
    );
  }

  // STEP 3: Configure Profile Settings (NetShield, Protocol, NAT, LAN, Auto-connect, DNS)
  Widget _buildStep3Settings(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(
          'Features & Security',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF161224),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fine-tune security and routing protocols for this profile',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
          ),
        ),
        const SizedBox(height: 20),

        // NetShield
        _buildSettingTile(
          icon: Icons.shield_rounded,
          title: 'NetShield',
          subtitle: _netShield,
          isDark: isDark,
          onTap: () => _showNetShieldModal(isDark),
        ),

        // Protocol
        _buildSettingTile(
          icon: Icons.vpn_lock_rounded,
          title: 'Protocol',
          subtitle: _protocol,
          isDark: isDark,
          onTap: () => _showProtocolModal(isDark),
        ),

        // NAT Type
        _buildSettingTile(
          icon: Icons.alt_route_rounded,
          title: 'NAT type',
          subtitle: _natType,
          isDark: isDark,
          onTap: () => _showNatTypeModal(isDark),
        ),

        // LAN Connections
        _buildSettingSwitchTile(
          icon: Icons.lan_rounded,
          title: 'LAN connections',
          subtitle: 'Allow direct access to local network devices and printers',
          value: _lanConnections,
          isDark: isDark,
          onChanged: (v) => setState(() => _lanConnections = v),
        ),

        // Connect and Go
        _buildSettingSwitchTile(
          icon: Icons.rocket_launch_rounded,
          title: 'Connect and Go',
          subtitle: 'Automatically connect with this profile when app launches',
          value: _connectOnLaunch,
          isDark: isDark,
          onChanged: (v) => setState(() => _connectOnLaunch = v),
        ),

        // Custom DNS
        _buildSettingSwitchTile(
          icon: Icons.dns_rounded,
          title: 'Custom DNS',
          subtitle: 'Override default DNS resolvers with private servers',
          value: _customDns,
          isDark: isDark,
          onChanged: (v) => setState(() => _customDns = v),
        ),

        if (_customDns) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _primaryDnsController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Primary DNS',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _secondaryDnsController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Secondary DNS',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF19142B) : const Color(0xFFF3F2F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF19142B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6B42FF), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF161224),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19142B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6B42FF), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF161224),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF6B42FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Modals for Step 2 & 3
  void _showConnectionTypeModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF19142B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connection type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF161224),
                ),
              ),
              const SizedBox(height: 16),
              _buildModalRadioItem(
                title: 'Standard',
                description: 'Connect to standard high-speed server',
                icon: Icons.shield_rounded,
                selected: _connectionType == 'Standard',
                onTap: () {
                  setState(() => _connectionType = 'Standard');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
              _buildModalRadioItem(
                title: 'Secure Core',
                description: 'Defend against network-based attacks with multi-hop',
                icon: Icons.lock_outline_rounded,
                selected: _connectionType == 'Secure Core',
                onTap: () {
                  setState(() => _connectionType = 'Secure Core');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
              _buildModalRadioItem(
                title: 'P2P',
                description: 'Optimized for fast and secure file sharing',
                icon: Icons.swap_calls_rounded,
                selected: _connectionType == 'P2P',
                onTap: () {
                  setState(() => _connectionType = 'P2P');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNetShieldModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF19142B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NetShield',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF161224)),
              ),
              const SizedBox(height: 16),
              _buildModalRadioItem(
                title: 'Block malware, ads, & trackers',
                description: 'Full DNS filter blocking advertisements, malicious domains, and data miners',
                icon: Icons.security_rounded,
                selected: _netShield == 'Block malware, ads, & trackers',
                onTap: () {
                  setState(() => _netShield = 'Block malware, ads, & trackers');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
              _buildModalRadioItem(
                title: 'Block malware only',
                description: 'Protects from phishing and ransomware without interfering with ad delivery',
                icon: Icons.verified_user_rounded,
                selected: _netShield == 'Block malware only',
                onTap: () {
                  setState(() => _netShield = 'Block malware only');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
              _buildModalRadioItem(
                title: 'Off',
                description: 'Allow all network requests directly without DNS filtering',
                icon: Icons.block_rounded,
                selected: _netShield == 'Off',
                onTap: () {
                  setState(() => _netShield = 'Off');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProtocolModal(bool isDark) {
    const protocols = [
      'Smart (Automatic)',
      'WireGuard',
      'Stealth',
      'OpenVPN - TCP',
      'OpenVPN - UDP',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF19142B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protocol',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF161224)),
              ),
              const SizedBox(height: 16),
              ...protocols.map((p) => _buildModalRadioItem(
                    title: p,
                    description: p == 'Smart (Automatic)'
                        ? 'Automatically selects the fastest and most stable protocol'
                        : (p == 'Stealth' ? 'Bypasses censorship and DPI firewalls' : 'High performance UDP/TCP tunnel'),
                    icon: Icons.vpn_key_rounded,
                    selected: _protocol == p,
                    onTap: () {
                      setState(() => _protocol = p);
                      Navigator.pop(ctx);
                    },
                    isDark: isDark,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showNatTypeModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF19142B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NAT type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF161224)),
              ),
              const SizedBox(height: 16),
              _buildModalRadioItem(
                title: 'Strict',
                description: 'Full endpoint security for web and streaming',
                icon: Icons.shield_rounded,
                selected: _natType == 'Strict',
                onTap: () {
                  setState(() => _natType = 'Strict');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
              _buildModalRadioItem(
                title: 'Moderate',
                description: 'Allows multiplayer peer connections for gaming without packet drops',
                icon: Icons.sports_esports_rounded,
                selected: _natType == 'Moderate',
                onTap: () {
                  setState(() => _natType = 'Moderate');
                  Navigator.pop(ctx);
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRadioItem({
    required String title,
    required String description,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6B42FF).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF221D38) : const Color(0xFFF3F2F8)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF6B42FF) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF6B42FF) : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF161224),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF6B42FF), size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getConnectionTypeIcon(String type) {
    switch (type) {
      case 'Secure Core':
        return Icons.lock_outline_rounded;
      case 'P2P':
        return Icons.swap_calls_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF6B42FF);
  }
}
