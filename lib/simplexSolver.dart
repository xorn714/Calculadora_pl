class SimplexSolver {
  static Map<String, dynamic> resolver(List<List<double>> matriz) {
    try {
      // Validar la matriz
      if (matriz.isEmpty || matriz[0].length < 3) {
        return {
          'exito': false,
          'mensaje': 'Matriz no válida',
          'matrizFinal': [],
          'iteraciones': []
        };
      }

      List<Map<String, dynamic>> iteraciones = [];
      List<List<double>> tabla = _convertirMatriz(matriz);
      int numVariables = matriz[0].length - 2;
      int numRestricciones = matriz.length - 1;

      // Paso 1: Verificar si ya es solución óptima
      while (!_esOptima(tabla[0])) {
        // Guardar estado actual para las iteraciones
        iteraciones.add({
          'tabla': _copiarTabla(tabla),
          'pivote': _encontrarPivote(tabla),
        });

        // Paso 2: Encontrar columna pivote (variable entrante)
        int colPivote = _encontrarColumnaPivote(tabla[0]);

        // Paso 3: Encontrar fila pivote (variable saliente)
        int filaPivote = _encontrarFilaPivote(tabla, colPivote);

        if (filaPivote == -1) {
          return {
            'exito': false,
            'mensaje': 'Solución no acotada',
            'matrizFinal': tabla,
            'iteraciones': iteraciones
          };
        }

        // Paso 4: Realizar operaciones de fila para hacer el pivote 1 y otros en columna 0
        _realizarOperacionesPivote(tabla, filaPivote, colPivote);
      }

      // Preparar solución
      Map<String, double> solucion =
          _extraerSolucion(tabla, numVariables, numRestricciones);
      double zOptimo = tabla[0].last;

      return {
        'exito': true,
        'mensaje':
            'Solución óptima encontrada: Z = ${zOptimo.toStringAsFixed(2)}',
        'matrizFinal': tabla,
        'solucion': solucion,
        'zOptimo': zOptimo,
        'iteraciones': iteraciones
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error durante el cálculo: $e',
        'matrizFinal': [],
        'iteraciones': []
      };
    }
  }

  static List<List<double>> _convertirMatriz(
      List<List<double>> matrizOriginal) {
    // Convertir la matriz de entrada al formato estándar para el algoritmo simplex
    List<List<double>> nuevaMatriz = [];
    for (var fila in matrizOriginal) {
      nuevaMatriz.add(List.from(fila));
    }
    return nuevaMatriz;
  }

  static bool _esOptima(List<double> filaZ) {
    // Verificar si todos los coeficientes en la fila Z son no negativos (para maximización)
    for (int i = 1; i < filaZ.length - 1; i++) {
      if (filaZ[i] < 0) {
        return false;
      }
    }
    return true;
  }

  static int _encontrarColumnaPivote(List<double> filaZ) {
    // Encontrar el índice del valor más negativo en la fila Z (para maximización)
    double minValor = 0;
    int indice = -1;

    for (int i = 1; i < filaZ.length - 1; i++) {
      if (filaZ[i] < minValor) {
        minValor = filaZ[i];
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

  static void _realizarOperacionesPivote(
      List<List<double>> tabla, int filaPivote, int colPivote) {
    // Hacer el elemento pivote igual a 1
    double pivote = tabla[filaPivote][colPivote];
    for (int j = 0; j < tabla[filaPivote].length; j++) {
      tabla[filaPivote][j] /= pivote;
    }

    // Hacer otros elementos en la columna pivote igual a 0
    for (int i = 0; i < tabla.length; i++) {
      if (i != filaPivote && tabla[i][colPivote] != 0) {
        double factor = tabla[i][colPivote];
        for (int j = 0; j < tabla[i].length; j++) {
          tabla[i][j] -= factor * tabla[filaPivote][j];
        }
      }
    }
  }

  static Map<String, double> _extraerSolucion(
      List<List<double>> tabla, int numVariables, int numRestricciones) {
    Map<String, double> solucion = {};

    // Para cada variable de decisión
    for (int j = 1; j <= numVariables; j++) {
      bool esBasica = false;
      int filaBasica = -1;

      // Verificar si es variable básica
      for (int i = 1; i < tabla.length; i++) {
        if (tabla[i][j] == 1) {
          // Verificar si es la única 1 en la columna
          bool unicoUno = true;
          for (int k = 0; k < tabla.length; k++) {
            if (k != i && tabla[k][j] != 0) {
              unicoUno = false;
              break;
            }
          }

          if (unicoUno) {
            esBasica = true;
            filaBasica = i;
            break;
          }
        }
      }

      if (esBasica) {
        solucion['x$j'] = tabla[filaBasica].last;
      } else {
        solucion['x$j'] = 0;
      }
    }
    for (int j = 1; j <= numRestricciones; j++) {
      bool esBasica = false;
      int filaBasica = -1;

      // Verificar si es variable básica
      for (int i = 1; i < tabla.length; i++) {
        if (tabla[i][j] == 1) {
          // Verificar si es la única 1 en la columna
          bool unicoUno = true;
          for (int k = 0; k < tabla.length; k++) {
            if (k != i && tabla[k][j] != 0) {
              unicoUno = false;
              break;
            }
          }

          if (unicoUno) {
            esBasica = true;
            filaBasica = i;
            break;
          }
        }
      }

      if (esBasica) {
        solucion['S$j'] = tabla[filaBasica].last;
      } else {
        solucion['S$j'] = 0;
      }
    }

    return solucion;
  }

  static List<List<double>> _copiarTabla(List<List<double>> tabla) {
    return tabla.map((fila) => List<double>.from(fila)).toList();
  }

  // Devuelve la posición del pivote actual como un mapa {'fila': int, 'columna': int}
  static Map<String, int> _encontrarPivote(List<List<double>> tabla) {
    int colPivote = _encontrarColumnaPivote(tabla[0]);
    int filaPivote = _encontrarFilaPivote(tabla, colPivote);
    return {'fila': filaPivote, 'columna': colPivote};
  }
}
