import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replace these two placeholders with your Supabase Project URL and
/// anon/publishable key. NEVER put the service_role key in a mobile app.
const supabaseUrl = 'https://qnddlauyiftfulxjknss.supabase.co';
const supabaseAnonKey = 'sb_publishable_TT4QdJKlaT3rXXfiI3wCJg_U9E931Td';

const navy = Color(0xFF102C45);
const blue = Color(0xFF1677C8);
const teal = Color(0xFF12A6A0);

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.startsWith('PASTE_') || supabaseAnonKey.startsWith('PASTE_')) {
    runApp(const SetupRequiredApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SevanexApp());
}

class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(title: const Text('SEVANEX Setup')),
      body: const Padding(
        padding: EdgeInsets.all(22),
        child: Text(
          'Supabase configuration बाकी है। main.dart में supabaseUrl और '
          'supabaseAnonKey में अपने Project URL और anon/publishable key डालें। '
          'service_role key कभी न डालें।',
          style: TextStyle(fontSize: 17),
        ),
      ),
    ),
  );
}

class CustomerProfile {
  final String name, phone, address;
  final int? cityId;
  const CustomerProfile({
    required this.name, required this.phone, required this.address, this.cityId,
  });
  bool get isComplete => name.trim().isNotEmpty &&
      RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone.trim()) &&
      address.trim().isNotEmpty;

  static Future<CustomerProfile?> load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final row = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    final profile = CustomerProfile(
      name: (row['full_name'] ?? '').toString(),
      phone: (row['phone'] ?? '').toString(),
      address: '',
      cityId: row['city_id'] as int?,
    );
    // Address is retained locally because the existing profiles table has no address column.
    final prefs = await SharedPreferences.getInstance();
    final localAddress = prefs.getString('profile_address') ?? '';
    final merged = CustomerProfile(
      name: profile.name,
      phone: profile.phone,
      address: localAddress,
      cityId: profile.cityId,
    );
    return merged.isComplete ? merged : null;
  }

  static Future<void> save(String name, String phone, String address) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('पहले Email और Password से Login करें।');
    final old = await supabase.from('profiles').select('city_id').eq('id', user.id).maybeSingle();
    await supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': name.trim(),
      'phone': phone.trim(),
      'city_id': old?['city_id'] ?? 1,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_address', address.trim());
  }
}

class SevanexApp extends StatelessWidget {
  const SevanexApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SEVANEX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: const Color(0xFFF5F8FB),
      appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) {
      if (supabase.auth.currentSession == null) return const AuthPage();
      return const RoleHome();
    },
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool createAccount = false, busy = false;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Email लिखें और Password कम से कम 6 अक्षर का रखें।');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      if (createAccount) {
        final result = await supabase.auth.signUp(
          email: email.text.trim(), password: password.text,
        );
        if (result.session == null && mounted) {
          setState(() => error = 'Account बन गया। Email confirmation पूरा करके Login करें।');
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email.text.trim(), password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = 'Login में समस्या: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SEVANEX Login')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      const SizedBox(height: 24),
      const Text('SEVANEX', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)),
      const Text('हर सेवा, एक ही प्लेटफॉर्म पर।'),
      const SizedBox(height: 28),
      TextField(controller: email, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true,
        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
      FilledButton(onPressed: busy ? null : submit,
        child: Text(busy ? 'कृपया प्रतीक्षा करें…' : createAccount ? 'नया अकाउंट बनाएँ' : 'Login करें')),
      TextButton(onPressed: busy ? null : () => setState(() { createAccount = !createAccount; error = null; }),
        child: Text(createAccount ? 'पहले से अकाउंट है? Login' : 'नया Customer Account बनाएँ')),
    ]),
  );
}

