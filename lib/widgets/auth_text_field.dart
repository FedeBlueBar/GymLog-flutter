import 'package:flutter/material.dart';

/// Widget personalizzato per i campi di testo utilizzati nelle schermate di autenticazione.
/// Standardizza l'aspetto (colori, bordi, label) per mantenere coerenza grafica
/// nei form di login e registrazione.
class AuthTextField extends StatelessWidget {
  /// Testo mostrato come etichetta (label) all'interno del campo.
  final String label;

  /// Controller per gestire e recuperare il testo inserito dall'utente.
  final TextEditingController controller;

  /// Se true, nasconde il testo inserito (es. per le password).
  final bool obscureText;

  /// Specifica il tipo di tastiera da mostrare (es. email, testo, numeri).
  final TextInputType keyboardType;

  /// Widget opzionale (es. un'icona) da mostrare alla fine del campo di testo.
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Colors.black,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelStyle: const TextStyle(color: Colors.black),
        suffixIcon: suffixIcon,
        // Bordo mostrato quando il campo è selezionato (focus)
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2.0),
        ),
        // Bordo mostrato quando il campo non è selezionato
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
