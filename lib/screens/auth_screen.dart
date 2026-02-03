// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flugo_chat/components/app_messenger.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (_isLogin) return null;
    if (v == null || v.trim().length < 2) return 'Informe seu nome.';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe seu e-mail.';
    if (!v.contains('@')) return 'Informe um e-mail válido.';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Informe sua senha.';
    if (v.length < 6) return 'Senha deve ter ao menos 6 caracteres.';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (_isLogin) return null;
    if (v == null || v.isEmpty) return 'Confirme sua senha.';
    if (v != _passwordController.text) return 'As senhas não conferem.';
    return null;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final pass = _passwordController.text;
      final name = _nameController.text.trim();

      if (_isLogin) {
        await auth.signInWithEmailAndPassword(email: email, password: pass);
        return;
      }

      final methods = await auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        AppMessenger.show('Esse e-mail já está em uso.');
        return;
      }

      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      await cred.user?.updateDisplayName(name.isEmpty ? 'Usuário' : name);
      await cred.user?.reload();
      return;
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'E-mail inválido.',
        'invalid-credential' => 'Credenciais incorretas.',
        'user-not-found' => 'Credenciais incorretas.',
        'wrong-password' => 'Credenciais incorretas.',
        'email-already-in-use' => 'Esse e-mail já está em uso.',
        'weak-password' => 'Senha fraca (mínimo recomendado: 6 caracteres).',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
        _ => 'Erro de autenticação: ${e.message ?? e.code}',
      };

      AppMessenger.show(msg);
    } catch (e) {
      AppMessenger.show('Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Bem-vindo!' : 'Criar conta';
    final subtitle = _isLogin
        ? 'Entre para acessar o chat'
        : 'Cadastre-se para começar';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade700,
              Colors.green.shade400,
              Colors.teal.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 10,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: !_isLogin
                                ? Column(
                                    key: const ValueKey('name'),
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Nome',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: _validateName,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textInputAction: _isLogin
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: (_) {
                              if (_isLogin) _submit();
                            },
                          ),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: !_isLogin
                                ? Column(
                                    key: const ValueKey('confirm'),
                                    children: [
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _hideConfirmPassword,
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(
                                          labelText: 'Confirmar senha',
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _hideConfirmPassword =
                                                  !_hideConfirmPassword,
                                            ),
                                            icon: Icon(
                                              _hideConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                        validator: _validateConfirmPassword,
                                        onFieldSubmitted: (_) => _submit(),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: _loading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Text(
                                        key: const ValueKey('text'),
                                        _isLogin ? 'Entrar' : 'Cadastrar',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? 'Ainda não tem conta? '
                                    : 'Já tem conta? ',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              TextButton(
                                onPressed: _loading ? null : _toggleMode,
                                child: Text(
                                  _isLogin ? 'Criar agora' : 'Entrar',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
