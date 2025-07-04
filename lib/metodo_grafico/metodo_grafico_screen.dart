import 'package:flutter/material.dart';

class GraphicMethodScreen extends StatelessWidget {
  const GraphicMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método Gráfico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Aquí irá la interfaz del Método Gráfico',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}