class RoleHome extends StatefulWidget {
  const RoleHome({super.key});
  @override
  State<RoleHome> createState() => _RoleHomeState();
}
class _RoleHomeState extends State<RoleHome> {
  CustomerProfile? profile;
  String role = 'customer';
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final user = supabase.auth.currentUser!;
      final row = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      role = (row?['role'] ?? 'customer').toString();
      profile = await CustomerProfile.load();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }
  Future<void> openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(existing: profile)));
    await load();
  }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('SEVANEX', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: openProfile, icon: const Icon(Icons.account_circle_outlined)),
          IconButton(tooltip: 'Logout', onPressed: () => supabase.auth.signOut(), icon: const Icon(Icons.logout)),
        ]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, blue]), borderRadius: BorderRadius.circular(22)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('हर सेवा, एक ही प्लेटफॉर्म पर।', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8), Text('Book trusted local services. Earn with your skills.', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 18), Text('Singrauli, Madhya Pradesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ])),
        const SizedBox(height: 16),
        Card(color: Colors.white, child: ListTile(
          title: Text(profile?.name ?? 'Customer Profile सेट करें'),
          subtitle: Text(profile?.phone ?? 'नाम, मोबाइल और पता सेव करें'),
          trailing: const Icon(Icons.edit), onTap: openProfile)),
        const SizedBox(height: 12),
        RoleCard(icon: Icons.home_repair_service, title: 'मुझे सर्विस चाहिए',
          subtitle: 'घर, ऑफिस और रोजमर्रा की सेवाएँ बुक करें', color: blue,
          onTap: () async {
            if (profile == null) { await openProfile(); if (profile == null) return; }
            if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage()));
          }),
        RoleCard(icon: Icons.handyman, title: 'मैं सर्विस पार्टनर हूँ',
          subtitle: 'अपनी बुकिंग देखें', color: teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderPage()))),
        if (role == 'admin' || role == 'manager')
          RoleCard(icon: Icons.admin_panel_settings, title: 'Admin Dashboard',
            subtitle: 'Online bookings और संचालन देखें', color: navy,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerPage()))),
      ]),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final CustomerProfile? existing;
  const ProfilePage({super.key, this.existing});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final address = TextEditingController(text: widget.existing?.address ?? '');
  bool saving = false;
  @override
  void dispose() { name.dispose(); phone.dispose(); address.dispose(); super.dispose(); }
  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await CustomerProfile.save(name.text, phone.text, address.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('प्रोफाइल Supabase में सेव हो गई। पता इस फोन में भी सुरक्षित है।')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('सेव नहीं हुआ: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('मेरी प्रोफाइल')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'पूरा नाम *', border: OutlineInputBorder()),
        validator: (v) => v == null || v.trim().isEmpty ? 'नाम लिखें' : null),
      const SizedBox(height: 12),
      TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10,
        decoration: const InputDecoration(labelText: 'मोबाइल नंबर *', border: OutlineInputBorder()),
        validator: (v) => v == null || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(v.trim()) ? 'सही 10 अंकों का मोबाइल नंबर लिखें' : null),
      const SizedBox(height: 12),
      TextFormField(controller: address, maxLines: 3,
        decoration: const InputDecoration(labelText: 'पूरा पता *', border: OutlineInputBorder()),
        validator: (v) => v == null || v.trim().isEmpty ? 'पता लिखें' : null),
      const SizedBox(height: 18),
      FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'सेव हो रहा है…' : 'प्रोफाइल सेव करें')),
    ])),
  );
}

class RoleCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const RoleCard({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4EBF1))),
    child: ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
      subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});
  static const categories = [
    ('इलेक्ट्रिशियन', 'वायरिंग, पंखा, लाइट', 1, Icons.electrical_services),
    ('प्लंबर', 'नल, पाइप, लीकेज', 2, Icons.plumbing),
    ('AC एवं उपकरण', 'AC, फ्रिज, वॉशिंग मशीन', 3, Icons.ac_unit),
    ('हाउस क्लीनिंग', 'घर और बाथरूम सफाई', 4, Icons.cleaning_services),
    ('कारपेंटर', 'फर्नीचर और फिटिंग', 5, Icons.chair),
    ('पेंटिंग', 'घर और ऑफिस पेंटिंग', 6, Icons.format_paint),
    ('वाहन सेवाएँ', 'कार वॉश और ड्राइवर', 7, Icons.directions_car),
    ('कंप्यूटर एवं IT', 'कंप्यूटर रिपेयर और सपोर्ट', 8, Icons.computer),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('सर्विस बुक करें')),
    body: GridView.builder(padding: const EdgeInsets.all(16), itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15),
      itemBuilder: (context, i) {
        final item = categories[i];
        return Card(color: Colors.white, child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(service: item.$1, categoryId: item.$3))),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(item.$4, color: blue, size: 30), const SizedBox(height: 8),
            Text(item.$1, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
            Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ]))));
      }),
  );
}

