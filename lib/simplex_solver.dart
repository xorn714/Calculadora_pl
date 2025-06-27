// lib/simplex_solver.dart
import 'dart:math';

/// Clase que implementa la lógica del método Simplex para problemas de programación lineal.
class SimplexSolver {
  final List<double> objectiveFunctionCoefficients;
  final List<List<double>> constraintCoefficients;
  final List<double> rhsValues;

  List<double>? _optimalSolution;
  double? _optimalZValue;
  // Initialize _simplexTableau directly here to guarantee it's never null.
  List<List<double>> _simplexTableau = [];

  SimplexSolver({
    required this.objectiveFunctionCoefficients,
    required this.constraintCoefficients,
    required this.rhsValues,
  });

  List<double>? get optimalSolution => _optimalSolution;
  double? get optimalZValue => _optimalZValue;

  /// Returns the final simplex tableau.
  /// This getter now guarantees a non-null List<List<double>>.
  List<List<double>> getSimplexTableau() => _simplexTableau;

  void solve() {
    int numVariables = objectiveFunctionCoefficients.length;
    int numRestrictions = constraintCoefficients.length;

    // Re-initialize _simplexTableau with the correct dimensions.
    // This creates a new list of lists, ensuring no null inner lists.
    _simplexTableau = List.generate(
      numRestrictions + 1,
      (i) => List.filled(numVariables + numRestrictions + 1, 0.0),
    );

    // Fill the objective function row (first row of the tableau).
    // Accessing _simplexTableau elements without '!' as it's guaranteed non-null.
    for (int j = 0; j < numVariables; j++) {
      _simplexTableau[0][j] = -objectiveFunctionCoefficients[j];
    }
    _simplexTableau[0][numVariables + numRestrictions] = 0.0; // Z value, initially 0

    // Fill the constraint rows.
    for (int i = 0; i < numRestrictions; i++) {
      for (int j = 0; j < numVariables; j++) {
        _simplexTableau[i + 1][j] = constraintCoefficients[i][j];
      }
      _simplexTableau[i + 1][numVariables + i] = 1.0; // Slack variable coefficient
      _simplexTableau[i + 1][numVariables + numRestrictions] = rhsValues[i];
    }

    // --- Simplex Iteration ---
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
        // Only consider positive values in the pivot column to avoid division by zero or negative ratios
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
        // This indicates an unbounded problem or an error in logic.
        print('Problema no acotado o sin solución factible.');
        // Set optimal solution and Z value to null to indicate an unsolved state.
        _optimalSolution = null;
        _optimalZValue = null;
        canImprove = false;
        break;
      }

      // Perform pivot operation
      double pivotElement = _simplexTableau[pivotRow][pivotColumn];

      // Normalize the pivot row
      for (int j = 0; j < numVariables + numRestrictions + 1; j++) {
        _simplexTableau[pivotRow][j] /= pivotElement;
      }

      // Make other elements in the pivot column zero
      for (int i = 0; i < numRestrictions + 1; i++) {
        if (i != pivotRow) {
          double factor = _simplexTableau[i][pivotColumn];
          for (int j = 0; j < numVariables + numRestrictions + 1; j++) {
            _simplexTableau[i][j] -= factor * _simplexTableau[pivotRow][j];
          }
        }
      }
    }

    // --- Extract Optimal Solution ---
    _optimalSolution = List.filled(numVariables, 0.0);
    for (int j = 0; j < numVariables; j++) {
      int oneRow = -1;
      int countOnes = 0;
      for (int i = 1; i < numRestrictions + 1; i++) {
        // Check if the element is approximately 1.0
        if ((_simplexTableau[i][j] - 1.0).abs() < 1e-9) {
          oneRow = i;
          countOnes++;
        }
      }
      // If there's exactly one '1' in the column (and others are 0, implicitly by pivot operations)
      // then it's a basic variable. Added check for oneRow != -1 for safety.
      if (countOnes == 1 && oneRow != -1) {
        _optimalSolution![j] = _simplexTableau[oneRow][numVariables + numRestrictions];
      } else {
        _optimalSolution![j] = 0.0; // Non-basic variable
      }
    }

    // Optimal Z value is in the first row, last column, with negated sign
    _optimalZValue = -_simplexTableau[0][numVariables + numRestrictions];
  }
}
