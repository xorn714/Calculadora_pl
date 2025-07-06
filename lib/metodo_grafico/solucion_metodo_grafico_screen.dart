import 'package:flutter/material.dart';


class SolutionScreen extends StatelessWidget {
  final Map<String, dynamic> problemData;

  const SolutionScreen({super.key, required this.problemData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solución'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solución del problema:',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Función objetivo: ${problemData['isMaximize'] ? 'Maximizar' : 'Minimizar'} Z = ${problemData['objectiveFunction']['x1']}X1 + ${problemData['objectiveFunction']['x2']}X2',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restricciones:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  ...problemData['restrictions']
                      .map<Widget>((r) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${r['x1']}X1 + ${r['x2']}X2 ${r['inequality']} ${r['value']}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ))
                      .toList(),
                  const SizedBox(height: 16),
                  const Text(
                    'X1, X2 ≥ 0',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 32),
                  // Aquí iría la solución gráfica y numérica
                  if (problemData['solution'] == null ||
                      problemData['solution']['message'] != null)
                    Center(
                      child: Text(
                        problemData['solution']?['message'] ??
                            'Error desconocido.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punto óptimo:',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: Colors.black),
                        ),
                        Text(
                            'X1 = ${problemData['solution']['optimalPoint']['x1'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black)),
                        Text(
                            'X2 = ${problemData['solution']['optimalPoint']['x2'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black)),
                        const SizedBox(height: 8),
                        Text(
                          'Valor óptimo de Z: ${problemData['solution']['optimalValue'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Evaluaciones en puntos factibles:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        ...List<Widget>.from(
                          (problemData['solution']['evaluations'] as List)
                              .map((ev) => Text(
                                    'X1=${ev['x1'].toStringAsFixed(2)}, '
                                    'X2=${ev['x2'].toStringAsFixed(2)} → '
                                    'Z=${ev['z'].toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.black),
                                  )),
                        )
                      ],
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}