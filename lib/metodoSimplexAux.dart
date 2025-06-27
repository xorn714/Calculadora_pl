import 'package:flutter/material.dart';
import 'simplexSolver.dart';

class SimplexScreen extends StatefulWidget {
  const SimplexScreen({super.key});

  @override
  _SimplexScreenState createState() => _SimplexScreenState();
}

class _SimplexScreenState extends State<SimplexScreen> {
  String _selectedOption = 'Maximizar';
  int _numVariables = 2;
  int _numRestricciones = 2;

  final TextEditingController _varController = TextEditingController(text: '2');
  final TextEditingController _resController = TextEditingController(text: '2');

  List<List<TextEditingController>> _matrixControllers = [];
  Map<String, dynamic> _resultadoSimplex = {};

  @override
  void initState() {
    super.initState();
    _initializeMatrix();
  }

  @override
  void dispose() {
    _varController.dispose();
    _resController.dispose();
    _disposeMatrixControllers();
    super.dispose();
  }

  void _disposeMatrixControllers() {
    for (var row in _matrixControllers) {
      for (var cell in row) {
        cell.dispose();
      }
    }
  }

  void _initializeMatrix() {
    _disposeMatrixControllers();

    int columns = _numVariables + _numRestricciones + 2;
    int rows = _numRestricciones + 1;

    _matrixControllers = List.generate(
      rows,
      (i) => List.generate(
        columns,
        (j) => TextEditingController(text: '0'),
      ),
    );

    // Configurar valores iniciales para la función objetivo (fila 0)
    if (_matrixControllers.isNotEmpty) {
      _matrixControllers[0][_numVariables].text = '1'; // Para Z
      for (int i = 1; i <= _numVariables; i++) {
        _matrixControllers[0][i - 1].text =
            i == 1 ? '1' : '0'; // Coeficientes de ejemplo
      }
    }

    // Configurar matriz identidad para variables de holgura
    for (int i = 1; i <= _numRestricciones; i++) {
      int holguraCol = _numVariables + i;
      if (i < _matrixControllers.length &&
          holguraCol < _matrixControllers[i].length) {
        _matrixControllers[i][holguraCol].text = '1';
      }
    }

    setState(() {});
  }

  void _updateMatrixDimensions() {
    int newVars = int.tryParse(_varController.text) ?? 2;
    int newRestr = int.tryParse(_resController.text) ?? 2;

    if (newVars != _numVariables || newRestr != _numRestricciones) {
      setState(() {
        _numVariables = newVars.clamp(1, 10);
        _numRestricciones = newRestr.clamp(1, 10);
        _initializeMatrix();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2D42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF123456),
        title: const Text('Método Simplex'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('Entrada de Datos',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maximizar / Minimizar:'),
                          DropdownButton<String>(
                            value: _selectedOption,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black),
                            items: ['Maximizar', 'Minimizar']
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedOption = value!);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Número de variables:'),
                          TextField(
                            controller: _varController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            onChanged: (value) => _updateMatrixDimensions(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Número de restricciones:'),
                          TextField(
                            controller: _resController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black),
                            onChanged: (value) => _updateMatrixDimensions(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Matriz aumentada:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    child: Table(
                      border: TableBorder.all(),
                      defaultColumnWidth: const FixedColumnWidth(60),
                      children: [
                        // Encabezados de columnas
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Z',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            for (int j = 0; j < _numVariables; j++)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'x${j + 1}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            for (int j = 0; j < _numRestricciones; j++)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'S${j + 1}', // Cambiado de 'h' a 'S'
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Sol',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Fila de la función objetivo (Z)
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue[50]),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                controller: _matrixControllers[0][0],
                                enabled: false,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            for (int j = 1;
                                j < _numVariables + _numRestricciones + 1;
                                j++)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  controller: _matrixControllers[0][j],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  enabled: j > _numVariables
                                      ? false
                                      : true, // No editable si es holgura
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            // LD (última columna)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                controller: _matrixControllers[0]
                                    [_numVariables + _numRestricciones + 1],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Filas de restricciones
                        for (int i = 1; i <= _numRestricciones; i++)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  controller: _matrixControllers[i][0],
                                  enabled: false,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              for (int j = 1;
                                  j < _numVariables + _numRestricciones + 1;
                                  j++)
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextField(
                                    controller: _matrixControllers[i][j],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    enabled: j > _numVariables
                                        ? false
                                        : true, // No editable si es columna de holgura
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              // LD (última columna)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: TextField(
                                  controller: _matrixControllers[i]
                                      [_numVariables + _numRestricciones + 1],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    try {
                      List<List<double>> matrix = [];
                      for (var row in _matrixControllers) {
                        List<double> rowValues = [];
                        for (var cell in row) {
                          double value =
                              double.tryParse(cell.text.replaceAll(',', '.')) ??
                                  0;
                          rowValues.add(value);
                        }
                        matrix.add(rowValues);
                      }

                      final resultado = SimplexSolver.resolver(
                        matrix,
                        esMaximizacion: _selectedOption == 'Maximizar',
                      );

                      setState(() {
                        _resultadoSimplex = resultado;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(resultado['mensaje']),
                          backgroundColor: resultado['exito'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Calcular'),
                ),
                const SizedBox(height: 32),
                const Text('Iteraciones',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_resultadoSimplex['exito'] == true) ...[
                        Text('Solución Óptima:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: _resultadoSimplex['solucion'] is Map<String, double>
                              ? _buildSolucionWidgets(_resultadoSimplex)
                              : [const Text('-')],
                        ),
                        const SizedBox(height: 12),
                        Text(
                            'Valor Óptimo: Z = ${_resultadoSimplex['zOptimo'] is num ? (_resultadoSimplex['zOptimo'] as num).toStringAsFixed(2) : "-"}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ] else if (_resultadoSimplex['mensaje'] != null) ...[
                        Text('Resultado:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(_resultadoSimplex['mensaje'],
                            style: TextStyle(color: Colors.red[800])),
                      ] else ...[
                        const Text('Solución Óptima: -',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSolucionWidgets(Map<String, dynamic> resultado) {
    final solucion = resultado['solucion'] as Map<String, double>;
    List<Widget> widgets = [];

    // Ordenar las variables para mostrarlas consistentemente
    var keys = solucion.keys.toList()..sort((a, b) => a.compareTo(b));

    for (var key in keys) {
      widgets.add(
        Text('$key = ${solucion[key]?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(fontSize: 14)),
      );
    }

    return widgets;
  }
}
