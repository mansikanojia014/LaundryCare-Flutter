import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessCustomersScreen extends StatefulWidget {
  const BusinessCustomersScreen({super.key});
  @override
  State<BusinessCustomersScreen> createState() => _BusinessCustomersScreenState();
}
class _BusinessCustomersScreenState extends State<BusinessCustomersScreen> {
  final ApiService _api = ApiService();
  List<Map<String,dynamic>> _customers = [];
  bool _loading = true;
  String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    setState((){_loading=true;_error=null;});
    try {
      final r=await _api.get(ApiConfig.businessCustomers);
      final data=r['customers'];
      if(!mounted)return;
      setState(()=>_customers=data is List?data.map((e)=>Map<String,dynamic>.from(e)).toList():[]);
    } catch(e){if(mounted)setState(()=>_error=e.toString());}
    if(mounted)setState(()=>_loading=false);
  }
  String _name(Map<String,dynamic> c)=>c['full_name']?.toString()??c['fullName']?.toString()??c['name']?.toString()??'Customer';
  String _email(Map<String,dynamic> c)=>c['email']?.toString()??'';
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Customers'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:_loading?const Center(child:CircularProgressIndicator()):_error!=null
      ?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:_load,child:const Text('Retry'))])))
      :RefreshIndicator(onRefresh:_load,child:_customers.isEmpty
        ?ListView(physics:const AlwaysScrollableScrollPhysics(),children:const[SizedBox(height:180),Icon(Icons.people_outline,size:56),SizedBox(height:16),Center(child:Text('No customers found'))])
        :ListView.builder(padding:const EdgeInsets.all(12),itemCount:_customers.length,itemBuilder:(context,i){
          final c=_customers[i]; final phone=c['phone']?.toString()??'';
          return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(_name(c),style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text([_email(c),phone].where((v)=>v.isNotEmpty).join('\n')),isThreeLine:phone.isNotEmpty));
        })),
  );
}