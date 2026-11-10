import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://qnddlauyiftfulxjknss.supabase.co';
const supabaseAnonKey = 'sb_publishable_TT4QdJKlaT3rXXfiI3wCJg_U9E931Td';
const navy = Color(0xFF102C45);
const blue = Color(0xFF1677C8);
const teal = Color(0xFF12A6A0);
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SevanexApp());
}

class SevanexApp extends StatelessWidget {
  const SevanexApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SEVANEX', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: blue), scaffoldBackgroundColor: const Color(0xFFF5F8FB), appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white)),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) => supabase.auth.currentSession == null ? const AuthPage() : const RoleHome(),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool signup = false, busy = false;
  String? message;
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!email.text.contains('@') || password.text.length < 6) { setState(() => message = 'सही Email और कम से कम 6 अक्षर का Password लिखें।'); return; }
    setState(() { busy = true; message = null; });
    try {
      if (signup) {
        final result = await supabase.auth.signUp(email: email.text.trim(), password: password.text);
        if (result.session == null && mounted) setState(() => message = 'अकाउंट बन गया। Email confirmation की जरूरत हो तो उसे पूरा करके Login करें।');
      } else {
        await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) { if (mounted) setState(() => message = e.message); }
      catch (e) { if (mounted) setState(() => message = 'समस्या: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('SEVANEX Login')), body: ListView(padding: const EdgeInsets.all(22), children: [
    const SizedBox(height: 28), const Text('SEVANEX', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)), const Text('हर सेवा, एक ही प्लेटफॉर्म पर।'), const SizedBox(height: 24),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())), const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())), const SizedBox(height: 12),
    if (message != null) Text(message!, style: const TextStyle(color: Colors.red)),
    FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'कृपया प्रतीक्षा करें…' : signup ? 'अकाउंट बनाएँ' : 'Login करें')),
    TextButton(onPressed: busy ? null : () => setState(() { signup = !signup; message = null; }), child: Text(signup ? 'पहले से अकाउंट है? Login' : 'नया अकाउंट बनाएँ')),
  ]));
}

class CustomerProfile {
  final String name, phone, address; final int? cityId;
  const CustomerProfile({required this.name, required this.phone, required this.address, this.cityId});
  bool get complete => name.trim().isNotEmpty && RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone.trim()) && address.trim().isNotEmpty;
  static Future<CustomerProfile?> load() async {
    final user = supabase.auth.currentUser; if (user == null) return null;
    final row = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final p = CustomerProfile(name: (row['full_name'] ?? '').toString(), phone: (row['phone'] ?? '').toString(), address: prefs.getString('profile_address') ?? '', cityId: row['city_id'] as int?);
    return p.complete ? p : null;
  }
  static Future<void> save(String name, String phone, String address) async {
    final user = supabase.auth.currentUser; if (user == null) throw Exception('पहले Login करें।');
    final old = await supabase.from('profiles').select('city_id,role').eq('id', user.id).maybeSingle();
    await supabase.from('profiles').upsert({'id': user.id, 'full_name': name.trim(), 'phone': phone.trim(), 'city_id': old?['city_id'] ?? 1, 'role': old?['role'] ?? 'customer'});
    final prefs = await SharedPreferences.getInstance(); await prefs.setString('profile_address', address.trim());
  }
}

class RoleHome extends StatefulWidget { const RoleHome({super.key}); @override State<RoleHome> createState() => _RoleHomeState(); }
class _RoleHomeState extends State<RoleHome> {
  CustomerProfile? profile; String role = 'customer'; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final u = supabase.auth.currentUser!; final row = await supabase.from('profiles').select('role').eq('id', u.id).maybeSingle(); role = (row?['role'] ?? 'customer').toString().toLowerCase(); profile = await CustomerProfile.load(); }
    catch (_) {} if (mounted) setState(() => loading = false);
  }
  Future<void> editProfile() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(existing: profile))); await load(); }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: const Text('SEVANEX', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: editProfile, icon: const Icon(Icons.account_circle_outlined)), IconButton(onPressed: () => supabase.auth.signOut(), icon: const Icon(Icons.logout))]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, blue]), borderRadius: BorderRadius.circular(22)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('हर सेवा, एक ही प्लेटफॉर्म पर।', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Singrauli, Madhya Pradesh', style: TextStyle(color: Colors.white70))])),
        const SizedBox(height: 14), Card(color: Colors.white, child: ListTile(title: Text(profile?.name ?? 'Customer Profile सेट करें'), subtitle: Text(profile?.phone ?? 'नाम, मोबाइल और पता सेव करें'), trailing: const Icon(Icons.edit), onTap: editProfile)),
        RoleCard(icon: Icons.home_repair_service, title: 'मुझे सर्विस चाहिए', subtitle: 'स्थानीय सर्विस बुक करें', color: blue, onTap: () async { if (profile == null) { await editProfile(); if (profile == null) return; } if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPage())); }),
        RoleCard(icon: Icons.handyman, title: 'मैं सर्विस पार्टनर हूँ', subtitle: 'Partner Registration, KYC और अपने काम देखें', color: teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderPage()))),
        if (role == 'admin' || role == 'manager' || role == 'city_manager') RoleCard(icon: Icons.admin_panel_settings, title: 'Admin Dashboard', subtitle: 'बुकिंग, Partner Approval और Assignment', color: navy, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()))),
      ]));
  }
}

