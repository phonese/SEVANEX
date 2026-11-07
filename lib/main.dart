import 'package:flutter/material.dart';

void main() => runApp(const SevanexApp());

const navy = Color(0xFF102C45);
const blue = Color(0xFF1677C8);
const teal = Color(0xFF12A6A0);

class SevanexApp extends StatelessWidget {
  const SevanexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEVANEX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF5F8FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const RoleHome(),
    );
  }
}

class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEVANEX', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('SINGRAULI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [navy, blue]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('हर सेवा, एक ही प्लेटफॉर्म पर।',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Book trusted local services. Earn with your skills.',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 18),
                Row(children: [
                  Icon(Icons.location_on, color: Colors.white, size: 17),
                  SizedBox(width: 5),
                  Text('Singrauli, Madhya Pradesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('आप SEVANEX पर क्या करना चाहते हैं?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
          const SizedBox(height: 12),
          RoleCard(
            icon: Icons.home_repair_service,
            title: 'मुझे सर्विस चाहिए',
            subtitle: 'घर, ऑफिस और रोजमर्रा की सेवाएँ बुक करें',
            color: blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage())),
          ),
          RoleCard(
            icon: Icons.handyman,
            title: 'मैं सर्विस पार्टनर हूँ',
            subtitle: 'काम पाएँ, सर्विस दें और कमाई करें',
            color: teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderPage())),
          ),
          RoleCard(
            icon: Icons.admin_panel_settings,
            title: 'City Manager / Admin',
            subtitle: 'शहर की बुकिंग और पार्टनर संचालन देखें',
            color: navy,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerPage())),
          ),
          const SizedBox(height: 18),
          const Center(child: Text('MVP PREVIEW • Version 0.1.0', style: TextStyle(color: Colors.black45, fontSize: 11))),
        ],
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const RoleCard({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4EBF1))),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(children: [
          CircleAvatar(radius: 25, backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ]),
      ),
    ),
  );
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  static const categories = [
    ('इलेक्ट्रिशियन', 'वायरिंग, पंखा, लाइट', Icons.electrical_services),
    ('प्लंबर', 'नल, पाइप, लीकेज', Icons.plumbing),
    ('AC एवं उपकरण', 'AC, फ्रिज, वॉशिंग मशीन', Icons.ac_unit),
    ('हाउस क्लीनिंग', 'घर और बाथरूम सफाई', Icons.cleaning_services),
    ('कारपेंटर', 'फर्नीचर और फिटिंग', Icons.chair),
    ('पेंटिंग', 'घर और ऑफिस पेंटिंग', Icons.format_paint),
    ('वाहन सेवाएँ', 'कार वॉश और ड्राइवर', Icons.directions_car),
    ('कंप्यूटर एवं IT', 'कंप्यूटर रिपेयर और सपोर्ट', Icons.computer),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('सर्विस बुक करें')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        decoration: InputDecoration(
          hintText: 'कौन-सी सर्विस चाहिए?',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 18),
      const Text('लोकप्रिय सर्विस', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.25),
        itemBuilder: (context, i) {
          final item = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(service: item.$1))),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4EBF1))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(item.$3, color: blue, size: 28),
                const SizedBox(height: 9),
                Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
                const SizedBox(height: 3),
                Text(item.$2, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 18),
      const Text('अगला कदम', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
      const Text('किसी सर्विस को चुनकर बुकिंग अनुरोध भेजें। यह शुरुआती डेमो फ्लो है; लाइव बुकिंग के लिए backend जोड़ा जाएगा.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]),
  );
}

class BookingRequest {
  final String id;
  final String service;
  final String customerName;
  final String phone;
  final String address;
  final String description;
  final DateTime createdAt;

  BookingRequest({
    required this.id,
    required this.service,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.description,
    required this.createdAt,
  });
}

class BookingStore {
  BookingStore._();
  static final List<BookingRequest> requests = [];

  static BookingRequest add({
    required String service,
    required String customerName,
    required String phone,
    required String address,
    required String description,
  }) {
    final request = BookingRequest(
      id: 'SVX-${DateTime.now().millisecondsSinceEpoch}',
      service: service,
      customerName: customerName,
      phone: phone,
      address: address,
      description: description,
      createdAt: DateTime.now(),
    );
    requests.insert(0, request);
    return request;
  }
}

class BookingPage extends StatefulWidget {
  final String service;
  const BookingPage({super.key, required this.service});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final customerName = TextEditingController();
  final phone = TextEditingController();
  final details = TextEditingController();
  final address = TextEditingController();
  final formKey = GlobalKey<FormState>();
  BookingRequest? createdBooking;

  @override
  void dispose() {
    customerName.dispose();
    phone.dispose();
    details.dispose();
    address.dispose();
    super.dispose();
  }

