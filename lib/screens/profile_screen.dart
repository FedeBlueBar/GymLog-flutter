// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/profile_notifier.dart';
import 'package:gymlog_flutter/widgets/profile_section.dart';
import 'package:gymlog_flutter/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileNotifier>().loadProfile();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (context, state, child) {
        // Trigger alerts on message state updates
        if (state.successMessage != null || state.errorMessage != null) {
          final message = state.successMessage ?? state.errorMessage;
          if (message != null && message.trim().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSnackBar(message);
              state.clearMessages();
            });
          }
        }

        final user = state.user;
        final fullName = [user?.nome, user?.cognome]
            .where((name) => name != null && name.trim().isNotEmpty)
            .join(" ");

        return Scaffold(
          backgroundColor: const Color(0xFFEBEBEB),
          appBar: AppBar(
            title: const Text(
              "Profilo",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Profile Header Photo Box
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Username label
                        Center(
                          child: Text(
                            user?.username != null && user!.username.isNotEmpty
                                ? user.username
                                : "—",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Full Name label
                        Center(
                          child: Text(
                            fullName.isNotEmpty ? fullName : "",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (user?.isPersonalTrainer == true) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Chip(
                              label: const Text("Personal Trainer"),
                              avatar: const Icon(Icons.workspace_premium, size: 18),
                              backgroundColor: Colors.white,
                              shape: StadiumBorder(
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Section ACCOUNT
                        const SectionHeader(testo: "Account"),
                        ProfileCard(
                          children: [
                            ProfileInfoRow(
                              icona: Icons.person_outline,
                              iconColor: Colors.black,
                              iconBgColor: const Color(0xFFF5F5F5),
                              etichetta: "Username",
                              valore: user?.username,
                              onClick: () => _openTextEditDialog("Username", "username", user?.username),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.email_outlined,
                              iconColor: const Color(0xFF16A085),
                              iconBgColor: const Color(0xFFE8F8F5),
                              etichetta: "Email (non modificabile)",
                              valore: user?.email,
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.lock_outline,
                              iconColor: const Color(0xFFE67E22),
                              iconBgColor: const Color(0xFFFFF4E6),
                              etichetta: "Cambia password",
                              valore: "••••••••",
                              onClick: () => _openChangePasswordDialog(),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.restart_alt_rounded,
                              iconColor: const Color(0xFF2980B9),
                              iconBgColor: const Color(0xFFEBF5FB),
                              etichetta: "Reset password",
                              valore: "Invia email di reset",
                              onClick: () => _openResetPasswordDialog(user?.email),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.delete_forever_outlined,
                              iconColor: const Color(0xFFC0392B),
                              iconBgColor: const Color(0xFFFDEDEC),
                              etichetta: "Elimina account",
                              valore: "Cancellazione definitiva",
                              onClick: () => _openDeleteAccountDialog(),
                            ),
                          ],
                        ),

                        // Section DATI PERSONALI
                        const SectionHeader(testo: "Dati personali"),
                        ProfileCard(
                          children: [
                            ProfileInfoRow(
                              icona: Icons.badge_outlined,
                              iconColor: Colors.black,
                              iconBgColor: const Color(0xFFF5F5F5),
                              etichetta: "Nome",
                              valore: user?.nome,
                              onClick: () => _openTextEditDialog("Nome", "nome", user?.nome),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.badge_outlined,
                              iconColor: const Color(0xFF16A085),
                              iconBgColor: const Color(0xFFE8F8F5),
                              etichetta: "Cognome",
                              valore: user?.cognome,
                              onClick: () => _openTextEditDialog("Cognome", "cognome", user?.cognome),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.cake_outlined,
                              iconColor: const Color(0xFFF1C40F),
                              iconBgColor: const Color(0xFFFEF9E7),
                              etichetta: "Anno di nascita",
                              valore: user?.annoDiNascita != null && user!.annoDiNascita > 0
                                  ? user.annoDiNascita.toString()
                                  : null,
                              onClick: () => _openNumberEditDialog(
                                "Anno di nascita",
                                "annoDiNascita",
                                user?.annoDiNascita != null && user!.annoDiNascita > 0
                                    ? user.annoDiNascita.toString()
                                    : "",
                                false,
                                "",
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.height_outlined,
                              iconColor: const Color(0xFF8E44AD),
                              iconBgColor: const Color(0xFFF4ECF8),
                              etichetta: "Altezza",
                              valore: user?.altezza != null && user!.altezza > 0
                                  ? "${user.altezza} cm"
                                  : null,
                              onClick: () => _openNumberEditDialog(
                                "Altezza",
                                "altezza",
                                user?.altezza != null && user!.altezza > 0
                                    ? user.altezza.toString()
                                    : "",
                                false,
                                "cm",
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.monitor_weight_outlined,
                              iconColor: const Color(0xFFD35400),
                              iconBgColor: const Color(0xFFFCEBE6),
                              etichetta: "Peso",
                              valore: user?.peso != null && user!.peso > 0.0
                                  ? "${user.peso} kg"
                                  : null,
                              onClick: () => _openNumberEditDialog(
                                "Peso",
                                "peso",
                                user?.peso != null && user!.peso > 0.0
                                    ? user.peso.toString()
                                    : "",
                                true,
                                "kg",
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.flag_outlined,
                              iconColor: const Color(0xFF27AE60),
                              iconBgColor: const Color(0xFFEAFAF1),
                              etichetta: "Obiettivo",
                              valore: user?.obiettivo,
                              onClick: () => _openDropdownEditDialog(
                                "Obiettivo",
                                "obiettivo",
                                Constants.availableGoals,
                                user?.obiettivo ?? "",
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileInfoRow(
                              icona: Icons.workspace_premium_outlined,
                              iconColor: const Color(0xFFF39C12),
                              iconBgColor: const Color(0xFFFEF5E7),
                              etichetta: "Personal Trainer",
                              valore: user?.isPersonalTrainer == true ? "Sì" : "No",
                              onClick: () => _openSwitchEditDialog(
                                "Sei un Personal Trainer?",
                                "PersonalTrainer",
                                user?.isPersonalTrainer == true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        // Log out red button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              state.logout();
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              "Logout",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // --- Modal Dialog Actions ---

  void _openTextEditDialog(String title, String fieldKey, String? initialValue) {
    final controller = TextEditingController(text: initialValue ?? "");
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final val = controller.text.trim();
            final canSave = val.isNotEmpty && val != (initialValue ?? "");

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Modifica $title", style: const TextStyle(color: Colors.black)),
              content: TextField(
                controller: controller,
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  labelText: title,
                  labelStyle: const TextStyle(color: Colors.black54),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                cursorColor: Colors.black,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: canSave
                      ? () {
                          context.read<ProfileNotifier>().updateField(fieldKey, val);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Salva",
                    style: TextStyle(
                      color: canSave ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openNumberEditDialog(
    String title,
    String fieldKey,
    String initialValue,
    bool isDouble,
    String suffix,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final val = controller.text.trim();
            final canSave = val.isNotEmpty;

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Modifica $title", style: const TextStyle(color: Colors.black)),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  labelText: title,
                  suffixText: suffix.isNotEmpty ? suffix : null,
                  labelStyle: const TextStyle(color: Colors.black54),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                cursorColor: Colors.black,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: canSave
                      ? () {
                          if (isDouble) {
                            final dbl = double.tryParse(val.replaceAll(',', '.'));
                            if (dbl != null) {
                              context.read<ProfileNotifier>().updateField(fieldKey, dbl);
                            }
                          } else {
                            final intVal = int.tryParse(val);
                            if (intVal != null) {
                              context.read<ProfileNotifier>().updateField(fieldKey, intVal);
                            }
                          }
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Salva",
                    style: TextStyle(
                      color: canSave ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDropdownEditDialog(
    String title,
    String fieldKey,
    List<String> options,
    String initialValue,
  ) {
    String selected = initialValue;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("Modifica $title", style: const TextStyle(color: Colors.black)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    return ListTile(
                      title: Text(opt, style: const TextStyle(color: Colors.black)),
                      leading: Radio<String>(
                        value: opt,
                        groupValue: selected,
                        activeColor: Colors.black,
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selected = val;
                            });
                          }
                        },
                      ),
                      onTap: () {
                        setStateDialog(() {
                          selected = opt;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    context.read<ProfileNotifier>().updateField(fieldKey, selected);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Salva",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSwitchEditDialog(String title, String fieldKey, bool initialValue) {
    bool checked = initialValue;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 18)),
              content: Row(
                children: [
                  Switch(
                    value: checked,
                    activeTrackColor: Colors.black,
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      setStateDialog(() {
                        checked = val;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    checked ? "Sì" : "No",
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    context.read<ProfileNotifier>().updateField(fieldKey, checked);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Salva",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final oldPwd = oldController.text;
            final newPwd = newController.text;
            final confirmPwd = confirmController.text;
            final mismatch = newPwd.isNotEmpty && confirmPwd.isNotEmpty && newPwd != confirmPwd;
            final canSave = oldPwd.isNotEmpty && newPwd.length >= 6 && newPwd == confirmPwd;

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Cambia password", style: TextStyle(color: Colors.black)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldController,
                      obscureText: true,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: const InputDecoration(
                        labelText: "Password attuale",
                        labelStyle: TextStyle(color: Colors.black54),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      cursorColor: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newController,
                      obscureText: true,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: const InputDecoration(
                        labelText: "Nuova password",
                        labelStyle: TextStyle(color: Colors.black54),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      cursorColor: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "Conferma nuova password",
                        labelStyle: const TextStyle(color: Colors.black54),
                        errorText: mismatch ? "Le due password non coincidono" : null,
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      cursorColor: Colors.black,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: canSave
                      ? () {
                          context.read<ProfileNotifier>().changePassword(oldPwd, newPwd);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Salva",
                    style: TextStyle(
                      color: canSave ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openResetPasswordDialog(String? email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Reset password", style: TextStyle(color: Colors.black)),
          content: Text(
            "Invieremo una mail con il link di reset a ${email ?? "—"}. Continuare?",
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                context.read<ProfileNotifier>().sendResetPasswordEmail();
                Navigator.pop(context);
              },
              child: const Text(
                "Invia",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final pwd = passwordController.text;
            final canConfirm = pwd.isNotEmpty;

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Elimina account", style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Questa azione è IRREVERSIBILE. Tutti i tuoi dati saranno cancellati.",
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: const InputDecoration(
                      labelText: "Conferma con password",
                      labelStyle: TextStyle(color: Colors.black54),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    cursorColor: Colors.black,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: canConfirm
                      ? () {
                          final profileNotifier = context.read<ProfileNotifier>();
                          profileNotifier.deleteAccount(pwd, () {
                            profileNotifier.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Elimina",
                    style: TextStyle(
                      color: canConfirm ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
