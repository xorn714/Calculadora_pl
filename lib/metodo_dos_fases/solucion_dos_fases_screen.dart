import 'package:flutter/material.dart';
import 'dos_fases_solver.dart';

class SolucionDosFasesScreen extends StatelessWidget {
  final TwoPhaseResult result;

  const SolucionDosFasesScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solución Método Dos Fases')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Valor óptimo: ${result.optimalValue}'),
              const SizedBox(height: 8),
              Text(
                  'Solución: ${result.solution.map((x) => x.toStringAsFixed(2)).join(', ')}'),
              const SizedBox(height: 16),
              const Text('Pasos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.steps.map((s) => Text(s)),
            ],
          ),
        ),
      ),
    );
  }
}
