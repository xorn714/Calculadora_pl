class TwoPhaseResult {
  final String message;
  final double optimalValue;
  final List<double> solution;
  final List<String> steps;

  TwoPhaseResult({
    required this.message,
    required this.optimalValue,
    required this.solution,
    required this.steps,
  });
}

class TwoPhaseMethod {
  static TwoPhaseResult solve({
    required List<double> objectiveCoefficients,
    required List<List<double>> constraints,
    required List<double> rhs,
    required List<String> constraintOperators,
    required String objectiveType,
  }) {
    List<String> steps = [];
    List<double> solution = [];
    String message = "";
    double optimalValue = 0;

    try {
      steps.add("=== INICIO DEL MÉTODO DE DOS FASES ===");
      steps.add("Preparando el problema...");

      int numVariables = objectiveCoefficients.length;
      int numConstraints = constraints.length;

      // FASE 1: Preparar problema artificial
      steps.add("\n=== FASE 1: Encontrar solución factible ===");

      // Determinar variables de holgura, exceso y artificiales
      List<int> artificialVars = [];
      List<int> slackVars = [];
      List<int> surplusVars = [];

      for (int i = 0; i < numConstraints; i++) {
        if (constraintOperators[i] == '≤') {
          slackVars.add(i);
        } else if (constraintOperators[i] == '≥') {
          surplusVars.add(i);
          artificialVars.add(i);
        } else if (constraintOperators[i] == '=') {
          artificialVars.add(i);
        }
      }

      int totalCols = numVariables +
          slackVars.length +
          surplusVars.length +
          artificialVars.length;

      // Crear tabla para Fase 1
      List<List<double>> phase1Table = List.generate(
          numConstraints + 1, (_) => List.filled(totalCols + 1, 0.0));

      // Llenar restricciones
      for (int i = 0; i < numConstraints; i++) {
        // Variables originales
        for (int j = 0; j < numVariables; j++) {
          phase1Table[i][j] = constraints[i][j];
        }

        // Variables de holgura
        if (constraintOperators[i] == '≤') {
          int slackIndex = numVariables + slackVars.indexOf(i);
          phase1Table[i][slackIndex] = 1.0;
        }
        // Variables de exceso y artificiales
        else if (constraintOperators[i] == '≥') {
          int surplusIndex =
              numVariables + slackVars.length + surplusVars.indexOf(i);
          phase1Table[i][surplusIndex] = -1.0;
          int artificialIndex = numVariables +
              slackVars.length +
              surplusVars.length +
              artificialVars.indexOf(i);
          phase1Table[i][artificialIndex] = 1.0;
        }
        // Solo variables artificiales
        else if (constraintOperators[i] == '=') {
          int artificialIndex = numVariables +
              slackVars.length +
              surplusVars.length +
              artificialVars.indexOf(i);
          phase1Table[i][artificialIndex] = 1.0;
        }

        // Lado derecho
        phase1Table[i][totalCols] = rhs[i];
      }

      // Función objetivo de Fase 1 (minimizar suma de variables artificiales)
      for (int i = 0; i < numConstraints; i++) {
        if (constraintOperators[i] == '≥' || constraintOperators[i] == '=') {
          int artificialIndex = numVariables +
              slackVars.length +
              surplusVars.length +
              artificialVars.indexOf(i);
          phase1Table[numConstraints][artificialIndex] = 1.0;

          // Restar las filas de restricción con variables artificiales de la función objetivo
          for (int j = 0; j <= totalCols; j++) {
            phase1Table[numConstraints][j] -= phase1Table[i][j];
          }
        }
      }

      steps.add("Tabla inicial para Fase 1 creada:");
      steps.addAll(_formatTableau(phase1Table));

      // Resolver Fase 1
      phase1Table = _simplex(phase1Table, steps, phase: 1);

      // Verificar si se encontró solución factible
      if (phase1Table.last.last.abs() > 1e-6) {
        message = "El problema no tiene solución factible.";
        steps.add(message);
        return TwoPhaseResult(
          message: message,
          optimalValue: 0,
          solution: [],
          steps: steps,
        );
      }

      // FASE 2: Preparar tabla sin variables artificiales
      steps.add("\n=== FASE 2: Optimizar función objetivo original ===");

      // Determinar variables básicas de la Fase 1
      List<int> basicVars = [];
      for (int j = 0; j < totalCols; j++) {
        int countOnes = 0;
        for (int i = 0; i < numConstraints; i++) {
          if (phase1Table[i][j].abs() > 1e-6) {
            if ((phase1Table[i][j] - 1.0).abs() < 1e-6) {
              countOnes++;
            } else {
              countOnes = 0;
              break;
            }
          }
        }
        if (countOnes == 1) {
          basicVars.add(j);
        }
      }

      // Crear tabla para Fase 2 (sin columnas artificiales)
      int phase2Cols = numVariables + slackVars.length + surplusVars.length;
      List<List<double>> phase2Table = List.generate(
          numConstraints + 1, (_) => List.filled(phase2Cols + 1, 0.0));

      // Copiar restricciones (sin variables artificiales)
      for (int i = 0; i < numConstraints; i++) {
        for (int j = 0; j < phase2Cols; j++) {
          phase2Table[i][j] = phase1Table[i][j];
        }
        phase2Table[i][phase2Cols] = phase1Table[i][totalCols];
      }

      // Configurar función objetivo original
      for (int j = 0; j < numVariables; j++) {
        phase2Table[numConstraints][j] = (objectiveType == 'Maximizar')
            ? -objectiveCoefficients[j]
            : objectiveCoefficients[j];
      }

      // Ajustar la función objetivo para variables básicas
      for (int j = 0; j < phase2Cols; j++) {
        for (int i = 0; i < numConstraints; i++) {
          if (phase2Table[i][j] == 1.0) {
            bool isBasic = true;
            for (int k = 0; k < numConstraints; k++) {
              if (k != i && phase2Table[k][j].abs() > 1e-6) {
                isBasic = false;
                break;
              }
            }
            if (isBasic && phase2Table[numConstraints][j].abs() > 1e-6) {
              double coeff = phase2Table[numConstraints][j];
              for (int k = 0; k <= phase2Cols; k++) {
                phase2Table[numConstraints][k] -= coeff * phase2Table[i][k];
              }
            }
          }
        }
      }

      steps.add("Tabla inicial para Fase 2 creada:");
      steps.addAll(_formatTableau(phase2Table));

      // Resolver Fase 2
      phase2Table = _simplex(phase2Table, steps, phase: 2);

      // Extraer solución
      solution = List.filled(numVariables, 0.0);
      for (int j = 0; j < numVariables; j++) {
        for (int i = 0; i < numConstraints; i++) {
          if (phase2Table[i][j] == 1.0) {
            bool isBasic = true;
            for (int k = 0; k < numConstraints; k++) {
              if (k != i && phase2Table[k][j].abs() > 1e-6) {
                isBasic = false;
                break;
              }
            }
            if (isBasic) {
              solution[j] = phase2Table[i][phase2Cols];
            }
          }
        }
      }

      optimalValue = (objectiveType == 'Maximizar')
          ? phase2Table[numConstraints][phase2Cols]
          : -phase2Table[numConstraints][phase2Cols];

      message = "Solución óptima encontrada.";
      steps.add(message);
      steps.add("Valor óptimo: $optimalValue");
      steps.add(
          "Solución: ${solution.map((x) => x.toStringAsFixed(2)).join(', ')}");
    } on Exception catch (e) {
      message = "Error: ${e.toString()}";
      steps.add(message);
      rethrow;
    } catch (e, stackTrace) {
      message = "Error durante el cálculo: ${e.toString()}";
      steps.add(message);
      steps.add("Stack trace: $stackTrace");
      throw Exception(message);
    }

    return TwoPhaseResult(
      message: message,
      optimalValue: optimalValue,
      solution: solution,
      steps: steps,
    );
  }

