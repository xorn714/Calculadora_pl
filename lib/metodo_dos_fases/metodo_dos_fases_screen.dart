import 'package:flutter/material.dart';
import 'dos_fases_solver.dart';
import 'solucion_dos_fases_screen.dart';

class TwoPhaseScreen extends StatefulWidget {
  const TwoPhaseScreen({super.key});

  @override
  State<TwoPhaseScreen> createState() => _TwoPhaseScreenState();
}

class _TwoPhaseScreenState extends State<TwoPhaseScreen> {
  final TextEditingController _numVariablesController =
      TextEditingController(text: '2');
  final TextEditingController _numRestrictionsController =
      TextEditingController(text: '2');

  String _objectiveType = 'Maximizar';
  List<TextEditingController> _objectiveFunctionControllers = [];
  List<List<TextEditingController>> _constraintControllers = [];
  List<TextEditingController> _rhsControllers = [];
  List<String> _constraintOperators = [];

  @override
  void initState() {
    super.initState();
    _updateMatrixSize();
    _numVariablesController.addListener(_updateMatrixSize);
    _numRestrictionsController.addListener(_updateMatrixSize);
  }

  @override
  void dispose() {
    _numVariablesController.dispose();
    _numRestrictionsController.dispose();
    _disposeDynamicControllers();
    super.dispose();
  }

  void _disposeDynamicControllers() {
    for (var c in _objectiveFunctionControllers) {
      c.dispose();
    }
    for (var row in _constraintControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    for (var c in _rhsControllers) {
      c.dispose();
    }
    _objectiveFunctionControllers.clear();
    _constraintControllers.clear();
    _rhsControllers.clear();
    _constraintOperators.clear();
  }

  void _updateMatrixSize() {
    setState(() {
      _disposeDynamicControllers();

      final numVariables = int.tryParse(_numVariablesController.text) ?? 2;
      final numRestrictions =
          int.tryParse(_numRestrictionsController.text) ?? 2;

      _objectiveFunctionControllers = List.generate(
        numVariables,
        (index) => TextEditingController(),
      );

      _constraintControllers = List.generate(
        numRestrictions,
        (_) => List.generate(
          numVariables,
          (_) => TextEditingController(),
        ),
      );

      _rhsControllers = List.generate(
        numRestrictions,
        (_) => TextEditingController(),
      );

      _constraintOperators = List.generate(
        numRestrictions,
        (_) => '≤',
      );
    });
  }

  void _generateSolution() {
    // Validar campos
    for (var c in _objectiveFunctionControllers) {
      if (c.text.isEmpty) {
        _showSnackBar("Ingrese todos los coeficientes de la función objetivo");
        return;
      }
    }

    for (int i = 0; i < _constraintControllers.length; i++) {
      for (int j = 0; j < _constraintControllers[i].length; j++) {
        if (_constraintControllers[i][j].text.isEmpty) {
          _showSnackBar("Ingrese todos los coeficientes de las restricciones");
          return;
        }
      }
      if (_rhsControllers[i].text.isEmpty) {
        _showSnackBar("Ingrese todos los términos independientes");
        return;
      }
    }

    // Convertir a valores numéricos
    List<double> objectiveCoefficients = _objectiveFunctionControllers
        .map((c) => double.tryParse(c.text) ?? 0)
        .toList();

    List<List<double>> constraints = _constraintControllers
        .map((row) => row.map((c) => double.tryParse(c.text) ?? 0).toList())
        .toList();

    List<double> rhs =
        _rhsControllers.map((c) => double.tryParse(c.text) ?? 0).toList();

    final result = TwoPhaseMethod.solve(
      objectiveCoefficients: objectiveCoefficients,
      constraints: constraints,
      rhs: rhs,
      constraintOperators: _constraintOperators,
      objectiveType: _objectiveType,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolucionDosFasesScreen(result: result),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Método Dos Fases"),
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
                    // Configuración inicial
                    const Text(
                      'Configuración del problema:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Número de variables:',
                                style: TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _numVariablesController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Número de restricciones:',
                                style: TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _numRestrictionsController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Función objetivo
                    const Text(
                      'Función objetivo:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButton<String>(
                            value: _objectiveType,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                            dropdownColor: Colors.white,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'Maximizar',
                                child: Text('Maximizar',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ),
                              DropdownMenuItem(
                                value: 'Minimizar',
                                child: Text('Minimizar',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.black)),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _objectiveType = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Z =',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4.0, // Espacio horizontal reducido
                            runSpacing: 8.0, // Espacio vertical reducido
                            children: List.generate(
                                _objectiveFunctionControllers.length, (index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        4.0), // Padding horizontal reducido
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (index > 0)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: Text(
                                          "+",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller:
                                            _objectiveFunctionControllers[
                                                index],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 4.0), // Espacio reducido
                                    Text(
                                      "X${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Restricciones
                    const Text(
                      'Restricciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children:
                          List.generate(_constraintControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 4.0, // Espacio horizontal reducido
                                  runSpacing: 8.0, // Espacio vertical reducido
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Variables
                                    ...List.generate(
                                        _constraintControllers[i].length, (j) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                4.0), // Padding horizontal reducido
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (j > 0)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 2.0),
                                                child: Text(
                                                  "+",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            SizedBox(
                                              width: 80,
                                              child: TextField(
                                                controller:
                                                    _constraintControllers[i]
                                                        [j],
                                                keyboardType:
                                                    TextInputType.number,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: 4.0), // Espacio reducido
                                            Text(
                                              "X${j + 1}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    // Operador de desigualdad
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal:
                                              4.0), // Margen horizontal reducido
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: DropdownButton<String>(
                                        value: _constraintOperators[i],
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.black),
                                        dropdownColor: Colors.white,
                                        underline: const SizedBox(),
                                        items: const [
                                          DropdownMenuItem(
                                            value: '≤',
                                            child: Text('≤',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black)),
                                          ),
                                          DropdownMenuItem(
                                            value: '≥',
                                            child: Text('≥',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black)),
                                          ),
                                          DropdownMenuItem(
                                            value: '=',
                                            child: Text('=',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black)),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _constraintOperators[i] = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 4.0), // Espacio reducido
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _rhsControllers[i],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            color: Colors.black),
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
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
                        onPressed: _generateSolution,
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
}
