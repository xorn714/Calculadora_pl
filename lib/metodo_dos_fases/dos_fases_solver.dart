class TwoPhaseResult {
  final bool isOptimal;
  final List<double> solution;
  final double optimalValue;
  final List<List<List<double>>> tableaux;
  final List<String> steps;
  final String message;

  TwoPhaseResult({
    required this.isOptimal,
    required this.solution,
    required this.optimalValue,
    required this.tableaux,
    required this.steps,
    required this.message,
  });
}

class TwoPhaseMethod {
  /// Resuelve un problema LP por el método de dos fases
  static TwoPhaseResult solve({
    required List<double> objectiveCoefficients,
    required List<List<double>> constraints,
    required List<double> rhs,
    required List<String> constraintOperators,
    required String objectiveType,
  }) {
    List<String> steps = [];
    List<List<List<double>>> tableaux = [];

    steps.add("Iniciando método de dos fases...");
    steps.add("Tipo de problema: ${objectiveType.toUpperCase()}");

    bool isMinimization = objectiveType.toLowerCase() == 'minimizar';
    List<double> c = List.from(objectiveCoefficients);

    if (isMinimization) {
      steps.add("Convirtiendo problema de minimización a maximización...");
      c = c.map((x) => -x).toList();
    }

    steps.add("\n=== FASE 1 ===");
    steps.add("Construyendo problema auxiliar...");

    int numVariables = c.length;
    int numConstraints = constraints.length;

    List<int> artificialVars = [];
    for (int i = 0; i < numConstraints; i++) {
      if (constraintOperators[i] == '≥' || constraintOperators[i] == '=') {
        artificialVars.add(i);
      }
    }

    int numArtificial = artificialVars.length;
    steps.add("Variables artificiales necesarias: $numArtificial");

    List<List<double>> phase1Table = _buildPhase1Table(
      c,
      constraints,
      rhs,
      constraintOperators,
      numVariables,
      numConstraints,
      artificialVars,
    );

    tableaux.add(_copyTable(phase1Table));
    steps.add("Tabla inicial de Fase 1 creada.");

    steps.add("Ejecutando Simplex en Fase 1...");
    TwoPhaseResult phase1Result = _simplex(
      phase1Table,
      numVariables,
      numConstraints,
      numArtificial,
      isPhase1: true,
    );

    if (phase1Result.optimalValue > 1e-10) {
      steps.add(
          "Problema no factible. Valor objetivo en Fase 1: ${phase1Result.optimalValue}");
      return TwoPhaseResult(
        isOptimal: false,
        solution: [],
        optimalValue: 0,
        tableaux: tableaux,
        steps: steps,
        message: "El problema no tiene solución factible (Fase 1 > 0).",
      );
    }

    steps.add("Fase 1 exitosa. Valor objetivo: ${phase1Result.optimalValue}");

    steps.add("\n=== FASE 2 ===");
    steps.add("Construyendo tabla para Fase 2...");

    List<List<double>> phase2Table = _buildPhase2Table(
      phase1Result.tableaux.last,
      c,
      numVariables,
      numConstraints,
      artificialVars,
    );

    tableaux.add(_copyTable(phase2Table));
    steps.add("Tabla inicial de Fase 2 creada.");

    steps.add("Ejecutando Simplex en Fase 2...");
    TwoPhaseResult phase2Result = _simplex(
      phase2Table,
      numVariables,
      numConstraints,
      0,
      isPhase1: false,
    );

    steps.addAll(phase2Result.steps);
    tableaux.addAll(phase2Result.tableaux);

    double finalOptimal = phase2Result.optimalValue;
    if (isMinimization) {
      finalOptimal = -finalOptimal;
      steps.add(
          "Ajuste del valor óptimo para problema de minimización: $finalOptimal");
    }

    return TwoPhaseResult(
      isOptimal: phase2Result.isOptimal,
      solution: phase2Result.solution,
      optimalValue: finalOptimal,
      tableaux: tableaux,
      steps: steps,
      message: phase2Result.isOptimal
          ? "Solución óptima encontrada."
          : "El problema no tiene solución óptima finita.",
    );
  }