class ProfilePage extends StatefulWidget { final CustomerProfile? existing; const ProfilePage({super.key, this.existing}); @override State<ProfilePage> createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final keyForm = GlobalKey<FormState>(); late final name = TextEditingController(text: widget.existing?.name ?? ''); late final phone = TextEditingController(text: widget.existing?.phone ?? ''); late final address = TextEditingController(text: widget.existing?.address ?? ''); bool saving = false;
  @override void dispose() { name.dispose(); phone.dispose(); address.dispose(); super.dispose(); }
  Future<void> save() async { if (!(keyForm.currentState?.validate() ?? false)) return; setState(() => saving = true); try { await CustomerProfile.save(name.text, phone.text, address.text); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('प्रोफाइल सेव हो गई।'))); Navigator.pop(context); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('सेव नहीं हुआ: $e'))); } finally { if (mounted) setState(() => saving = false); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('मेरी प्रोफाइल')), body: Form(key: keyForm, child: ListView(padding: const EdgeInsets.all(18), children: [
    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'पूरा नाम', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'नाम लिखें' : null), const SizedBox(height: 12),
    TextFormField(controller: phone, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'मोबाइल नंबर', counterText: '', border: OutlineInputBorder()), validator: (v) => v == null || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(v.trim()) ? 'सही 10 अंकों का नंबर लिखें' : null), const SizedBox(height: 12),
    TextFormField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'पूरा पता', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'पता लिखें' : null), const SizedBox(height: 16),
    FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'सेव हो रहा है…' : 'प्रोफाइल सेव करें')),
  ])));
}

class RoleCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color; final VoidCallback onTap;
  const RoleCard({super.key, required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE4EBF1))), child: ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});
  static const categories = [('इलेक्ट्रिशियन','वायरिंग, पंखा, लाइट',1,Icons.electrical_services),('प्लंबर','नल, पाइप, लीकेज',2,Icons.plumbing),('AC एवं उपकरण','AC, फ्रिज, वॉशिंग मशीन',3,Icons.ac_unit),('हाउस क्लीनिंग','घर और बाथरूम सफाई',4,Icons.cleaning_services),('कारपेंटर','फर्नीचर और फिटिंग',5,Icons.chair),('पेंटिंग','घर और ऑफिस पेंटिंग',6,Icons.format_paint),('वाहन सेवाएँ','कार वॉश और ड्राइवर',7,Icons.directions_car),('कंप्यूटर एवं IT','कंप्यूटर रिपेयर और सपोर्ट',8,Icons.computer)];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('सर्विस बुक करें')), body: GridView.builder(padding: const EdgeInsets.all(16), itemCount: categories.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2), itemBuilder: (context,i) { final c=categories[i]; return Card(color: Colors.white, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingPage(service:c.$1,categoryId:c.$3))), child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(c.$4,color:blue,size:30), const SizedBox(height:8), Text(c.$1,style:const TextStyle(fontWeight:FontWeight.bold,color:navy)), Text(c.$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:11))])))); }));
}

