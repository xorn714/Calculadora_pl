import 'package:flutter/material.dart';
import 'solucion_metodo_grafico_screen.dart';
import 'metodo_grafico_solver.dart';

class GraphicMethodScreen extends StatefulWidget {
  const GraphicMethodScreen({super.key});

  @override
  _GraphicMethodScreenState createState() => _GraphicMethodScreenState();
}

class _GraphicMethodScreenState extends State<GraphicMethodScreen> {
  bool isMaximize = true;
  TextEditingController x1Controller = TextEditingController();
  TextEditingController x2Controller = TextEditingController();
  TextEditingController restrictionsCountController =
      TextEditingController(text: '1');
  List<Map<String, dynamic>> restrictions = [];

  @override
  void initState() {
    super.initState();
    _initializeRestrictions();
    restrictionsCountController.addListener(_updateRestrictionsCount);
  }

  void _initializeRestrictions() {
    final count = int.tryParse(restrictionsCountController.text) ?? 1;
    restrictions = List.generate(
        count,
        (index) => {
              'x1Controller': TextEditingController(),
              'x2Controller': TextEditingController(),
              'inequality': '≤',
              'valueController': TextEditingController(),
            });
  }

  void _updateRestrictionsCount() {
    final newCount = int.tryParse(restrictionsCountController.text) ?? 1;
    if (newCount != restrictions.length) {
      setState(() {
        if (newCount > restrictions.length) {
          // Añadir nuevas restricciones
          for (int i = restrictions.length; i < newCount; i++) {
            restrictions.add({
              'x1Controller': TextEditingController(),
              'x2Controller': TextEditingController(),
              'inequality': '≤',
              'valueController': TextEditingController(),
            });
          }
        } else {
          // Eliminar restricciones sobrantes
          for (int i = restrictions.length - 1; i >= newCount; i--) {
            restrictions[i]['x1Controller'].dispose();
            restrictions[i]['x2Controller'].dispose();
            restrictions[i]['valueController'].dispose();
          }
          restrictions = restrictions.sublist(0, newCount);
        }
      });
    }
  }

  Widget _buildRestrictionInputs() {
    return Column(
      children: restrictions.map((restriction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              // Campo para coeficiente X1
              SizedBox(
                width: 60,
                child: TextField(
                  controller: restriction['x1Controller'],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'X1 +',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(width: 8),
              // Campo para coeficiente X2
              SizedBox(
                width: 60,
                child: TextField(
                  controller: restriction['x2Controller'],
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'X2',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(width: 16),
              // Dropdown para ≤, ≥ o =
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButton<String>(
                  value: restriction['inequality'],
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  dropdownColor: Colors.white,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '≤', child: Text('≤')),
                    DropdownMenuItem(value: '≥', child: Text('≥')),
                    DropdownMenuItem(value: '=', child: Text('=')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      restriction['inequality'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Campo para el término independiente
              SizedBox(
                width: 80,
                child: TextField(
                  controller: restriction['valueController'],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _calculateSolution() {
    // Validar que todos los campos estén completos
    if (x1Controller.text.isEmpty || x2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor ingrese todos los coeficientes de la función objetivo')),
      );
      return;
    }

    for (var restriction in restrictions) {
      if (restriction['x1Controller'].text.isEmpty ||
          restriction['x2Controller'].text.isEmpty ||
          restriction['valueController'].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Por favor complete todos los campos de las restricciones')),
        );
        return;
      }
    }

    // Preparar los datos para pasar a la pantalla de resultados
    final problemData = {
      'isMaximize': isMaximize,
      'objectiveFunction': {
        'x1': double.tryParse(x1Controller.text) ?? 0,
        'x2': double.tryParse(x2Controller.text) ?? 0,
      },
      'restrictions': restrictions
          .map((r) => {
                'x1': double.tryParse(r['x1Controller'].text) ?? 0,
                'x2': double.tryParse(r['x2Controller'].text) ?? 0,
                'inequality': r['inequality'],
                'value': double.tryParse(r['valueController'].text) ?? 0,
              })
          .toList(),
    };

    resolverMetodoGrafico(problemData); // <--- Llama aquí al solver

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolutionScreen(problemData: problemData),
      ),
    );
  }

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Función objetivo
                    const Text(
                      'Función objetivo:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButton<bool>(
                            value: isMaximize,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            dropdownColor: Colors.white,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                  value: true, child: Text('Maximizar')),
                              DropdownMenuItem(
                                  value: false, child: Text('Minimizar')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                isMaximize = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Z =',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: x1Controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'X1 +',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: x2Controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'X2',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Número de restricciones
                    const Text(
                      'Número de restricciones:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: restrictionsCountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restricciones (S.A.)
                    const Text(
                      'S.A.',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    _buildRestrictionInputs(),
                    const Text(
                      'X1, X2 ≥ 0',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Botón de calcular
                    Center(
                      child: ElevatedButton(
                        onPressed: _calculateSolution,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'CALCULAR',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    x1Controller.dispose();
    x2Controller.dispose();
    restrictionsCountController.dispose();
    for (var restriction in restrictions) {
      restriction['x1Controller'].dispose();
      restriction['x2Controller'].dispose();
      restriction['valueController'].dispose();
    }
    super.dispose();
  }
}