  /// Construye la tabla inicial para la Fase 1 del método de dos fases
  static List<List<double>> _buildPhase1Table(
    List<double> c,
    List<List<double>> constraints,
    List<double> rhs,
    List<String> constraintOperators,
    int numVariables,
    int numConstraints,
    List<int> artificialVars,
  ) {
    int totalSlacks = 0;
    for (var op in constraintOperators) {
      if (op == '≤' || op == '≥') {
        totalSlacks++;
      }
    }

    int totalCols = 1 + numVariables + totalSlacks + artificialVars.length + 1;
    List<List<double>> table = List.generate(
      numConstraints + 1,
      (_) => List.filled(totalCols, 0.0),
    );

    table[0][0] = 1.0;

    for (int i = 0; i < artificialVars.length; i++) {
      int artificialCol = 1 + numVariables + totalSlacks + i;
      table[0][artificialCol] = 1.0;
    }

    int slackCount = 0;
    int artificialCount = 0;
    for (int i = 0; i < numConstraints; i++) {
      for (int j = 0; j < numVariables; j++) {
        table[i + 1][1 + j] = constraints[i][j];
      }

      String op = constraintOperators[i];
      if (op == '≤') {
        table[i + 1][1 + numVariables + slackCount] = 1.0;
        slackCount++;
      } else if (op == '≥') {
        table[i + 1][1 + numVariables + slackCount] = -1.0;
        table[i + 1][1 + numVariables + totalSlacks + artificialCount] = 1.0;
        slackCount++;
        artificialCount++;
      } else if (op == '=') {
        table[i + 1][1 + numVariables + totalSlacks + artificialCount] = 1.0;
        artificialCount++;
      }

      table[i + 1][totalCols - 1] = rhs[i];
    }

    artificialCount = 0;
    for (int i = 0; i < numConstraints; i++) {
      String op = constraintOperators[i];
      if (op == '≥' || op == '=') {
        table[0] = _addRows(table[0], table[i + 1]);
        artificialCount++;
      }
    }

    return table;
  }

  /// Construye la tabla inicial para la Fase 2 tras eliminar variables artificiales
  static List<List<double>> _buildPhase2Table(
    List<List<double>> phase1FinalTable,
    List<double> c,
    int numVariables,
    int numConstraints,
    List<int> artificialVars,
  ) {
    int numArtificial = artificialVars.length;
    // 1. Eliminar completamente columnas de variables artificiales
    List<List<double>> phase2Table = phase1FinalTable
        .map((fila) => fila.sublist(0, fila.length - numArtificial))
        .toList();

    // 2. Restaurar función objetivo original
    for (int j = 0; j < numVariables; j++) {
      phase2Table[0][1 + j] = -c[j]; // Negativo porque es tableau simplex
    }

    // Ajustar la fila objetivo para que las variables básicas tengan coeficiente 0
    int totalPhase2Cols = phase2Table[0].length;
    for (int j = 1; j < totalPhase2Cols - 1; j++) {
      int basicRow = -1;
      for (int i = 1; i <= numConstraints; i++) {
        if ((phase2Table[i][j] - 1.0).abs() < 1e-10) {
          bool isBasic = true;
          for (int k = 1; k <= numConstraints; k++) {
            if (k != i && phase2Table[k][j].abs() > 1e-10) {
              isBasic = false;
              break;
            }
          }
          if (isBasic) {
            basicRow = i;
            break;
          }
        }
      }
      if (basicRow != -1 && phase2Table[0][j].abs() > 1e-10) {
        double coef = phase2Table[0][j];
        for (int k = 0; k < totalPhase2Cols; k++) {
          phase2Table[0][k] -= coef * phase2Table[basicRow][k];
        }
      }
    }

    return phase2Table;
  }

  /// Verifica si la solución encontrada es factible para las restricciones dadas
  static bool esFactible(List<double> solucion) {
    // Ejemplo para 3 restricciones, personalizar según el problema
    if ((3 * solucion[0] + solucion[1] - 3).abs() > 1e-6) return false;
    if (4 * solucion[0] + 3 * solucion[1] < 6 - 1e-6) return false;
    if (solucion[0] + 2 * solucion[1] > 4 + 1e-6) return false;
    return true;
  }