class BookingPage extends StatefulWidget { final String service; final int categoryId; const BookingPage({super.key,required this.service,required this.categoryId}); @override State<BookingPage> createState()=>_BookingPageState(); }
class _BookingPageState extends State<BookingPage> {
  final details=TextEditingController(); CustomerProfile? profile; bool loading=true,saving=false; int? bookingId;
  @override void initState(){super.initState();load();}
  Future<void> load() async { try { profile=await CustomerProfile.load(); } catch (_) {} if(mounted)setState(()=>loading=false); }
  @override void dispose(){details.dispose();super.dispose();}
  Future<void> submit() async { if(profile==null||saving||bookingId!=null)return; setState(()=>saving=true); try { final row=await supabase.from('bookings').insert({'customer_id':supabase.auth.currentUser!.id,'city_id':profile!.cityId??1,'category_id':widget.categoryId,'description':'${widget.service}: ${details.text.trim()}','address':profile!.address,'status':'requested'}).select('id').single(); if(mounted)setState(()=>bookingId=row['id'] as int); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('बुकिंग सेव नहीं हुई: $e')));} finally{if(mounted)setState(()=>saving=false);} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('बुकिंग अनुरोध')),body:loading?const Center(child:CircularProgressIndicator()):profile==null?const Center(child:Text('पहले Customer Profile पूरी करें।')):ListView(padding:const EdgeInsets.all(18),children:[Text(widget.service,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:navy)),Card(color:Colors.white,child:ListTile(title:Text(profile!.name),subtitle:Text('${profile!.phone}\n${profile!.address}',))),const SizedBox(height:12),TextField(controller:details,maxLines:3,decoration:const InputDecoration(labelText:'काम की जानकारी',border:OutlineInputBorder())),const SizedBox(height:16),FilledButton(onPressed:saving||bookingId!=null?null:submit,child:Text(saving?'भेज रहे हैं…':'ऑनलाइन बुकिंग भेजें')),if(bookingId!=null)Padding(padding:const EdgeInsets.only(top:16),child:Text('बुकिंग सफल! Booking ID: $bookingId',style:const TextStyle(color:Colors.green,fontWeight:FontWeight.bold)))]));
}

class ProviderPage extends StatefulWidget { const ProviderPage({super.key}); @override State<ProviderPage> createState()=>_ProviderPageState(); }
class _ProviderPageState extends State<ProviderPage> {
  final business=TextEditingController(),bio=TextEditingController(),kyc=TextEditingController(); bool loading=true,saving=false; Map<String,dynamic>? provider; List<Map<String,dynamic>> jobs=[]; String? error;
  @override void initState(){super.initState();load();}
  @override void dispose(){business.dispose();bio.dispose();kyc.dispose();super.dispose();}
  Future<void> load() async { setState(()=>loading=true); try { final uid=supabase.auth.currentUser!.id; provider=await supabase.from('provider_profiles').select().eq('id',uid).maybeSingle(); if(provider!=null){business.text=(provider!['business_name']??'').toString();bio.text=(provider!['description']??'').toString(); if(provider!['kyc_status']=='approved'){jobs=List<Map<String,dynamic>>.from(await supabase.from('bookings').select().eq('provider_id',uid).order('created_at',ascending:false));}} error=null; } catch(e){error='$e';} if(mounted)setState(()=>loading=false); }
  Future<void> register() async { if(business.text.trim().isEmpty||bio.text.trim().isEmpty){setState(()=>error='Business name और काम का विवरण भरें।');return;} setState(()=>saving=true); try { final uid=supabase.auth.currentUser!.id; await supabase.from('provider_profiles').insert({'id':uid,'business_name':business.text.trim(),'description':'${bio.text.trim()} | KYC reference: ${kyc.text.trim()}','kyc_status':'pending','is_available':false}); await load(); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Partner आवेदन भेज दिया गया। Admin approval का इंतजार करें।'))); } catch(e){setState(()=>error='आवेदन सेव नहीं हुआ: $e');} finally{if(mounted)setState(()=>saving=false);} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Partner Dashboard')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(18),children:[
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
    if(provider==null)...[
      const Text('Service Partner Registration',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:navy)),const Text('अपना व्यवसाय और अनुभव भरकर approval के लिए भेजें।'),const SizedBox(height:14),
      TextField(controller:business,decoration:const InputDecoration(labelText:'Business / Partner Name',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:bio,maxLines:3,decoration:const InputDecoration(labelText:'कौन-कौन सी सर्विस देते हैं?',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:kyc,decoration:const InputDecoration(labelText:'KYC reference (दस्तावेज़ अभी अलग से verify होंगे)',border:OutlineInputBorder())),const SizedBox(height:16),FilledButton(onPressed:saving?null:register,child:Text(saving?'भेज रहे हैं…':'Partner आवेदन भेजें')),
    ] else ...[
      Text(provider!['business_name']?.toString()??'Partner',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:navy)),const SizedBox(height:8),Text('KYC / Approval स्थिति: ${provider!['kyc_status']}'),
      if(provider!['kyc_status']!='approved')const Padding(padding:EdgeInsets.only(top:12),child:Text('Admin की मंजूरी मिलने के बाद आपको assigned bookings दिखाई देंगी।'))
      else ...[const SizedBox(height:18),const Text('आपको मिली बुकिंग',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:navy)),if(jobs.isEmpty)const Text('अभी कोई Booking assign नहीं हुई है।'),...jobs.map((b)=>Card(color:Colors.white,child:ListTile(title:Text('Booking #${b['id']}'),subtitle:Text('${b['description']}\n${b['address']}\nस्थिति: ${b['status']}'))))]
    ]
  ])));
}

