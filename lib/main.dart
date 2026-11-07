import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SevanexApp());

const navy = Color(0xFF102C45);
const blue = Color(0xFF1677C8);
const teal = Color(0xFF12A6A0);

class CustomerProfile {
  final String name, phone, address;
  const CustomerProfile({required this.name, required this.phone, required this.address});
  bool get isComplete => name.trim().isNotEmpty && RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone.trim()) && address.trim().isNotEmpty;
  static Future<CustomerProfile?> load() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString('profile_name') ?? '';
    final phone = p.getString('profile_phone') ?? '';
    final address = p.getString('profile_address') ?? '';
    final profile = CustomerProfile(name: name, phone: phone, address: address);
    return profile.isComplete ? profile : null;
  }
  static Future<void> save(String name, String phone, String address) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_name', name.trim());
    await p.setString('profile_phone', phone.trim());
    await p.setString('profile_address', address.trim());
  }
}

class BookingRequest {
  final String id, service, name, phone, address, description;
  BookingRequest({required this.id, required this.service, required this.name, required this.phone, required this.address, required this.description});
}

class BookingStore {
  static final List<BookingRequest> requests = [];
  static BookingRequest add({required String service, required CustomerProfile profile, required String description}) {
    final booking = BookingRequest(
      id: 'SVX-${DateTime.now().millisecondsSinceEpoch}', service: service,
      name: profile.name, phone: profile.phone, address: profile.address, description: description,
    );
    requests.insert(0, booking);
    return booking;
  }
}

class SevanexApp extends StatelessWidget {
  const SevanexApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SEVANEX', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: blue), scaffoldBackgroundColor: const Color(0xFFF5F8FB), appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white)),
    home: const RoleHome(),
  );
}

class RoleHome extends StatefulWidget {
  const RoleHome({super.key});
  @override
  State<RoleHome> createState() => _RoleHomeState();
}
class _RoleHomeState extends State<RoleHome> {
  CustomerProfile? profile;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await CustomerProfile.load(); if (mounted) setState(() => profile = p); }
  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(existing: profile)));
    await _load();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SEVANEX', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)), actions: [IconButton(tooltip: 'मेरी प्रोफाइल', onPressed: _openProfile, icon: const Icon(Icons.account_circle_outlined))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, blue]), borderRadius: BorderRadius.circular(22)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('हर सेवा, एक ही प्लेटफॉर्म पर।', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Book trusted local services. Earn with your skills.', style: TextStyle(color: Colors.white70, fontSize: 13)), SizedBox(height: 18), Row(children: [Icon(Icons.location_on, color: Colors.white, size: 17), SizedBox(width: 5), Text('Singrauli, Madhya Pradesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])])),
      const SizedBox(height: 18),
      Card(color: Colors.white, child: ListTile(leading: const Icon(Icons.person, color: blue), title: Text(profile?.name ?? 'Customer Profile सेट करें'), subtitle: Text(profile == null ? 'पहली बार नाम, मोबाइल और पता सेव करें' : '${profile!.phone} • ${profile!.address}'), trailing: const Icon(Icons.edit), onTap: _openProfile)),
      const SizedBox(height: 8), const Text('आप SEVANEX पर क्या करना चाहते हैं?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 12),
      RoleCard(icon: Icons.home_repair_service, title: 'मुझे सर्विस चाहिए', subtitle: 'घर, ऑफिस और रोजमर्रा की सेवाएँ बुक करें', color: blue, onTap: () async {
        if (profile == null) { await _openProfile(); if (profile == null) return; }
        if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage()));
      }),
      RoleCard(icon: Icons.handyman, title: 'मैं सर्विस पार्टनर हूँ', subtitle: 'काम पाएँ, सर्विस दें और कमाई करें', color: teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderPage()))),
      RoleCard(icon: Icons.admin_panel_settings, title: 'City Manager / Admin', subtitle: 'शहर की बुकिंग और पार्टनर संचालन देखें', color: navy, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerPage()))),
      const SizedBox(height: 14), const Center(child: Text('MVP • Customer profile saved on this device', style: TextStyle(color: Colors.black45, fontSize: 11))),
    ]),
  );
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
    await CustomerProfile.save(name.text, phone.text, address.text);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आपकी प्रोफाइल इस फोन में सेव हो गई।')));
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('मेरी प्रोफाइल')), body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
    const Text('एक बार अपनी जानकारी सेव करें। अगली बुकिंग में यह अपने आप भर जाएगी।', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18),
    TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'पूरा नाम *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().isEmpty ? 'नाम लिखें' : null), const SizedBox(height: 12),
    TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर *', counterText: '', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => v == null || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(v.trim()) ? 'सही 10 अंकों का मोबाइल नंबर लिखें' : null), const SizedBox(height: 12),
    TextFormField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'पूरा पता *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)), validator: (v) => v == null || v.trim().isEmpty ? 'पता लिखें' : null), const SizedBox(height: 18),
    FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'सेव हो रहा है…' : 'प्रोफाइल सेव करें')),
    const SizedBox(height: 10), const Text('नोट: यह MVP प्रोफाइल अभी इसी मोबाइल में सेव होती है। OTP और ऑनलाइन अकाउंट सिंक अभी जोड़े जाने बाकी हैं।', style: TextStyle(fontSize: 12, color: Colors.black54)),
  ])));
}

class RoleCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const RoleCard({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4EBF1))), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [CircleAvatar(radius: 25, backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color, size: 26)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54))])), const Icon(Icons.chevron_right, color: Colors.black45)]))));
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});
  static const categories = [
    ('इलेक्ट्रिशियन', 'वायरिंग, पंखा, लाइट', Icons.electrical_services), ('प्लंबर', 'नल, पाइप, लीकेज', Icons.plumbing), ('AC एवं उपकरण', 'AC, फ्रिज, वॉशिंग मशीन', Icons.ac_unit), ('हाउस क्लीनिंग', 'घर और बाथरूम सफाई', Icons.cleaning_services), ('कारपेंटर', 'फर्नीचर और फिटिंग', Icons.chair), ('पेंटिंग', 'घर और ऑफिस पेंटिंग', Icons.format_paint), ('वाहन सेवाएँ', 'कार वॉश और ड्राइवर', Icons.directions_car), ('कंप्यूटर एवं IT', 'कंप्यूटर रिपेयर और सपोर्ट', Icons.computer),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('सर्विस बुक करें')), body: ListView(padding: const EdgeInsets.all(16), children: [
    const Text('लोकप्रिय सर्विस', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 10),
    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: categories.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.25), itemBuilder: (context, i) { final item = categories[i]; return InkWell(borderRadius: BorderRadius.circular(16), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(service: item.$1))), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4EBF1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.$3, color: blue, size: 28), const SizedBox(height: 9), Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 3), Text(item.$2, style: const TextStyle(fontSize: 11, color: Colors.black54))]))); }),
  ]));
}

class BookingPage extends StatefulWidget { final String service; const BookingPage({super.key, required this.service}); @override State<BookingPage> createState() => _BookingPageState(); }
class _BookingPageState extends State<BookingPage> {
  final details = TextEditingController(); CustomerProfile? profile; BookingRequest? createdBooking; bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await CustomerProfile.load(); if (mounted) setState(() { profile = p; loading = false; }); }
  @override void dispose() { details.dispose(); super.dispose(); }
  Future<void> _editProfile() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(existing: profile))); await _load(); }
  void submit() { if (profile == null || createdBooking != null) return; FocusScope.of(context).unfocus(); setState(() => createdBooking = BookingStore.add(service: widget.service, profile: profile!, description: details.text.trim())); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('बुकिंग अनुरोध')), body: loading ? const Center(child: CircularProgressIndicator()) : profile == null ? Center(child: FilledButton(onPressed: _editProfile, child: const Text('पहले प्रोफाइल सेव करें'))) : ListView(padding: const EdgeInsets.all(18), children: [
    Text(widget.service, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 6), const Text('आपकी सेव की हुई जानकारी अपने आप जुड़ गई है।', style: TextStyle(color: Colors.black54)), const SizedBox(height: 16),
    Card(color: Colors.white, child: ListTile(leading: const Icon(Icons.person, color: blue), title: Text(profile!.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${profile!.phone}\n${profile!.address}'), isThreeLine: true, trailing: IconButton(icon: const Icon(Icons.edit), onPressed: _editProfile))),
    const SizedBox(height: 14), TextField(controller: details, maxLines: 3, decoration: const InputDecoration(labelText: 'सर्विस की समस्या बताएँ', border: OutlineInputBorder(), alignLabelWithHint: true)), const SizedBox(height: 18),
    FilledButton.icon(onPressed: createdBooking == null ? submit : null, icon: const Icon(Icons.send), label: const Text('बुकिंग अनुरोध भेजें'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
    if (createdBooking != null) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE7F7EF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFB8E5CC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.check_circle, color: Color(0xFF176B42)), SizedBox(width: 8), Text('बुकिंग दर्ज हो गई!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF176B42)))]), const SizedBox(height: 8), Text('Booking ID: ${createdBooking!.id}', style: const TextStyle(fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 4), const Text('यह डेमो बुकिंग अभी इसी ऐप सेशन में रहती है। स्थायी ऑनलाइन बुकिंग अगले चरण में जोड़ी जाएगी।', style: TextStyle(fontSize: 12, color: Color(0xFF176B42)))]))],
  ]));
}

class ProviderPage extends StatelessWidget {
  const ProviderPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Partner Dashboard')), body: ListView(padding: const EdgeInsets.all(18), children: [
    const Text('नमस्ते, Service Partner', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 5), const Text('Singrauli service area • Demo account', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18),
    const Row(children: [Expanded(child: MetricCard(label: 'आज की कमाई', value: '₹850', icon: Icons.currency_rupee)), SizedBox(width: 10), Expanded(child: MetricCard(label: 'पूरे काम', value: '4', icon: Icons.task_alt))]), const SizedBox(height: 18), const Text('बुकिंग अनुरोध', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 10),
    if (BookingStore.requests.isEmpty) const Text('अभी कोई नई बुकिंग नहीं है।') else ...BookingStore.requests.map((b) => Card(color: Colors.white, child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFEAF3FC), child: Icon(Icons.work_outline, color: blue)), title: Text(b.service, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${b.name} • ${b.phone}\n${b.address}\n${b.id}\n${b.description}'), isThreeLine: true, trailing: const Text('नया', style: TextStyle(color: blue, fontWeight: FontWeight.w700))))),
    const SizedBox(height: 12), const Text('यह शुरुआती डेमो है। सर्वर पर बुकिंग सिंक, पार्टनर अलर्ट, KYC और payout अगले चरण में आएँगे।', style: TextStyle(fontSize: 12, color: Colors.black54)),
  ]));
}

class ManagerPage extends StatelessWidget { const ManagerPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('City Manager')), body: const Center(child: Text('City Manager Dashboard • Demo'))); }
class MetricCard extends StatelessWidget { final String label, value; final IconData icon; const MetricCard({super.key, required this.label, required this.value, required this.icon}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4EBF1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: blue), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))])); }
