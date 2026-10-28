import 'package:flutter/material.dart';
class RegisterPersonalInfoPage extends StatelessWidget {
 const RegisterPersonalInfoPage({super.key,required this.name,required this.phone,
 required this.username,required this.birthDate,required this.onPickBirthDate});
 final TextEditingController name, phone, username;
 final DateTime? birthDate;
 final VoidCallback onPickBirthDate;
 static bool isAdult(DateTime birth, DateTime today) {
   final limit = DateTime(today.year - 18,today.month,today.day);
   return !birth.isAfter(limit);
 }
 @override Widget build(BuildContext context) => ListView(children: [
   Text('Háblanos más de ti',style: Theme.of(context).textTheme.headlineSmall),
   const SizedBox(height: 15),
   TextFormField(controller: name,decoration: const InputDecoration(labelText: 'Nombre completo'),
     validator:(v)=>(v??'').trim().length<3?'Ingresa tu nombre completo':null),
   const SizedBox(height: 14),
   TextFormField(controller: phone,keyboardType: TextInputType.phone,
     decoration: const InputDecoration(labelText: 'Teléfono'),
     validator:(v){ final digits=(v??'').replaceAll(RegExp(r'\D'),'');
       return digits.length<7||digits.length>15?'Ingresa un teléfono válido':null; }),
   const SizedBox(height: 14),
   TextFormField(controller: username,autocorrect:false,
     decoration: const InputDecoration(labelText:'Nombre de usuario',helperText:'3 a 20 caracteres: minúsculas, números y _'),
     validator:(v)=>!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch((v??'').trim())?'Nombre de usuario inválido':null),
   const SizedBox(height: 14),
   ListTile(contentPadding: EdgeInsets.zero,title: const Text('Fecha de nacimiento'),
     subtitle:Text(birthDate == null?'Selecciona tu fecha (18 años o más)':'${birthDate!.day.toString().padLeft(2,'0')}/${birthDate!.month.toString().padLeft(2,'0')}/${birthDate!.year}'),
     trailing: const Icon(Icons.calendar_today_outlined),onTap:onPickBirthDate),
 ]);
}
