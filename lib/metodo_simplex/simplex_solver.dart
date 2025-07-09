// lib/simplex_solver.dart

/// Clase que implementa la lógica del método Simplex para problemas de programación lineal.
class SimplexSolver {
  final List<double> objectiveFunctionCoefficients;
  final List<List<double>> constraintCoefficients;
  final List<double> rhsValues;

  List<double>? _optimalSolution;
  double? _optimalZValue;
  // Inicializa _simplexTableau directamente aquí para garantizar que nunca sea nulo.
  List<List<double>> _simplexTableau = [];

  SimplexSolver({
    required this.objectiveFunctionCoefficients,
    required this.constraintCoefficients,
    required this.rhsValues,
  });

  List<double>? get optimalSolution => _optimalSolution;
  double? get optimalZValue => _optimalZValue;

  /// Devuelve el tableau final del método simplex.
  List<List<double>> getSimplexTableau() => _simplexTableau;

  void solve() {
    int numVariables = objectiveFunctionCoefficients.length;
    int numRestrictions = constraintCoefficients.length;

    // Reinicializa _simplexTableau con las dimensiones correctas.
    // Esto crea una nueva lista de listas, asegurando que no haya listas internas nulas.
    _simplexTableau = List.generate(
      numRestrictions + 1,
      (i) => List.filled(numVariables + numRestrictions + 1, 0.0),
    );

    // Llena la fila de la función objetivo (primera fila del tableau).
    // Se accede a los elementos de _simplexTableau sin '!' ya que está garantizado que no es nulo.
    for (int j = 0; j < numVariables; j++) {
      _simplexTableau[0][j] = -objectiveFunctionCoefficients[j];
    }
    _simplexTableau[0][numVariables + numRestrictions] = 0.0; // Valor de Z, inicialmente 0

    // Llena las filas de restricciones.
    for (int i = 0; i < numRestrictions; i++) {
      for (int j = 0; j < numVariables; j++) {
        _simplexTableau[i + 1][j] = constraintCoefficients[i][j];
      }
      _simplexTableau[i + 1][numVariables + i] = 1.0; // Coeficiente de variable de holgura
      _simplexTableau[i + 1][numVariables + numRestrictions] = rhsValues[i];
    }

    // --- Iteración del método Simplex ---
    bool canImprove = true;
    while (canImprove) {
      int pivotColumn = -1;
      double minZCoefficient = 0.0;
      for (int j = 0; j < numVariables + numRestrictions; j++) {
        if (_simplexTableau[0][j] < minZCoefficient) {
          minZCoefficient = _simplexTableau[0][j];
          pivotColumn = j;
        }
      }

      if (pivotColumn == -1) {
        canImprove = false;
        break;
      }

      int pivotRow = -1;
      double minRatio = double.infinity;

      for (int i = 1; i < numRestrictions + 1; i++) {
        // Solo considerar valores positivos en la columna pivote para evitar división por cero o razones negativas
        if (_simplexTableau[i][pivotColumn] > 1e-9) { // Using a small epsilon for comparison with 0
          double ratio = _simplexTableau[i][numVariables + numRestrictions] /
              _simplexTableau[i][pivotColumn];
          if (ratio < minRatio) {
            minRatio = ratio;
            pivotRow = i;
          }
        }
      }

      if (pivotRow == -1) {
        // Esto indica un problema no acotado o un error en la lógica.
        print('Problema no acotado o sin solución factible.');
        // Establece la solución óptima y el valor Z en null para indicar un estado no resuelto.
        _optimalSolution = null;
        _optimalZValue = null;
        canImprove = false;
        break;
      }

      // Realizar la operación de pivoteo
      double pivotElement = _simplexTableau[pivotRow][pivotColumn];

      // Normalizar la fila pivote
      for (int j = 0; j < numVariables + numRestrictions + 1; j++) {
        _simplexTableau[pivotRow][j] /= pivotElement;
      }

      // Hacer cero los demás elementos en la columna pivote
      for (int i = 0; i < numRestrictions + 1; i++) {
        if (i != pivotRow) {
          double factor = _simplexTableau[i][pivotColumn];
          for (int j = 0; j < numVariables + numRestrictions + 1; j++) {
            _simplexTableau[i][j] -= factor * _simplexTableau[pivotRow][j];
          }
        }
      }
    }

    // --- Extraer la solución óptima ---
    _optimalSolution = List.filled(numVariables, 0.0);
    for (int j = 0; j < numVariables; j++) {
      int oneRow = -1;
      int countOnes = 0;
      for (int i = 1; i < numRestrictions + 1; i++) {
        // Verifica si el elemento es aproximadamente 1.0
        if ((_simplexTableau[i][j] - 1.0).abs() < 1e-9) {
          oneRow = i;
          countOnes++;
        }
      }
      // Si hay exactamente un '1' en la columna (y los demás son 0, implícitamente por las operaciones de pivoteo)
      // entonces es una variable básica. Se añade la comprobación de oneRow != -1 por seguridad.
      if (countOnes == 1 && oneRow != -1) {
        _optimalSolution![j] = _simplexTableau[oneRow][numVariables + numRestrictions];
      } else {
        _optimalSolution![j] = 0.0; // Variable no básica
      }
    }
    _optimalZValue = _simplexTableau[0][numVariables + numRestrictions];
  }
}
