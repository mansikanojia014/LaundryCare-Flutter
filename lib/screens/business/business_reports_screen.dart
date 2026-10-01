import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class BusinessReportsScreen extends StatefulWidget {
  const BusinessReportsScreen({super.key});
  @override State<BusinessReportsScreen> createState()=>_BusinessReportsScreenState();
}
class _BusinessReportsScreenState extends State<BusinessReportsScreen>{
  final ApiService _api=ApiService();
  Map<String,dynamic> _report={};
  bool _loading=true;
  String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async{
    setState((){_loading=true;_error=null;});
    try{final r=await _api.get(ApiConfig.businessReports);if(mounted)setState(()=>_report=Map<String,dynamic>.from(r));}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    if(mounted)setState(()=>_loading=false);
  }
  String _label(String s)=>s.split('_').map((w)=>w.isEmpty?w:w[0].toUpperCase()+w.substring(1)).join(' ');
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Reports'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    body:_loading?const Center(child:CircularProgressIndicator()):_error!=null
      ?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:_load,child:const Text('Retry'))])))
      :ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Business Reports',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:16),
        ..._report.entries.where((e)=>e.value is num||e.value is String).map((e)=>Card(child:ListTile(title:Text(_label(e.key)),trailing:Text(e.value.toString(),style:const TextStyle(fontWeight:FontWeight.bold))))),
        if(_report.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('No report data available yet.'))),
      ]),
  );
}
