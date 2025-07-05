import 'package:flutter/material.dart';

class TwoPhaseScreen extends StatefulWidget {
  const TwoPhaseScreen({super.key});

  @override
  State<TwoPhaseScreen> createState() => _TwoPhaseScreenState();
}

class _TwoPhaseScreenState extends State<TwoPhaseScreen> {
  final TextEditingController _numVariablesController = TextEditingController();
  final TextEditingController _numRestrictionsController =
      TextEditingController();

  int _numVariables = 0;
  int _numRestrictions = 0;

  String _objectiveType = 'Maximizar'; // Nuevo

  List<TextEditingController> _objectiveFunctionControllers = [];
  List<List<TextEditingController>> _constraintControllers = [];
  List<TextEditingController> _rhsControllers = [];
  List<String> _constraintOperators = []; // Nuevo

  @override
  void initState() {
    super.initState();
    _numVariablesController.text = '2';
    _numRestrictionsController.text = '2';
    _updateMatrixSize();
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
    _constraintOperators.clear(); // Nuevo
  }

  void _updateMatrixSize() {
    setState(() {
      _disposeDynamicControllers();

      _numVariables = int.tryParse(_numVariablesController.text) ?? 0;
      _numRestrictions = int.tryParse(_numRestrictionsController.text) ?? 0;

      _objectiveFunctionControllers = List.generate(
        _numVariables,
        (index) => TextEditingController(),
      );

      _constraintControllers = List.generate(
        _numRestrictions,
        (_) => List.generate(
          _numVariables,
          (_) => TextEditingController(),
        ),
      );

      _rhsControllers = List.generate(
        _numRestrictions,
        (_) => TextEditingController(),
      );

      _constraintOperators = List.generate(
        _numRestrictions,
        (_) => '≤',
      );
    });
  }

  void _generateSolution() {
    List<double> objectiveCoefficients = [];
    List<List<double>> constraints = [];
    List<double> rhs = [];

    for (var c in _objectiveFunctionControllers) {
      final value = double.tryParse(c.text);
      if (value == null) {
        _showSnackBar(
            "Ingrese valores numéricos válidos para la función objetivo.");
        return;
      }
      objectiveCoefficients.add(value);
    }

    for (int i = 0; i < _numRestrictions; i++) {
      List<double> row = [];
      for (int j = 0; j < _numVariables; j++) {
        final value = double.tryParse(_constraintControllers[i][j].text);
        if (value == null) {
          _showSnackBar(
              "Ingrese valores numéricos válidos en las restricciones.");
          return;
        }
        row.add(value);
      }
      constraints.add(row);
    }

    for (var c in _rhsControllers) {
      final value = double.tryParse(c.text);
      if (value == null) {
        _showSnackBar(
            "Ingrese valores numéricos válidos para el lado derecho.");
        return;
      }
      rhs.add(value);
    }

    // Para depuración
    debugPrint("Tipo de función objetivo: $_objectiveType");
    debugPrint("Función Objetivo: $objectiveCoefficients");
    debugPrint("Restricciones: $constraints");
    debugPrint("Operadores: $_constraintOperators");
    debugPrint("Lado derecho: $rhs");

    _showSnackBar("Datos capturados correctamente (Método Dos Fases).");
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
                borderRadius: BorderRadius.circular(25.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numVariablesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad de Variables',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(color: Colors.black),
                            ),
                            onSubmitted: (_) => _updateMatrixSize(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _numRestrictionsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad de Restricciones',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(color: Colors.black),
                            ),
                            onSubmitted: (_) => _updateMatrixSize(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _updateMatrixSize,
                          child: const Text("Confirmar"),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_numVariables > 0) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<String>(
                              value: _objectiveType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                  color: Colors
                                      .black), // <-- texto negro cuando está cerrado
                              items: const [
                                DropdownMenuItem(
                                  value: 'Maximizar',
                                  child: Text('Maximizar',
                                      style: TextStyle(color: Colors.black)),
                                ),
                                DropdownMenuItem(
                                  value: 'Minimizar',
                                  child: Text('Minimizar',
                                      style: TextStyle(color: Colors.black)),
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
                          const SizedBox(width: 8),
                          const Text(
                            "Z:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: List.generate(_numVariables, (index) {
                                return SizedBox(
                                  width: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _objectiveFunctionControllers[
                                                  index],
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                              color: Colors.black),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      Text(" X${index + 1}",
                                          style: const TextStyle(
                                              color: Colors.black)),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (_numRestrictions > 0) ...[
                      const Text(
                        "S.A.",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: List.generate(_numRestrictions, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: List.generate(_numVariables, (j) {
                                      return SizedBox(
                                        width: 70,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _constraintControllers[i]
                                                        [j],
                                                keyboardType:
                                                    TextInputType.number,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 8),
                                                ),
                                              ),
                                            ),
                                            Text(
                                                " X${j + 1} ${j < _numVariables - 1 ? '+' : ''}",
                                                style: const TextStyle(
                                                    color: Colors.black)),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                DropdownButton<String>(
                                  value: _constraintOperators[i],
                                  dropdownColor: Colors.white,
                                  items: const [
                                    DropdownMenuItem(
                                      value: '≤',
                                      child: Text('≤',
                                          style:
                                              TextStyle(color: Colors.black)),
                                    ),
                                    DropdownMenuItem(
                                      value: '≥',
                                      child: Text('≥',
                                          style:
                                              TextStyle(color: Colors.black)),
                                    ),
                                    DropdownMenuItem(
                                      value: '=',
                                      child: Text('=',
                                          style:
                                              TextStyle(color: Colors.black)),
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
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _rhsControllers[i],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.black),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      )
                    ],
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _generateSolution,
                        child: const Text("Generar"),
                      ),
                    )
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
