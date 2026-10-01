import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessDiscountsScreen extends StatefulWidget {
  const BusinessDiscountsScreen({super.key});
  @override State<BusinessDiscountsScreen> createState() => _BusinessDiscountsScreenState();
}
class _BusinessDiscountsScreenState extends State<BusinessDiscountsScreen> {
  final ApiService _api = ApiService();
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    setState((){_loading=true;_error=null;});
    try {
      final r=await _api.get(ApiConfig.businessDiscounts);
      final d=r['discounts'];
      if(mounted)setState(()=>_items=d is List?d.map((e)=>Map<String,dynamic>.from(e)).toList():[]);
    } catch(e) { if(mounted)setState(()=>_error=e.toString()); }
    if(mounted)setState(()=>_loading=false);
  }
  Future<void> _form([Map<String,dynamic>? item]) async {
    final code=TextEditingController(text:item?['code']?.toString()??'');
    final percent=TextEditingController(text:item?['percent']?.toString()??'');
    final until=TextEditingController(text:item?['valid_until']?.toString()??item?['validUntil']?.toString()??'');
    final key=GlobalKey<FormState>();
    final saved=await showDialog<bool>(
      context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(item==null?'Add Discount':'Edit Discount'),
        content:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
          TextFormField(controller:code,decoration:const InputDecoration(labelText:'Code',border:OutlineInputBorder()),validator:(v)=>v==null||v.trim().isEmpty?'Enter code':null),
          const SizedBox(height:12),
          TextFormField(controller:percent,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Percent',border:OutlineInputBorder()),validator:(v)=>double.tryParse(v??'')==null?'Enter percentage':null),
          const SizedBox(height:12),
          TextFormField(controller:until,decoration:const InputDecoration(labelText:'Valid until (YYYY-MM-DD)',border:OutlineInputBorder())),
        ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
          FilledButton(onPressed:() async {
            if(!key.currentState!.validate())return;
            try {
              final body=<String,dynamic>{'code':code.text.trim(),'percent':double.parse(percent.text.trim()),'active':true,if(until.text.trim().isNotEmpty)'validUntil':until.text.trim()};
              final id=item?['id']?.toString();
              if(id==null){await _api.post(ApiConfig.businessDiscounts,body:body);}else{await _api.patch('${ApiConfig.businessDiscounts}/$id',body:body);}
              if(ctx.mounted)Navigator.pop(ctx,true);
            } catch(e) { if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(e.toString()))); }
          },child:const Text('Save')),
        ],
      ),
    );
    code.dispose();percent.dispose();until.dispose();
    if(saved==true)_load();
  }
  Future<void> _toggle(Map<String,dynamic> d) async {
    final id=d['id']?.toString(); if(id==null)return;
    try {await _api.patch('${ApiConfig.businessDiscounts}/$id/status',body:{'active':d['active']!=true});_load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Discounts'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>_form(),icon:const Icon(Icons.add),label:const Text('Add Discount')),
    body:_loading?const Center(child:CircularProgressIndicator()):_error!=null
      ?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:_load,child:const Text('Retry'))])))
      :RefreshIndicator(onRefresh:_load,child:_items.isEmpty
        ?ListView(physics:const AlwaysScrollableScrollPhysics(),children:const[SizedBox(height:180),Icon(Icons.discount_outlined,size:56),SizedBox(height:16),Center(child:Text('No discounts added yet'))])
        :ListView.builder(padding:const EdgeInsets.fromLTRB(12,12,12,90),itemCount:_items.length,itemBuilder:(ctx,i){
          final d=_items[i];final active=d['active']!=false;
          final expiry=d['valid_until']?.toString()??d['validUntil']?.toString()??'No expiry';
          final percentText=(d['percent']??0).toString();
          return Card(child:ListTile(
            title:Text(d['code']?.toString()??'Discount',style:const TextStyle(fontWeight:FontWeight.bold)),
            subtitle:Text('$percentText% • $expiry\n${active ? 'Active' : 'Inactive'}'),
            trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')_form(d);if(v=='toggle')_toggle(d);},itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'toggle',child:Text(active?'Deactivate':'Activate'))]),
          ));
        }),
      ),
  );
}
