import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String testo;

  const SectionHeader({super.key, required this.testo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        testo.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.0,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icona;
  final Color iconColor;
  final Color iconBgColor;
  final String etichetta;
  final String? valore;
  final VoidCallback? onClick;

  const ProfileInfoRow({
    super.key,
    required this.icona,
    this.iconColor = const Color(0xFF6C5CE7),
    this.iconBgColor = const Color(0xFFEBE5FF),
    required this.etichetta,
    required this.valore,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final hasClick = onClick != null;
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              icona,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etichetta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valore == null || valore!.trim().isEmpty ? "—" : valore!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasClick)
            const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black,
            ),
        ],
      ),
    );

    if (hasClick) {
      return InkWell(
        onTap: onClick,
        child: rowContent,
      );
    } else {
      return rowContent;
    }
  }
}

class ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
      ),
      color: const Color(0xFFF6F5F8),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        height: 1,
      ),
    );
  }
}