  /// Ejecuta el algoritmo Simplex sobre la tabla dada
  static TwoPhaseResult _simplex(
    List<List<double>> table,
    int numVariables,
    int numConstraints,
    int numArtificial, {
    required bool isPhase1,
  }) {
    List<String> steps = [];
    List<List<List<double>>> tableaux = [];
    tableaux.add(_copyTable(table));
    steps.add("Tabla inicial:\n${_tableToString(table)}");

    int iteration = 0;
    while (iteration < 100) {
      iteration++;
      steps.add("\nIteración $iteration");

      // 1. Encontrar columna pivote (la más negativa en la fila objetivo)
      int pivotCol = -1;
      double minReducedCost = 0.0;

      // Ajustar el rango de búsqueda para excluir variables artificiales en Fase 2
      int lastColToCheck = table[0].length - 1;
      if (isPhase1) {
        lastColToCheck = 1 +
            numVariables +
            (table[0].length - 2 - numVariables - numArtificial);
      }

      for (int j = 1; j < lastColToCheck; j++) {
        if (table[0][j] < minReducedCost - 1e-10) {
          minReducedCost = table[0][j];
          pivotCol = j;
        }
      }

      if (pivotCol == -1) {
        // Verificar si esto es realmente óptimo o si hay variables artificiales en la base
        bool hasArtificialInBasis = false;
        if (!isPhase1 && numArtificial > 0) {
          for (int j = 1 + numVariables; j < table[0].length - 1; j++) {
            if (j >=
                1 +
                    numVariables +
                    (table[0].length - 2 - numVariables - numArtificial)) {
              // Estas son columnas de artificiales
              for (int i = 1; i < table.length; i++) {
                if ((table[i][j] - 1.0).abs() < 1e-10) {
                  bool unique = true;
                  for (int k = 1; k < table.length; k++) {
                    if (k != i && table[k][j].abs() > 1e-10) {
                      unique = false;
                      break;
                    }
                  }
                  if (unique) {
                    hasArtificialInBasis = true;
                    break;
                  }
                }
              }
            }
            if (hasArtificialInBasis) break;
          }
        }

        if (hasArtificialInBasis) {
          steps.add("¡Advertencia! Variables artificiales aún en la base.");
          return TwoPhaseResult(
            isOptimal: false,
            solution: [],
            optimalValue: 0,
            tableaux: tableaux,
            steps: steps,
            message:
                "El problema no tiene solución factible (artificiales en base).",
          );
        } else {
          steps.add("No hay columnas entrantes. Óptimo alcanzado.");
          break;
        }
      }

      steps.add(
          "Variable entrante en columna $pivotCol (coef: $minReducedCost)");

      int pivotRow = -1;
      double minRatio = double.infinity;

      for (int i = 1; i < table.length; i++) {
        if (table[i][pivotCol] > 1e-10) {
          double ratio = table[i][table[i].length - 1] / table[i][pivotCol];
          if (ratio < minRatio - 1e-10) {
            minRatio = ratio;
            pivotRow = i;
          }
        }
      }

      if (pivotRow == -1) {
        steps.add("Problema no acotado.");
        return TwoPhaseResult(
          isOptimal: false,
          solution: [],
          optimalValue: 0,
          tableaux: tableaux,
          steps: steps,
          message: "El problema es no acotado.",
        );
      }

      steps.add("Variable saliente en fila $pivotRow (ratio: $minRatio)");

      // Realizar pivoteo
      double pivotValue = table[pivotRow][pivotCol];
      for (int j = 0; j < table[pivotRow].length; j++) {
        table[pivotRow][j] /= pivotValue;
      }

      for (int i = 0; i < table.length; i++) {
        if (i != pivotRow) {
          double factor = table[i][pivotCol];
          for (int j = 0; j < table[i].length; j++) {
            table[i][j] -= factor * table[pivotRow][j];
          }
        }
      }

      tableaux.add(_copyTable(table));
      steps.add("Tabla tras pivotar:\n${_tableToString(table)}");
    }

    // Extraer solución
    List<double> solution = List.filled(numVariables, 0.0);
    double optimalValue = table[0][table[0].length - 1];

    for (int j = 0; j < numVariables; j++) {
      int col = 1 + j;
      bool isBasic = false;
      int basicRow = -1;

      for (int i = 1; i < table.length; i++) {
        if ((table[i][col] - 1.0).abs() < 1e-10) {
          bool unique = true;
          for (int k = 1; k < table.length; k++) {
            if (k != i && table[k][col].abs() > 1e-10) {
              unique = false;
              break;
            }
          }
          if (unique) {
            isBasic = true;
            basicRow = i;
            break;
          }
        }
      }

      if (isBasic) {
        solution[j] = table[basicRow][table[basicRow].length - 1];
      }
    }

    return TwoPhaseResult(
      isOptimal: true,
      solution: solution,
      optimalValue: optimalValue,
      tableaux: tableaux,
      steps: steps,
      message: "Solución óptima encontrada.",
    );
  }

  /// Suma dos filas elemento a elemento
  static List<double> _addRows(List<double> a, List<double> b) {
    return List.generate(a.length, (i) => a[i] + b[i]);
  }

  /// Multiplica una fila por un escalar
  static List<double> _multiplyRow(List<double> row, double factor) {
    return row.map((x) => x * factor).toList();
  }

  /// Devuelve una copia de una tabla
  static List<List<double>> _copyTable(List<List<double>> table) {
    return table.map((r) => List<double>.from(r)).toList();
  }

  /// Devuelve una representación en texto de una tabla con encabezados
  static String _tableToString(List<List<double>> table) {
    StringBuffer sb = StringBuffer();
    sb.writeln("Tabla Simplex:");
    sb.writeln("VB | Coefs... | Sol");
    for (var fila in table) {
      sb.writeln(fila.map((v) => v.toStringAsFixed(4)).join("\t"));
    }
    return sb.toString();
  }
}
