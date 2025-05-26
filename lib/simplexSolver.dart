class SimplexSolver {
  static Map<String, dynamic> resolver(List<List<double>> matriz, {bool esMaximizacion = true}) {
    try {
      // Validación mejorada de la matriz
      if (matriz.isEmpty || matriz[0].length < 3 || matriz.length < 2) {
        return {
          'exito': false,
          'mensaje': 'Matriz no válida. Debe tener al menos 1 variable y 1 restricción',
          'matrizFinal': [],
          'iteraciones': [],
          'solucion': {}
        };
      }

      // Verificar consistencia de dimensiones
      int columnasEsperadas = matriz[0].length;
      for (var fila in matriz) {
        if (fila.length != columnasEsperadas) {
          return {
            'exito': false,
            'mensaje': 'Todas las filas deben tener la misma cantidad de columnas',
            'matrizFinal': [],
            'iteraciones': [],
            'solucion': {}
          };
        }
      }

      List<Map<String, dynamic>> iteraciones = [];
      List<List<double>> tabla = _copiarMatriz(matriz);
      int numVariables = matriz[0].length - matriz.length - 1;
      int numRestricciones = matriz.length - 1;

      // Convertir minimización a maximización si es necesario
      if (!esMaximizacion) {
        for (int j = 1; j < tabla[0].length - 1; j++) {
          tabla[0][j] *= -1;
        }
      }

      // Algoritmo simplex
      while (!_esOptima(tabla[0], esMaximizacion)) {
        // Guardar iteración actual
        iteraciones.add({
          'tabla': _copiarMatriz(tabla),
          'pivote': _encontrarPivote(tabla, esMaximizacion),
        });

        int colPivote = _encontrarColumnaPivote(tabla[0], esMaximizacion);
        int filaPivote = _encontrarFilaPivote(tabla, colPivote);

        if (filaPivote == -1) {
          return {
            'exito': false,
            'mensaje': 'Solución no acotada',
            'matrizFinal': tabla,
            'iteraciones': iteraciones,
            'solucion': {}
          };
        }

        _realizarOperacionesPivote(tabla, filaPivote, colPivote);
      }

      // Extraer solución
      Map<String, double> solucion = _extraerSolucion(tabla, numVariables, numRestricciones);
      double zOptimo = tabla[0].last * (esMaximizacion ? 1 : -1);

      return {
        'exito': true,
        'mensaje': 'Solución óptima encontrada: Z = ${zOptimo.toStringAsFixed(2)}',
        'matrizFinal': tabla,
        'solucion': solucion,
        'zOptimo': zOptimo,
        'iteraciones': iteraciones
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error durante el cálculo: ${e.toString()}',
        'matrizFinal': [],
        'iteraciones': [],
        'solucion': {}
      };
    }
  }

  static List<List<double>> _copiarMatriz(List<List<double>> original) {
    return original.map((fila) => List<double>.from(fila)).toList();
  }

  static bool _esOptima(List<double> filaZ, bool esMaximizacion) {
    for (int i = 1; i < filaZ.length - 1; i++) {
      if ((esMaximizacion && filaZ[i] < 0) || (!esMaximizacion && filaZ[i] > 0)) {
        return false;
      }
    }
    return true;
  }

  static int _encontrarColumnaPivote(List<double> filaZ, bool esMaximizacion) {
    int indice = -1;
    double valorExtremo = esMaximizacion ? double.negativeInfinity : double.infinity;

    for (int i = 1; i < filaZ.length - 1; i++) {
      if ((esMaximizacion && filaZ[i] < 0 && filaZ[i] > valorExtremo) ||
          (!esMaximizacion && filaZ[i] > 0 && filaZ[i] < valorExtremo)) {
        valorExtremo = filaZ[i];
        indice = i;
      }
    }

    return indice;
  }

  static int _encontrarFilaPivote(List<List<double>> tabla, int colPivote) {
    int filaPivote = -1;
    double minRatio = double.infinity;

    for (int i = 1; i < tabla.length; i++) {
      if (tabla[i][colPivote] > 0) {
        double ratio = tabla[i].last / tabla[i][colPivote];
        if (ratio < minRatio) {
          minRatio = ratio;
          filaPivote = i;
        }
      }
    }

    return filaPivote;
  }

  static void _realizarOperacionesPivote(List<List<double>> tabla, int filaPivote, int colPivote) {
    // Normalizar fila pivote
    double pivote = tabla[filaPivote][colPivote];
    for (int j = 0; j < tabla[filaPivote].length; j++) {
      tabla[filaPivote][j] /= pivote;
    }

    // Eliminar otros elementos en la columna pivote
    for (int i = 0; i < tabla.length; i++) {
      if (i != filaPivote) {
        double factor = tabla[i][colPivote];
        for (int j = 0; j < tabla[i].length; j++) {
          tabla[i][j] -= factor * tabla[filaPivote][j];
        }
      }
    }
  }

  static Map<String, double> _extraerSolucion(List<List<double>> tabla, int numVariables, int numRestricciones) {
    Map<String, double> solucion = {};

    // Para cada columna (variables de decisión + holgura)
    for (int j = 1; j <= numVariables + numRestricciones; j++) {
      String nombreVar = j <= numVariables ? 'x$j' : 'S${j - numVariables}';
      solucion[nombreVar] = 0.0;

      for (int i = 1; i < tabla.length; i++) {
        if (tabla[i][j] == 1.0) {
          bool esBasica = true;
          for (int k = 0; k < tabla.length; k++) {
            if (k != i && tabla[k][j] != 0.0) {
              esBasica = false;
              break;
            }
          }
          if (esBasica) {
            solucion[nombreVar] = tabla[i].last;
            break;
          }
        }
      }
    }

    return solucion;
  }

  static Map<String, int> _encontrarPivote(List<List<double>> tabla, bool esMaximizacion) {
    int colPivote = _encontrarColumnaPivote(tabla[0], esMaximizacion);
    int filaPivote = _encontrarFilaPivote(tabla, colPivote);
    return {'fila': filaPivote, 'columna': colPivote};
  }
}