  void submitBooking() {
    if (createdBooking != null) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final booking = BookingStore.add(
      service: widget.service,
      customerName: customerName.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      description: details.text.trim(),
    );
    setState(() => createdBooking = booking);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('आपका बुकिंग अनुरोध सफलतापूर्वक दर्ज हो गया।')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('बुकिंग अनुरोध')),
    body: Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.service, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 6),
        const Text('अपनी जानकारी भरें। अनुरोध Partner Dashboard में दिखाई देगा।', style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 18),
        TextFormField(
          controller: customerName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'आपका नाम *', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'कृपया अपना नाम लिखें।' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(labelText: 'मोबाइल नंबर *', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder(), counterText: ''),
          validator: (value) => (value == null || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(value.trim())) ? '10 अंकों का सही मोबाइल नंबर लिखें।' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: details,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'सर्विस की समस्या बताएँ', alignLabelWithHint: true, border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: address,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'पूरा पता / लोकेशन *', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'कृपया पूरा पता लिखें।' : null,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: createdBooking == null ? submitBooking : null,
          icon: const Icon(Icons.send),
          label: const Text('बुकिंग अनुरोध भेजें'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        if (createdBooking != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE7F7EF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFB8E5CC))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.check_circle, color: Color(0xFF176B42)), SizedBox(width: 8), Text('बुकिंग दर्ज हो गई!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF176B42)))]),
              const SizedBox(height: 8),
              Text('Booking ID: ${createdBooking!.id}', style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
              const SizedBox(height: 4),
              const Text('यह अनुरोध इस ऐप के Partner Dashboard में उपलब्ध है। अभी यह केवल इसी ऐप सेशन में सेव है; ऐप बंद करने पर डेटा सुरक्षित नहीं रहेगा।', style: TextStyle(fontSize: 12, color: Color(0xFF176B42))),
            ]),
          ),
        ],
      ]),
    ),
  );
}

class ProviderPage extends StatelessWidget {
  const ProviderPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Partner Dashboard')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('नमस्ते, Service Partner', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 5),
      const Text('Singrauli service area • Demo account', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 18),
      const Row(children: [
        Expanded(child: MetricCard(label: 'आज की कमाई', value: '₹850', icon: Icons.currency_rupee)),
        SizedBox(width: 10),
        Expanded(child: MetricCard(label: 'पूरे काम', value: '4', icon: Icons.task_alt)),
      ]),
      const SizedBox(height: 18),
      const Text('बुकिंग अनुरोध', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 10),
      if (BookingStore.requests.isEmpty)
        const Text('अभी कोई नई बुकिंग नहीं है। Customer ऐप से बुकिंग भेजने पर यहाँ दिखाई देगी।', style: TextStyle(fontSize: 13, color: Colors.black54))
      else
        ...BookingStore.requests.map((request) => Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEAF3FC), child: Icon(Icons.work_outline, color: blue)),
            title: Text(request.service, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${request.customerName} • ${request.phone}\n${request.address}\n${request.id}', maxLines: 3, overflow: TextOverflow.ellipsis),
            isThreeLine: true,
            trailing: const Text('नया', style: TextStyle(fontWeight: FontWeight.w800, color: blue)),
          ),
        )),
      const SizedBox(height: 12),
      const Text('यह शुरुआती स्थानीय डेमो है। स्थायी सर्वर सेविंग, पार्टनर अलर्ट, KYC और payout अगले चरण में जोड़े जाएँगे।', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  );
}

class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('City Manager')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Singrauli Operations', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 5),
      const Text('City-level demo dashboard', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 16),
      const Row(children: [
        Expanded(child: MetricCard(label: 'बुकिंग', value: '24', icon: Icons.event_note)),
        SizedBox(width: 10),
        Expanded(child: MetricCard(label: 'पार्टनर', value: '18', icon: Icons.groups)),
      ]),
      const SizedBox(height: 10),
      const Row(children: [
        Expanded(child: MetricCard(label: 'पूरी हुई', value: '19', icon: Icons.check_circle)),
        SizedBox(width: 10),
        Expanded(child: MetricCard(label: 'शिकायतें', value: '2', icon: Icons.support_agent)),
      ]),
      const SizedBox(height: 20),
      const Text('Manager permissions (planned)', style: TextStyle(fontWeight: FontWeight.w800, color: navy)),
      const SizedBox(height: 8),
      const PermissionTile('अपने शहर के पार्टनर देखना', true),
      const PermissionTile('शहर की बुकिंग संभालना', true),
      const PermissionTile('शिकायतों पर कार्रवाई', true),
      const PermissionTile('कंपनी का global commission बदलना', false),
      const PermissionTile('दूसरे शहरों का वित्तीय डेटा देखना', false),
      const SizedBox(height: 12),
      const Text('अंतिम permissions central Admin द्वारा नियंत्रित होंगी। ये अभी केवल UI उदाहरण हैं.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  );
}

class MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const MetricCard({super.key, required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4EBF1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: blue),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]),
  );
}

class JobCard extends StatelessWidget {
  final String title, category, amount, status;
  const JobCard({super.key, required this.title, required this.category, required this.amount, required this.status});
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0,
    child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFEAF3FC), child: Icon(Icons.work_outline, color: blue)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$category • $status'),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
    ),
  );
}

class PermissionTile extends StatelessWidget {
  final String title;
  final bool allowed;
  const PermissionTile(this.title, this.allowed, {super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(allowed ? Icons.check_circle : Icons.lock, color: allowed ? Colors.green : Colors.redAccent),
    title: Text(title, style: const TextStyle(fontSize: 13)),
    trailing: Text(allowed ? 'अनुमति' : 'प्रतिबंधित', style: TextStyle(fontSize: 11, color: allowed ? Colors.green : Colors.redAccent)),
  );
}
