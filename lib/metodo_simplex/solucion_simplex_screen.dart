// lib/solucion_simplex_screen.dart
import 'package:calculadora_pl/metodo_simplex/simplex_solver.dart';
import 'package:flutter/material.dart';

class SolucionSimplexScreen extends StatefulWidget {
  final List<double> objectiveFunctionCoefficients;
  final List<List<double>> constraintCoefficients;
  final List<double> rhsValues;

  const SolucionSimplexScreen({
    super.key,
    required this.objectiveFunctionCoefficients,
    required this.constraintCoefficients,
    required this.rhsValues,
  });

  @override
  State<SolucionSimplexScreen> createState() => _SolucionSimplexScreenState();
}

class _SolucionSimplexScreenState extends State<SolucionSimplexScreen> {
  late SimplexSolver _solver;
  List<double>? _optimalSolution;
  double? _optimalZValue;
  List<List<double>>? _finalSimplexTableau; // To store the final tableau
  List<String>? _basicVariableRowLabels; // To store labels for basic variables per row

  @override
  void initState() {
    super.initState();
    _solver = SimplexSolver(
      objectiveFunctionCoefficients: widget.objectiveFunctionCoefficients,
      constraintCoefficients: widget.constraintCoefficients,
      rhsValues: widget.rhsValues,
    );
    _solver.solve(); // Run the simplex algorithm
    _optimalSolution = _solver.optimalSolution;
    _optimalZValue = _solver.optimalZValue;
    _finalSimplexTableau = _solver.getSimplexTableau(); // Get the final tableau

    // Populate basic variable labels for each row
    _basicVariableRowLabels = [];
    if (_finalSimplexTableau != null && _finalSimplexTableau!.isNotEmpty) {
      int numOriginalVars = widget.objectiveFunctionCoefficients.length;
      int numConstraints = widget.constraintCoefficients.length;

      // The first row is always the Z-row
      _basicVariableRowLabels!.add('Z');

      // Iterate through the constraint rows to identify basic variables
      // Rows start from index 1 in the tableau (after the Z-row)
      for (int i = 0; i < numConstraints; i++) {
        int basicVarColIndex = -1;
        // Search for a column that represents a basic variable (unit vector: 1 in this row, 0 elsewhere)
        for (int j = 0; j < numOriginalVars + numConstraints; j++) { // Iterate through X and S columns
          // Check for '1' in the current row (i + 1 because of Z-row)
          if (_finalSimplexTableau![i + 1][j].abs() - 1.0 < 0.0001) { // Using a small tolerance for double comparison
            bool isUnitVector = true;
            // Check if all other rows have '0' in this column
            for (int k = 0; k < numConstraints + 1; k++) { // Iterate through all rows including Z-row
              if (k != i + 1 && _finalSimplexTableau![k][j].abs() > 0.0001) { // Check for non-zero values
                isUnitVector = false;
                break;
              }
            }
            if (isUnitVector) {
              basicVarColIndex = j;
              break;
            }
          }
        }

        // Assign the basic variable label based on the identified column index
        if (basicVarColIndex != -1) {
          if (basicVarColIndex < numOriginalVars) {
            _basicVariableRowLabels!.add('X${basicVarColIndex + 1}');
          } else {
            _basicVariableRowLabels!.add('S${basicVarColIndex + 1 - numOriginalVars}');
          }
        } else {
          // Fallback if no clear basic variable is found for the row (should not happen in a solved tableau)
          _basicVariableRowLabels!.add('R${i + 1}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solución del Método Simplex'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                    const Text(
                      'Función Objetivo (Z):',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Z = ${widget.objectiveFunctionCoefficients.asMap().entries.map((entry) {
                        int index = entry.key;
                        double coeff = entry.value;
                        String sign = coeff >= 0 ? (index == 0 ? '' : ' + ') : ' - ';
                        return '${sign}${coeff.abs()}X${index + 1}';
                      }).join()}',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Restricciones (S.A.):',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          List.generate(widget.constraintCoefficients.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.constraintCoefficients[i]
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        int index = entry.key;
                                        double coeff = entry.value;
                                        String sign =
                                            coeff >= 0 ? (index == 0 ? '' : ' + ') : ' - ';
                                        return '${sign}${coeff.abs()}X${index + 1}';
                                      }).join(),
                                  style:
                                      const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('≤',
                                  style: TextStyle(fontSize: 16, color: Colors.black)),
                              const SizedBox(width: 8),
                              Text(
                                widget.rhsValues[i].toString(),
                                style:
                                    const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Solución del Método Simplex:',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    // Display the final Simplex Tableau
                    if (_finalSimplexTableau != null) ...[
                      const Text(
                        'Matriz Simplex Final:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 12,
                          dataRowMinHeight: 20,
                          dataRowMaxHeight: 30,
                          columns: [
                            // New column for Basic Variable labels
                            DataColumn(
                                label: Text('Variable Básica',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))),
                            ...List.generate(
                              _finalSimplexTableau![0].length,
                              (index) => DataColumn(
                                  label: Text(
                                      index < widget.objectiveFunctionCoefficients.length
                                          ? 'X${index + 1}'
                                          : (index <
                                                  widget.objectiveFunctionCoefficients.length +
                                                      widget.constraintCoefficients.length
                                              ? 'S${index + 1 - widget.objectiveFunctionCoefficients.length}'
                                              : 'Sol'),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black))),
                            ),
                          ],
                          rows: _finalSimplexTableau!.asMap().entries.map((rowEntry) {
                            int rowIndex = rowEntry.key;
                            List<double> row = rowEntry.value;
                            return DataRow(
                              cells: [
                                // DataCell for Basic Variable label
                                DataCell(
                                  Text(
                                    _basicVariableRowLabels![rowIndex],
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            rowIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                ...row.map((cellValue) {
                                  return DataCell(
                                    Text(
                                      cellValue.toStringAsFixed(2), // Format to 2 decimal places
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              rowIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                          color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Valor óptimo de Z: ${_optimalZValue?.toStringAsFixed(2) ?? 'Calculando...'}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Valores de las variables (Xn):',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (_optimalSolution != null)
                      ...List.generate(_optimalSolution!.length, (index) {
                        return Text(
                          'X${index + 1} = ${_optimalSolution![index].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        );
                      })
                    else
                      const Text(
                        'Calculando valores...',
                        style: TextStyle(fontSize: 16, color: Colors.black),
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
