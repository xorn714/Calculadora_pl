void resolverMetodoGrafico(Map<String, dynamic> problemData) {
  final isMaximize = problemData['isMaximize'] as bool;

  // Función objetivo
  final objX1 = problemData['objectiveFunction']['x1'] as double;
  final objX2 = problemData['objectiveFunction']['x2'] as double;

  // Restricciones
  final restrictionsRaw = problemData['restrictions'] as List<dynamic>;

  final typedRestrictions = restrictionsRaw
      .map<Map<String, dynamic>>((r) => {
            'x1': (r['x1'] as num?)?.toDouble() ?? 0.0,
            'x2': (r['x2'] as num?)?.toDouble() ?? 0.0,
            'value': (r['value'] as num?)?.toDouble() ?? 0.0,
            'inequality': (r['inequality'] ?? '≤') as String,
          })
      .toList();

  // Generar las rectas (Ax + By = C)
  List<_Recta> rectas = typedRestrictions.map((r) {
    return _Recta(
      a: r['x1'] as double,
      b: r['x2'] as double,
      c: r['value'] as double,
      signo: r['inequality'] as String,
    );
  }).toList();

  // Calcular intersecciones entre TODAS las rectas
  List<_Punto> puntos = [];

  for (int i = 0; i < rectas.length; i++) {
    for (int j = i + 1; j < rectas.length; j++) {
      final interseccion = _intersectarRectas(rectas[i], rectas[j]);
      if (interseccion != null) {
        puntos.add(interseccion);
      }
    }
  }

  // Además, incluir intersección con ejes X1 y X2 ≥ 0
  puntos.addAll(_interseccionesConEjes(rectas));

  // Filtrar solo puntos en la región factible
  List<_Punto> puntosFactibles = puntos.where((p) {
    return _cumpleTodasLasRestricciones(p, rectas);
  }).toList();

  if (puntosFactibles.isEmpty) {
    problemData['solution'] = {
      'message': 'No existe región factible.',
    };
    return;
  }

// Evaluar la función objetivo en todos los puntos factibles
  List<Map<String, double>> evaluaciones = puntosFactibles.map((p) {
    final z = objX1 * p.x + objX2 * p.y;
    return {
      'x1': p.x,
      'x2': p.y,
      'z': z,
    };
  }).toList();

// Encontrar el óptimo
  Map<String, double> optimo;

  if (isMaximize) {
    optimo = evaluaciones.reduce((a, b) => (a['z']! > b['z']!) ? a : b);
  } else {
    optimo = evaluaciones.reduce((a, b) => (a['z']! < b['z']!) ? a : b);
  }

  problemData['solution'] = {
    'optimalPoint': {
      'x1': optimo['x1'],
      'x2': optimo['x2'],
    },
    'optimalValue': optimo['z'],
    'evaluations': evaluaciones,
  };
}

// Representación de una recta Ax + By = C
class _Recta {
  final double a;
  final double b;
  final double c;
  final String signo;

  _Recta({
    required this.a,
    required this.b,
    required this.c,
    required this.signo,
  });
}

// Punto en el plano
class _Punto {
  final double x;
  final double y;

  _Punto(this.x, this.y);
}

/// Intersección de dos rectas.
/// Devuelve null si son paralelas.
_Punto? _intersectarRectas(_Recta r1, _Recta r2) {
  final det = r1.a * r2.b - r2.a * r1.b;

  if (det == 0) {
    // Rectas paralelas
    return null;
  }

  final x = (r1.c * r2.b - r2.c * r1.b) / det;
  final y = (r1.a * r2.c - r2.a * r1.c) / det;

  return _Punto(x, y);
}

/// Devuelve intersecciones de cada recta con los ejes:
/// - intersección con X1 (cuando X2 = 0)
/// - intersección con X2 (cuando X1 = 0)
List<_Punto> _interseccionesConEjes(List<_Recta> rectas) {
  List<_Punto> puntos = [];

  for (final r in rectas) {
    // x-intercepto (x cuando y=0)
    if (r.a != 0) {
      final x = r.c / r.a;
      if (x >= 0) {
        puntos.add(_Punto(x, 0));
      }
    }
    // y-intercepto (y cuando x=0)
    if (r.b != 0) {
      final y = r.c / r.b;
      if (y >= 0) {
        puntos.add(_Punto(0, y));
      }
    }
  }

  return puntos;
}

/// Verifica si el punto cumple todas las restricciones
bool _cumpleTodasLasRestricciones(_Punto p, List<_Recta> rectas) {
  for (final r in rectas) {
    final valor = r.a * p.x + r.b * p.y;

    bool cumple;

    if (r.signo == '≤') {
      cumple = valor <= r.c + 1e-8;
    } else if (r.signo == '≥') {
      cumple = valor >= r.c - 1e-8;
    } else {
      cumple = (valor - r.c).abs() < 1e-8;
    }

    if (!cumple) return false;
  }

  // X1, X2 >= 0
  if (p.x < -1e-8 || p.y < -1e-8) {
    return false;
  }

  return true;
}