class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState()=>_AdminPageState(); }
class _AdminPageState extends State<AdminPage> {
  bool loading=true; String? error; List<Map<String,dynamic>> bookings=[],partners=[]; final Map<int,String?> assignments={};
  @override void initState(){super.initState();load();}
  Future<void> load() async { setState(()=>loading=true); try { bookings=List<Map<String,dynamic>>.from(await supabase.from('bookings').select().order('created_at',ascending:false)); partners=List<Map<String,dynamic>>.from(await supabase.from('provider_profiles').select().order('created_at',ascending:false)); error=null; } catch(e){error='Admin data लोड नहीं हुआ: $e';} if(mounted)setState(()=>loading=false); }
  Future<void> approve(String uid) async { try { await supabase.from('provider_profiles').update({'kyc_status':'approved'}).eq('id',uid); await load(); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Approval नहीं हुआ: $e')));} }
  Future<void> assign(int bookingId,String uid) async { try { await supabase.from('bookings').update({'provider_id':uid,'status':'accepted'}).eq('id',bookingId); await load(); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Partner assign हो गया।'))); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Assign नहीं हुआ: $e')));} }
  Future<void> status(int id,String value) async { try { await supabase.from('bookings').update({'status':value}).eq('id',id); await load(); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Status नहीं बदला: $e')));} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('SEVANEX Admin')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),Text('Partner Applications (${partners.length})',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:navy)),
    if(partners.isEmpty)const Text('अभी कोई Partner आवेदन नहीं है।'),...partners.map((p){final approved=p['kyc_status']=='approved';return Card(color:Colors.white,child:ListTile(isThreeLine:true,title:Text(p['business_name']?.toString()??'Partner'),subtitle:Text('${p['description']}\nस्थिति: ${p['kyc_status']}'),trailing:approved?const Icon(Icons.verified,color:Colors.green):TextButton(onPressed:()=>approve(p['id'].toString()),child:const Text('Approve'))));}),
    const SizedBox(height:18),Text('Bookings (${bookings.length})',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:navy)),
    if(bookings.isEmpty)const Text('अभी कोई Booking नहीं है।'),...bookings.map((b){final id=b['id'] as int;final eligible=partners.where((p)=>p['kyc_status']=='approved').toList();return Card(color:Colors.white,margin:const EdgeInsets.only(top:9),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Booking #$id',style:const TextStyle(fontWeight:FontWeight.bold,color:navy)),Text('Customer: ${b['customer_id']}'),Text('Service: ${b['category_id']} • City: ${b['city_id']}'),Text('पता: ${b['address']}'),Text('काम: ${b['description']}'),Text('स्थिति: ${b['status']}'),if(eligible.isNotEmpty)DropdownButtonFormField<String>(value:assignments[id]??b['provider_id']?.toString(),decoration:const InputDecoration(labelText:'Approved Partner assign करें'),items:eligible.map((p)=>DropdownMenuItem(value:p['id'].toString(),child:Text(p['business_name'].toString()))).toList(),onChanged:(v)=>setState(()=>assignments[id]=v)),if(eligible.isNotEmpty)Align(alignment:Alignment.centerRight,child:TextButton(onPressed:assignments[id]==null?null:()=>assign(id,assignments[id]!),child:const Text('Assign Partner'))),Wrap(spacing:6,children:[TextButton(onPressed:()=>status(id,'in_progress'),child:const Text('In Progress')),TextButton(onPressed:()=>status(id,'completed'),child:const Text('Complete')),TextButton(onPressed:()=>status(id,'cancelled'),child:const Text('Cancel'))])])));})
  ])));
}
