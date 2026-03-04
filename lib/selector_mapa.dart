import 'package:flutter/material.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';

class SelectorMapa extends StatelessWidget {
  const SelectorMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Ubicación"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD4AF37),
      ),
      body: OpenStreetMapSearchAndPick(
        // Dejamos solo los colores, el texto del botón y la acción
        buttonColor: const Color(0xFFD4AF37),
        buttonText: 'CONFIRMAR UBICACIÓN',
        onPicked: (pickedData) {
          print("📍 ¡El botón reaccionó!");
          print(
            "📍 Coordenadas atrapadas: ${pickedData.latLong.latitude}, ${pickedData.latLong.longitude}",
          );
          Navigator.pop(context, pickedData);
        },
      ),
    );
  }
}
