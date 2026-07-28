// lib/screens/login_screen.dart -- Login / Register + Phone OTP screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // 0 = login/register, 1 = phone input, 2 = OTP input
  int _mode = 0;
  bool _isLogin = true;
  bool _obscure = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+62');
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Phone auth state
  String? _verificationId;
  bool _phoneLoading = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isLogin = !_isLogin);
    _fadeCtrl.forward(from: 0);
  }

  void _setMode(int m) {
    setState(() {
      _mode = m;
      _phoneError = null;
    });
    _fadeCtrl.forward(from: 0);
  }

  // ── Email/Password Auth ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<app_auth.AuthProvider>();
    bool ok;
    if (_isLogin) {
      ok = await auth.login(email: _emailCtrl.text, password: _passCtrl.text);
    } else {
      ok = await auth.register(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          name: _nameCtrl.text);
    }
    if (!ok && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.coral),
      );
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Masukkan email terlebih dahulu')));
      return;
    }
    final auth = context.read<app_auth.AuthProvider>();
    final ok = await auth.resetPassword(_emailCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Link reset dikirim ke ${_emailCtrl.text}'
            : 'Gagal mengirim email reset.'),
        backgroundColor: ok ? AppColors.primary : AppColors.coral,
      ));
    }
  }

  // ── Phone Auth ──────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _phoneError = 'Nomor HP tidak valid');
      return;
    }
    setState(() { _phoneLoading = true; _phoneError = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval / instant verify (Android only)
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _phoneLoading = false;
          _phoneError = _friendlyPhoneError(e.code);
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _phoneLoading = false;
          _mode = 2; // go to OTP screen
        });
        _fadeCtrl.forward(from: 0);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _phoneError = 'Kode OTP harus 6 digit');
      return;
    }
    if (_verificationId == null) return;

    setState(() { _phoneLoading = true; _phoneError = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _phoneLoading = false;
        _phoneError = _friendlyPhoneError(e.code);
      });
    }
  }

  String _friendlyPhoneError(String code) {
    switch (code) {
      case 'invalid-phone-number': return 'Format nomor HP tidak valid. Gunakan format +62...';
      case 'too-many-requests': return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-verification-code': return 'Kode OTP salah. Coba lagi.';
      case 'session-expired': return 'Sesi OTP kadaluarsa. Kirim ulang kode.';
      case 'quota-exceeded': return 'Kuota SMS habis. Coba lagi besok.';
      case 'missing-phone-number': return 'Masukkan nomor HP terlebih dahulu.';
      default: return 'Terjadi kesalahan ($code). Coba lagi.';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: _mode == 1
                ? _buildPhoneInput()
                : _mode == 2
                    ? _buildOtpInput()
                    : _buildEmailForm(),
          ),
        ),
      ),
    );
  }

  // ── Email/Password form ─────────────────────────────────────────────────

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _header(),
          const SizedBox(height: 36),

          // Login / Daftar tab
          _tabToggle(),
          const SizedBox(height: 24),

          if (!_isLogin) ...[
            _field(controller: _nameCtrl, label: 'Nama Lengkap',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
          ],

          _field(controller: _emailCtrl, label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              }),
          const SizedBox(height: 12),

          _field(controller: _passCtrl, label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18, color: AppColors.textMuted),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (!_isLogin && v.length < 6) return 'Minimal 6 karakter';
                return null;
              }),

          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _forgotPassword,
                child: Text('Lupa password?',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                        fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Submit button
          Consumer<app_auth.AuthProvider>(
            builder: (_, auth, __) => _primaryBtn(
              label: _isLogin ? 'MASUK' : 'BUAT AKUN',
              loading: auth.isLoading,
              onTap: _submit,
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau', style: TextStyle(color: AppColors.textMuted,
                  fontFamily: 'Nunito', fontSize: 12)),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ]),
          const SizedBox(height: 16),

          // Phone login button
          _outlineBtn(
            icon: Icons.phone_outlined,
            label: 'Masuk dengan Nomor HP',
            onTap: () => _setMode(1),
          ),
          const SizedBox(height: 10),

          // Google Sign-In button
          Consumer<app_auth.AuthProvider>(
            builder: (_, auth, __) => _socialBtn(
              icon: Icons.g_mobiledata_rounded,
              label: 'Masuk dengan Google',
              color: const Color(0xFF4285F4),
              loading: auth.isLoading,
              onTap: () async {
                final ok = await auth.signInWithGoogle();
                if (!ok && mounted && auth.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(auth.errorMessage!),
                      backgroundColor: AppColors.coral));
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // Anonymous (guest) login
          Consumer<app_auth.AuthProvider>(
            builder: (_, auth, __) => _outlineBtn(
              icon: Icons.person_outline_rounded,
              label: 'Masuk sebagai Tamu',
              onTap: () async {
                final ok = await auth.signInAnonymously();
                if (!ok && mounted && auth.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(auth.errorMessage!),
                      backgroundColor: AppColors.coral));
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Mode tamu: data tidak tersimpan di cloud',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 10,
                    color: AppColors.textMuted)),
          ),
          const SizedBox(height: 20),

          // Toggle register/login
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
                  children: [
                    TextSpan(
                      text: _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textMuted)),
                    TextSpan(
                      text: _isLogin ? 'Daftar sekarang' : 'Masuk',
                      style: TextStyle(color: AppColors.accent,
                          fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Data tersimpan offline jika tidak ada internet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                    color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  // ── Phone number input ──────────────────────────────────────────────────

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _header(),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _setMode(0),
          child: Row(children: [
            Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('Kembali', style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.accent, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 28),

        Text('Nomor HP', style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 8),

        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
              color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '+62 812 3456 7890',
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
            prefixIcon: const Icon(Icons.phone_outlined, size: 18,
                color: AppColors.textMuted),
          ),
        ),

        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Text(_phoneError!, style: TextStyle(color: AppColors.coral,
              fontFamily: 'Nunito', fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Text('Format: +62 diikuti nomor tanpa awalan 0.\nContoh: +6281234567890',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                color: AppColors.textMuted)),
        const SizedBox(height: 28),

        _primaryBtn(
          label: 'KIRIM KODE OTP',
          loading: _phoneLoading,
          onTap: _sendOtp,
        ),
      ],
    );
  }

  // ── OTP input ───────────────────────────────────────────────────────────

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _header(),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _setMode(1),
          child: Row(children: [
            Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('Ganti nomor', style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.accent, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kode OTP dikirim ke ${_phoneCtrl.text}',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        Text('Masukkan Kode OTP', style: TextStyle(fontFamily: 'Nunito',
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 8),

        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 22,
              fontWeight: FontWeight.w900, color: AppColors.textPrimary,
              letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.3),
                letterSpacing: 8),
          ),
        ),

        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Text(_phoneError!, style: TextStyle(color: AppColors.coral,
              fontFamily: 'Nunito', fontSize: 12)),
        ],
        const SizedBox(height: 28),

        _primaryBtn(
          label: 'VERIFIKASI',
          loading: _phoneLoading,
          onTap: _verifyOtp,
        ),
        const SizedBox(height: 16),

        Center(
          child: GestureDetector(
            onTap: () { _otpCtrl.clear(); _setMode(1); },
            child: Text('Kirim ulang kode',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────

  Widget _header() {
    return Column(children: [
      Center(
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
          ),
          child: const Icon(Icons.eco_rounded, size: 36, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 16),
      Center(child: Text('SNBT TRACKER',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
              fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 2))),
      Center(child: Text(
          _mode == 0
              ? (_isLogin ? 'Masuk ke akunmu' : 'Buat akun baru')
              : _mode == 1 ? 'Masuk via Nomor HP' : 'Verifikasi OTP',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textMuted))),
    ]);
  }

  Widget _tabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(children: [
        _tabBtn('Masuk', _isLogin, () { if (!_isLogin) _toggle(); }),
        _tabBtn('Daftar', !_isLogin, () { if (_isLogin) _toggle(); }),
      ]),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: AppRadius.pill,
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.textMuted)),
          ),
        ),
      ),
    );
  }

  Widget _primaryBtn({required String label, required bool loading,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
                fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _outlineBtn({required IconData icon, required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: AppColors.accent),
        label: Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w800, color: AppColors.accent)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),
    );
  }

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 22, color: Colors.white),
        label: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w800, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
            : null,
      ),
    );
  }
}
