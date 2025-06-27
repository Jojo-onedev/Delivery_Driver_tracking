import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../config/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedVehicle;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        vehicle: _selectedVehicle,
        licensePlate: _selectedVehicle != null && _selectedVehicle != 'on_foot' && _licensePlateController.text.isNotEmpty
            ? _licensePlateController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (success) {
        // Redirection vers l'écran de connexion après inscription réussie
        Navigator.pushReplacementNamed(context, Routes.login);
        
        // Afficher un message de succès
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Veuillez vous connecter.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'inscription. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer un compte',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),
                // Champs de formulaire
                CustomTextField(
                  controller: _nameController,
                  label: 'Nom complet',
                  hint: 'Entrez votre nom complet',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Entrez votre email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  hint: 'Entrez votre numéro de téléphone',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Sélecteur de véhicule
                DropdownButtonFormField<String>(
                  value: _selectedVehicle,
                  decoration: InputDecoration(
                    labelText: 'Véhicule',
                    hintText: 'Sélectionnez votre véhicule',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'on_foot',
                      child: Text('À pied'),
                    ),
                    DropdownMenuItem(
                      value: 'car',
                      child: Text('Voiture'),
                    ),
                    DropdownMenuItem(
                      value: 'motorbike',
                      child: Text('Moto'),
                    ),
                    DropdownMenuItem(
                      value: 'bicycle',
                      child: Text('Vélo'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicle = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un véhicule';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Champ de saisie de la plaque d'immatriculation
                _selectedVehicle != null && _selectedVehicle != 'on_foot'
                    ? CustomTextField(
                        controller: _licensePlateController,
                        label: 'Plaque d\'immatriculation',
                        hint: 'Entrez la plaque d\'immatriculation de votre véhicule',
                        prefixIcon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer la plaque d\'immatriculation de votre véhicule';
                          }
                          return null;
                        },
                      )
                    : const SizedBox(),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: 'Entrez votre mot de passe',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  hint: 'Confirmez votre mot de passe',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Bouton d'inscription
                CustomButton(
                  onPressed: _isLoading ? null : _register,
                  text: 'S\'inscrire',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                // Lien vers la page de connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà inscrit ? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, Routes.login);
                      },
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}