import 'package:flutter/material.dart';
import 'metodo_grafico.dart';
import 'metodo_simplex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Programación Lineal',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: const Color(0xFF1B2A41),
        fontFamily: 'Roboto',
      ),
      home: const MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Calculadora de Programación Lineal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccione un método:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.table_chart),
                label: const Text('Método Simplex'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 60),
                  backgroundColor: const Color(0xFF297373),
                  textStyle: const TextStyle(fontSize: 18),
                  shadowColor: Colors.black45,
                  elevation: 6,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimplexScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.show_chart),
                label: const Text('Método Gráfico'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 60),
                  backgroundColor: const Color(0xFF355691),
                  textStyle: const TextStyle(fontSize: 18),
                  shadowColor: Colors.black45,
                  elevation: 6,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GraphicMethodScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}