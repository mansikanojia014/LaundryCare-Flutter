import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override State<CustomerNotificationsScreen> createState()=>_CustomerNotificationsScreenState();
}
class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen>{
  final ApiService _api=ApiService(); List<Map<String,dynamic>> _items=[]; bool _loading=true; String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{setState((){_loading=true;_error=null;});try{final r=await _api.get(ApiConfig.notifications);final d=r['notifications'];if(mounted)setState(()=>_items=d is List?d.map((e)=>Map<String,dynamic>.from(e)).toList():[]);}catch(e){if(mounted)setState(()=>_error=e.toString());}if(mounted)setState(()=>_loading=false);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Notifications'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:_load,child:const Text('Retry'))]))):RefreshIndicator(onRefresh:_load,child:_items.isEmpty?ListView(physics:const AlwaysScrollableScrollPhysics(),children:const[SizedBox(height:180),Icon(Icons.notifications_none,size:56),SizedBox(height:16),Center(child:Text('No notifications'))]):ListView.builder(padding:const EdgeInsets.all(12),itemCount:_items.length,itemBuilder:(ctx,i){final n=_items[i];final title=n['title']?.toString()??n['message']?.toString()??'Notification';final body=n['message']?.toString()??n['body']?.toString()??'';final at=n['created_at']?.toString()??n['createdAt']?.toString()??'';return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.notifications_outlined)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text([body,at].where((v)=>v.isNotEmpty).join('\n'))));})));
}