  static List<List<double>> _simplex(
      List<List<double>> tableau, List<String> steps,
      {required int phase}) {
    int numRows = tableau.length - 1;
    int numCols = tableau[0].length - 1;

    steps.add("\nIniciando fase $phase...");

    while (true) {
      // Paso 1: Verificar optimalidad
      bool isOptimal = true;
      int pivotCol = -1;
      double minVal = 0;

      for (int j = 0; j < numCols; j++) {
        if (tableau.last[j] < -1e-6) {
          isOptimal = false;
          if (tableau.last[j] < minVal) {
            minVal = tableau.last[j];
            pivotCol = j;
          }
        }
      }

      if (isOptimal) break;

      if (pivotCol == -1) {
        steps.add("No se encontró columna pivote válida.");
        break;
      }

      steps.add(
          "Columna pivote seleccionada: ${pivotCol + 1} (valor: ${tableau.last[pivotCol].toStringAsFixed(4)})");

      // Paso 2: Encontrar fila pivote
      int pivotRow = -1;
      double minRatio = double.infinity;

      for (int i = 0; i < numRows; i++) {
        if (tableau[i][pivotCol] > 1e-6) {
          double ratio = tableau[i].last / tableau[i][pivotCol];
          if (ratio < minRatio) {
            minRatio = ratio;
            pivotRow = i;
          }
        }
      }

      if (pivotRow == -1) {
        steps.add("El problema es no acotado.");
        throw Exception(
            "Problema no acotado: No se encontró fila pivote válida");
      }

      steps.add(
          "Fila pivote seleccionada: ${pivotRow + 1} (ratio: ${minRatio.toStringAsFixed(4)})");
      steps.add(
          "Elemento pivote: ${tableau[pivotRow][pivotCol].toStringAsFixed(4)}");

      // Paso 3: Operación de pivote
      double pivotVal = tableau[pivotRow][pivotCol];

      // Normalizar fila pivote
      for (int j = 0; j <= numCols; j++) {
        tableau[pivotRow][j] /= pivotVal;
      }

      // Actualizar otras filas
      for (int i = 0; i <= numRows; i++) {
        if (i != pivotRow) {
          double factor = tableau[i][pivotCol];
          for (int j = 0; j <= numCols; j++) {
            tableau[i][j] -= factor * tableau[pivotRow][j];
          }
        }
      }

      steps.add("Tabla después del pivoteo:");
      steps.addAll(_formatTableau(tableau));
    }

    steps.add("Solución óptima encontrada en fase $phase");
    return tableau;
  }

  static List<String> _formatTableau(List<List<double>> tableau) {
    List<String> lines = [];
    
    // Primero añadimos la fila Z (última fila)
    String zLine = "Z | ${tableau.last.map((val) => val.toStringAsFixed(2)).join(" | ")}";
    lines.add(zLine);
    
    // Luego añadimos las demás filas (restricciones)
    for (int i = 0; i < tableau.length - 1; i++) {
      String line = "${i + 1} | ${tableau[i].map((val) => val.toStringAsFixed(2)).join(" | ")}";
      lines.add(line);
    }
    
    return lines;
  }
}