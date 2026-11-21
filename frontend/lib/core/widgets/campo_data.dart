import 'package:flutter/material.dart';

import '../utils/formatadores.dart';

// Campo de data com seletor de calendário, para usar dentro de um Form.
class CampoData extends FormField<DateTime> {
  CampoData({
    super.key,
    required String rotulo,
    required ValueChanged<DateTime?> aoMudar,
    DateTime? valor,
    DateTime? primeira,
    DateTime? ultima,
    String mensagemObrigatorio = 'Informe a data.',
    bool enabled = true,
  }) : super(
         initialValue: valor,
         enabled: enabled,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         validator: (data) => data == null ? mensagemObrigatorio : null,
         builder: (state) {
           final inicio = primeira ?? DateTime(2000);
           final fim = ultima ?? DateTime(2100);

           Future<void> escolher() async {
             var inicial = state.value ?? DateTime.now();
             if (inicial.isAfter(fim)) inicial = fim;
             if (inicial.isBefore(inicio)) inicial = inicio;

             final escolhida = await showDatePicker(
               context: state.context,
               initialDate: inicial,
               firstDate: inicio,
               lastDate: fim,
               helpText: rotulo,
             );

             if (escolhida != null) {
               state.didChange(escolhida);
               aoMudar(escolhida);
             }
           }

           return Semantics(
             button: true,
             label: rotulo,
             child: InkWell(
               borderRadius: BorderRadius.circular(12),
               onTap: enabled ? escolher : null,
               child: InputDecorator(
                 decoration: InputDecoration(
                   labelText: rotulo,
                   errorText: state.errorText,
                   suffixIcon: const Icon(Icons.calendar_today_outlined),
                 ),
                 child: Text(
                   state.value == null
                       ? 'Selecionar data'
                       : Formatadores.data(state.value!),
                 ),
               ),
             ),
           );
         },
       );
}
