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

    // Validación inicial
    if (constraints.length != rhs.length ||
        constraints.length != constraintOperators.length) {
      return TwoPhaseResult(
        isOptimal: false,
        solution: [],
        optimalValue: 0,
        tableaux: [],
        steps: steps
          ..add(
              "Error: Número de restricciones no coincide con los términos independientes u operadores"),
        message: "Datos de entrada inconsistentes",
      );
    }

    // Verificar operadores válidos
    final validOperators = ['≤', '≥', '='];
    if (constraintOperators.any((op) => !validOperators.contains(op))) {
      return TwoPhaseResult(
        isOptimal: false,
        solution: [],
        optimalValue: 0,
        tableaux: [],
        steps: steps
          ..add("Error: Operadores de restricción deben ser ≤, ≥ o ="),
        message: "Operadores de restricción no válidos",
      );
    }

    bool isMinimization = objectiveType.toLowerCase() == 'minimizar';
    steps.add(
        "Tipo de problema: ${isMinimization ? 'MINIMIZACIÓN' : 'MAXIMIZACIÓN'}");

    // FASE 1: Configuración
    List<double> originalC = List.from(objectiveCoefficients);
    List<double> cPhase1 = List.filled(objectiveCoefficients.length,
        0.0); // Coeficientes cero para variables originales

    steps.add("\n=== FASE 1 ===");
    steps.add("Construyendo problema auxiliar...");

    int numVariables = cPhase1.length;
    int numConstraints = constraints.length;

    // Identificar restricciones que necesitan variables artificiales
    List<int> artificialVars = [];
    for (int i = 0; i < numConstraints; i++) {
      if (constraintOperators[i] == '≥' || constraintOperators[i] == '=') {
        artificialVars.add(i);
      }
    }

    int numArtificial = artificialVars.length;
    steps.add("Variables artificiales necesarias: $numArtificial");

    // Construir tabla de Fase 1
    List<List<double>> phase1Table = _buildPhase1Table(
      cPhase1,
      constraints,
      rhs,
      constraintOperators,
      numVariables,
      numConstraints,
      artificialVars,
    );

    tableaux.add(_copyTable(phase1Table));
    steps
        .add("Tabla inicial de Fase 1 creada:\n${_tableToString(phase1Table)}");

    // Ejecutar Fase 1
    steps.add("Ejecutando Simplex en Fase 1...");
    TwoPhaseResult phase1Result = _simplex(
      phase1Table,
      numVariables,
      numConstraints,
      numArtificial,
      isPhase1: true,
    );

    tableaux.addAll(phase1Result.tableaux);
    steps.addAll(phase1Result.steps);

    // Verificar factibilidad
    if (phase1Result.optimalValue.abs() > 1e-10) {
      steps.add(
          "¡Problema no factible! Valor objetivo en Fase 1: ${phase1Result.optimalValue.toStringAsFixed(6)}");
      return TwoPhaseResult(
        isOptimal: false,
        solution: [],
        optimalValue: 0,
        tableaux: tableaux,
        steps: steps,
        message: "El problema no tiene solución factible (Fase 1 > 0).",
      );
    }

    steps.add(
        "Fase 1 exitosa. Valor objetivo: ${phase1Result.optimalValue.toStringAsFixed(6)}");

    // FASE 2: Configuración
    steps.add("\n=== FASE 2 ===");
    steps.add("Construyendo tabla para Fase 2...");

    List<List<double>> phase2Table = _buildPhase2Table(
      phase1Result.tableaux.last,
      originalC,
      numVariables,
      numConstraints,
      artificialVars,
      isMinimization,
    );

    tableaux.add(_copyTable(phase2Table));
    steps
        .add("Tabla inicial de Fase 2 creada:\n${_tableToString(phase2Table)}");

    // Ejecutar Fase 2
    steps.add("Ejecutando Simplex en Fase 2...");
    TwoPhaseResult phase2Result = _simplex(
      phase2Table,
      numVariables,
      numConstraints,
      0,
      isPhase1: false,
    );

    tableaux.addAll(phase2Result.tableaux);
    steps.addAll(phase2Result.steps);

    // Procesar resultado final
    double finalOptimal =
        double.parse(phase2Result.optimalValue.toStringAsFixed(10));
    List<double> finalSolution = phase2Result.solution
        .map((v) => v < 1e-10 ? 0.0 : double.parse(v.toStringAsFixed(10)))
        .toList();

    // Verificar solución factible (no negativa)
    if (finalSolution.any((v) => v < -1e-10)) {
      steps.add("¡Solución no factible! Variables con valores negativos");
      return TwoPhaseResult(
        isOptimal: false,
        solution: [],
        optimalValue: 0,
        tableaux: tableaux,
        steps: steps,
        message: "El problema tiene solución no factible (valores negativos).",
      );
    }

    // Ajustar para minimización
    if (isMinimization) {
      finalOptimal = -finalOptimal;
      steps.add(
          "Ajustando valor óptimo para minimización: ${finalOptimal.toStringAsFixed(6)}");
    }

    return TwoPhaseResult(
      isOptimal: phase2Result.isOptimal,
      solution: finalSolution,
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
    // Contar variables de holgura y artificiales
    int totalSlacks =
        constraintOperators.where((op) => op == '≤' || op == '≥').length;
    int totalArtificial = artificialVars.length;

    // Configurar tamaño de la tabla
    int totalCols = 1 + numVariables + totalSlacks + totalArtificial + 1;
    List<List<double>> table = List.generate(
      numConstraints + 1,
      (_) => List.filled(totalCols, 0.0),
    );

    // Configurar función objetivo de Fase 1 (solo variables artificiales)
    table[0][0] = 1.0; // Columna Z
    for (int i = 0; i < totalArtificial; i++) {
      table[0][1 + numVariables + totalSlacks + i] = 1.0;
    }

    // Llenar restricciones
    int slackCount = 0;
    int artificialCount = 0;
    for (int i = 0; i < numConstraints; i++) {
      // Coeficientes de variables originales
      for (int j = 0; j < numVariables; j++) {
        table[i + 1][1 + j] = constraints[i][j];
      }

      // Variables de holgura/artificiales según el tipo de restricción
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

      // Lado derecho
      table[i + 1][totalCols - 1] = rhs[i];
    }

    // Restar las filas de variables artificiales de la función objetivo
    for (int i = 0; i < numConstraints; i++) {
      if (constraintOperators[i] == '≥' || constraintOperators[i] == '=') {
        for (int j = 0; j < totalCols; j++) {
          table[0][j] -= table[i + 1][j];
        }
      }
    }

    return table;
  }

  /// Construye la tabla inicial para la Fase 2
  static List<List<double>> _buildPhase2Table(
    List<List<double>> phase1FinalTable,
    List<double> originalC,
    int numVariables,
    int numConstraints,
    List<int> artificialVars,
    bool isMinimization,
  ) {
    int numArtificial = artificialVars.length;
    // Elimina las columnas de variables artificiales
    List<List<double>> phase2Table = phase1FinalTable
        .map((fila) => fila.sublist(0, fila.length - numArtificial))
        .toList();

    // Configura la función objetivo original
    for (int j = 0; j < numVariables; j++) {
      // Para minimización: mantener coeficientes originales
      // Para maximización: negar coeficientes originales
      phase2Table[0][1 + j] = isMinimization ? originalC[j] : -originalC[j];
    }

    // Restaura la forma canónica de la función objetivo
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

      int pivotCol = -1;
      double minReducedCost = 0.0;

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
        steps.add("No hay columnas entrantes. Óptimo alcanzado.");
        break;
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
        throw Exception("Problema no acotado.");
      }

      steps.add("Variable saliente en fila $pivotRow (ratio: $minRatio)");

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

    List<double> solution = List.filled(numVariables, 0.0);
    double optimalValue = table[0][table[0].length - 1];

    for (int j = 0; j < numVariables; j++) {
      int col = 1 + j;
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
            basicRow = i;
            break;
          }
        }
      }
      if (basicRow != -1) {
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

  static List<double> _addRows(List<double> a, List<double> b) {
    return List.generate(a.length, (i) => a[i] + b[i]);
  }

  static List<List<double>> _copyTable(List<List<double>> table) {
    return table.map((r) => List<double>.from(r)).toList();
  }

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
