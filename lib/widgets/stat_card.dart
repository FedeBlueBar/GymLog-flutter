import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String titolo;
  final String valore;
  final IconData icona;
  final VoidCallback onClick;
  final String? valoreObiettivo;
  final String? sottotitolo;
  final double? progress;

  const StatCard({
    super.key,
    required this.titolo,
    required this.valore,
    required this.icona,
    required this.onClick,
    this.valoreObiettivo,
    this.sottotitolo,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFF6F5F8),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onClick,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icona,
                size: 20,
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              Text(
                titolo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    valore,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (valoreObiettivo != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      valoreObiettivo!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (sottotitolo != null) ...[
                const SizedBox(height: 4),
                Text(
                  sottotitolo!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
