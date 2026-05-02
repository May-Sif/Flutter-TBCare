import 'package:flutter/material.dart';
import 'package:tbc_app/services/auth_service.dart';
import 'package:tbc_app/theme.dart';
import 'package:tbc_app/pages/home_page.dart';
import 'package:tbc_app/pages/isi_datadiri.dart';

class LoginTab extends StatefulWidget {
  final TabController tabController;
  const LoginTab({super.key, required this.tabController});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();

  bool _rememberMe = false;
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await _auth.getSavedEmail();
    if (saved != null && mounted) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingEmail = true);
    await Future.delayed(
      const Duration(
        milliseconds: 600
      )
    );

    final result = _auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loadingEmail = false);

    if (result['success']) {
      if (_rememberMe) {
        await _auth.saveRememberMe(_emailCtrl.text.trim());
      } else {
        await _auth.clearRememberMe();
      }
      _navigate(
        email: _emailCtrl.text.trim(),
        isNewUser: result['isNewUser'] as bool,
      );
    } else {
      _snack(
        result['message'], 
        error: true
      );
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _loadingGoogle = true);
    final result = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loadingGoogle = false);

    if (result['success']) {
      _navigate(
        email: result['email'],
        name: result['name'],
        photoUrl: result['photoUrl'],
        isNewUser: result['isNewUser'] as bool,
      );
    } else {
      _snack(result['message'], error: true);
    }
  }

  void _navigate({
    required String email,
    String name = '',
    String? photoUrl,
    required bool isNewUser,
  }) {
    if (isNewUser) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IsiDataDiriPage(
            email: email,
            name: name,
            photoUrl: photoUrl,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            email: email,
            name: name,
            photoUrl: photoUrl,
          ),
        ),
      );
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Email'),
          _EmailField(controller: _emailCtrl),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel('Kata Sandi'),
            ],
          ),
          _PasswordField(
            controller: _passCtrl,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Kata sandi tidak boleh kosong'
                : null,
          ),
          const SizedBox(height: 12),

          _RememberMeCheckbox(
            value: _rememberMe,
            onChanged: (v) => setState(() => _rememberMe = v),
          ),
          const SizedBox(height: 20),

          _PrimaryButton(
            label: 'Masuk',
            isLoading: _loadingEmail,
            onPressed: _login,
          ),
          const SizedBox(height: 20),

          const _OrDivider(),
          const SizedBox(height: 16),

          _GoogleSignInButton(
            isLoading: _loadingGoogle,
            onPressed: _loginGoogle,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary
            )
        ),
      );
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'Masukkan alamat E-mail...',
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
          return 'Format email tidak sesuai';
        }
        return null;
      },
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? hint;
  const _PasswordField(
      {required this.controller, required this.validator, this.hint});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintStyle:
            const TextStyle(
              color: AppColors.textSecondary, 
              fontSize: 14
            ),
        prefixIcon: const Icon(
          Icons.lock_outline,
            color: AppColors.textSecondary, 
            size: 20
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class _RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RememberMeCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side:
                  const BorderSide(
                    color: AppColors.inputBorder, 
                    width: 1.5
                  ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Ingat saya di perangkat ini',
              style:
                  TextStyle(
                    fontSize: 13, 
                    color: AppColors.textSecondary
                  )
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _PrimaryButton(
      {required this.label,
      required this.isLoading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, 
                    strokeWidth: 2.5
                )
              )
            : Text(
              label,
                style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                )
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.divider
          )
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('atau',
              style: TextStyle(
                  color: AppColors.textSecondary, 
                  fontSize: 13
              )
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.divider
          )
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _GoogleSignInButton(
      {required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.inputBorder
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, 
                    color: AppColors.primary
                )
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  const Text('Masuk dengan Google',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary
                      )
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.82),
        start, sweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.16
          ..strokeCap = StrokeCap.round,
      );
    }

    arc(const Color(0xFFEA4335), -2.36, -1.40);
    arc(const Color(0xFFFBBC05), 2.36, -1.18);
    arc(const Color(0xFF34A853), 1.18, -1.18);
    arc(const Color(0xFF4285F4), -1.18, -1.18);

    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.82, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.16
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}