class BookingPage extends StatefulWidget {
  final String service; final int categoryId;
  const BookingPage({super.key, required this.service, required this.categoryId});
  @override
  State<BookingPage> createState() => _BookingPageState();
}
class _BookingPageState extends State<BookingPage> {
  final details = TextEditingController();
  CustomerProfile? profile;
  bool loading = true, saving = false;
  int? bookingId;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { profile = await CustomerProfile.load(); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }
  @override
  void dispose() { details.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (profile == null || saving || bookingId != null) return;
    setState(() => saving = true);
    try {
      final user = supabase.auth.currentUser!;
      final row = await supabase.from('bookings').insert({
        'customer_id': user.id,
        'city_id': profile!.cityId ?? 1,
        'category_id': widget.categoryId,
        'description': '${widget.service}: ${details.text.trim()}',
        'address': profile!.address,
        'status': 'requested',
      }).select('id').single();
      if (mounted) setState(() => bookingId = row['id'] as int);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('बुकिंग सेव नहीं हुई: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('बुकिंग अनुरोध')),
      body: profile == null ? const Center(child: Text('पहले प्रोफाइल पूरी करें।')) :
      ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.service, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy)),
        Card(color: Colors.white, child: ListTile(title: Text(profile!.name), subtitle: Text('${profile!.phone}\n${profile!.address}'), isThreeLine: true)),
        const SizedBox(height: 12),
        TextField(controller: details, maxLines: 3, decoration: const InputDecoration(labelText: 'सर्विस की समस्या बताएँ', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        FilledButton(onPressed: saving || bookingId != null ? null : submit,
          child: Text(saving ? 'भेज रहे हैं…' : 'ऑनलाइन बुकिंग भेजें')),
        if (bookingId != null) Padding(padding: const EdgeInsets.only(top: 18),
          child: Text('बुकिंग सफल! Booking ID: $bookingId', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class ProviderPage extends StatefulWidget {
  const ProviderPage({super.key});
  @override
  State<ProviderPage> createState() => _ProviderPageState();
}
class _ProviderPageState extends State<ProviderPage> {
  bool loading = true; List<Map<String, dynamic>> rows = []; String? message;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final user = supabase.auth.currentUser!;
      final provider = await supabase.from('provider_profiles').select('id,kyc_status').eq('id', user.id).maybeSingle();
      if (provider == null) { message = 'आपका Provider Profile अभी नहीं बना है। Admin approval के बाद बुकिंग दिखाई देंगी।'; }
      else if (provider['kyc_status'] != 'approved') { message = 'आपका KYC अभी ${provider['kyc_status']} स्थिति में है।'; }
      else {
        rows = List<Map<String, dynamic>>.from(await supabase.from('bookings').select().eq('provider_id', user.id).order('created_at', ascending: false));
      }
    } catch (e) { message = 'डेटा लोड नहीं हुआ: $e'; }
    if (mounted) setState(() => loading = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Partner Dashboard')),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: () async { setState(() => loading = true); await load(); },
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (message != null) Text(message!),
        ...rows.map((b) => Card(child: ListTile(title: Text('Booking #${b['id']}'), subtitle: Text('${b['description']}\n${b['address']}\nStatus: ${b['status']}')))),
      ]),
    ));
}

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});
  @override
  State<ManagerPage> createState() => _ManagerPageState();
}
class _ManagerPageState extends State<ManagerPage> {
  bool loading = true; String? error; List<Map<String, dynamic>> bookings = [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      bookings = List<Map<String, dynamic>>.from(
        await supabase.from('bookings').select().order('created_at', ascending: false));
      error = null;
    } catch (e) { error = 'बुकिंग लोड नहीं हुई: $e'; }
    if (mounted) setState(() => loading = false);
  }
  Future<void> updateStatus(int id, String status) async {
    try {
      await supabase.from('bookings').update({'status': status}).eq('id', id);
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status नहीं बदला: $e')));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SEVANEX Admin Dashboard'), actions: [
      IconButton(onPressed: () { setState(() => loading = true); load(); }, icon: const Icon(Icons.refresh)),
    ]),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Total Bookings: ${bookings.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navy)),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        if (bookings.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('अभी कोई ऑनलाइन बुकिंग नहीं है।')),
        ...bookings.map((b) {
          final id = b['id'] as int;
          return Card(color: Colors.white, margin: const EdgeInsets.only(top: 10),
            child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Booking #$id', style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
              Text('Customer ID: ${b['customer_id']}'),
              Text('Service ID: ${b['category_id']} • City ID: ${b['city_id']}'),
              Text('Address: ${b['address']}'),
              Text('Description: ${b['description']}'),
              Text('Status: ${b['status']}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton(onPressed: () => updateStatus(id, 'accepted'), child: const Text('Accept')),
                OutlinedButton(onPressed: () => updateStatus(id, 'in_progress'), child: const Text('In Progress')),
                OutlinedButton(onPressed: () => updateStatus(id, 'completed'), child: const Text('Complete')),
                OutlinedButton(onPressed: () => updateStatus(id, 'cancelled'), child: const Text('Cancel')),
              ]),
            ])),
          );
        }),
      ]),
    ),
  );
}
