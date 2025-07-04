import 'package:flutter/material.dart';
import 'package:calculadora_pl/metodo_simplex/solucion_simplex_screen.dart'; // Make sure this import path is correct based on your project structure

class SimplexScreen extends StatefulWidget {
  const SimplexScreen({super.key});

  @override
  State<SimplexScreen> createState() => _SimplexScreenState();
}

class _SimplexScreenState extends State<SimplexScreen> {
  // Controllers for the number of variables and restrictions
  final TextEditingController _numVariablesController = TextEditingController();
  final TextEditingController _numRestrictionsController = TextEditingController();

  // State variables to hold the parsed number of variables and restrictions
  int _numVariables = 0;
  int _numRestrictions = 0;

  // Lists of controllers for dynamically generated input fields
  // Objective function coefficients (Max Z)
  List<TextEditingController> _objectiveFunctionControllers = [];
  // Constraint coefficients (S.A.) and right-hand side values
  List<List<TextEditingController>> _constraintControllers = [];
  List<TextEditingController> _rhsControllers = []; // Right-hand side values for constraints

  @override
  void initState() {
    super.initState();
    // Set default values for variables and restrictions to 2
    _numVariablesController.text = '2';
    _numRestrictionsController.text = '2';
    // Initialize the UI with default values
    _updateMatrixSize();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _numVariablesController.dispose();
    _numRestrictionsController.dispose();
    _disposeDynamicControllers();
    super.dispose();
  }

  // Helper to dispose dynamically created controllers
  void _disposeDynamicControllers() {
    for (var controller in _objectiveFunctionControllers) {
      controller.dispose();
    }
    for (var row in _constraintControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var controller in _rhsControllers) {
      controller.dispose();
    }
    _objectiveFunctionControllers.clear();
    _constraintControllers.clear();
    _rhsControllers.clear();
  }

  // Function to update the number of variables and restrictions
  void _updateMatrixSize() {
    setState(() {
      _disposeDynamicControllers(); // Dispose old controllers before creating new ones

      _numVariables = int.tryParse(_numVariablesController.text) ?? 0;
      _numRestrictions = int.tryParse(_numRestrictionsController.text) ?? 0;

      // Initialize objective function controllers
      _objectiveFunctionControllers = List.generate(
        _numVariables,
        (index) => TextEditingController(),
      );

      // Initialize constraint controllers and RHS controllers
      _constraintControllers = List.generate(
        _numRestrictions,
        (i) => List.generate(
          _numVariables,
          (j) => TextEditingController(),
        ),
      );
      _rhsControllers = List.generate(
        _numRestrictions,
        (index) => TextEditingController(),
      );
    });
  }

  // Function to parse input and navigate
  void _generateSolution() {
    List<double> objectiveFunctionCoefficients = [];
    List<List<double>> constraintCoefficients = [];
    List<double> rhsValues = [];

    // Parse Objective Function Coefficients
    for (var controller in _objectiveFunctionControllers) {
      final value = double.tryParse(controller.text);
      if (value == null) {
        _showSnackBar('Por favor, ingrese valores numéricos válidos para la función objetivo.');
        return;
      }
      objectiveFunctionCoefficients.add(value);
    }

    // Parse Constraint Coefficients
    for (int i = 0; i < _numRestrictions; i++) {
      List<double> rowCoefficients = [];
      for (int j = 0; j < _numVariables; j++) {
        final value = double.tryParse(_constraintControllers[i][j].text);
        if (value == null) {
          _showSnackBar('Por favor, ingrese valores numéricos válidos para las restricciones.');
          return;
        }
        rowCoefficients.add(value);
      }
      constraintCoefficients.add(rowCoefficients);
    }

    // Parse RHS Values
    for (var controller in _rhsControllers) {
      final value = double.tryParse(controller.text);
      if (value == null) {
        _showSnackBar('Por favor, ingrese valores numéricos válidos para el lado derecho de las restricciones.');
        return;
      }
      rhsValues.add(value);
    }

    // Navigate to the SolucionSimplexScreen with the parsed data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolucionSimplexScreen(
          objectiveFunctionCoefficients: objectiveFunctionCoefficients,
          constraintCoefficients: constraintCoefficients,
          rhsValues: rhsValues,
        ),
      ),
    );
  }

  // Helper function to show a SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método Simplex'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center( // Center the container
        child: Padding( // Add padding around the white container
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox( // Constrain the size of the white container
            constraints: const BoxConstraints(maxWidth: 600), // Max width for the container
            child: Container(
              // Changed to BoxDecoration for rounded corners
              decoration: BoxDecoration(
                color: Colors.white, // Set the background color to white
                borderRadius: BorderRadius.circular(25.0), // Rounded corners
              ),
              padding: const EdgeInsets.all(16.0), // Padding inside the white container
              child: SingleChildScrollView( // Use SingleChildScrollView for scrollability
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section for entering number of variables and restrictions
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numVariablesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black), // Text color black
                            decoration: const InputDecoration(
                              labelText: 'Cantidad de Variables',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelStyle: TextStyle(color: Colors.black), // Label color black
                            ),
                            onSubmitted: (_) => _updateMatrixSize(), // Update on submission
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _numRestrictionsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black), // Text color black
                            decoration: const InputDecoration(
                              labelText: 'Cantidad de Restricciones',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              labelStyle: TextStyle(color: Colors.black), // Label color black
                            ),
                            onSubmitted: (_) => _updateMatrixSize(), // Update on submission
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _updateMatrixSize,
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Section for Objective Function (Max Z)
                    if (_numVariables > 0) ...[
                      Row( // Changed Column to Row for "Maximizar Z" section
                        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                        children: [
                          const Text(
                            'Maximizar Z:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(width: 8), // Add some spacing between text and inputs
                          Expanded( // Use Expanded to allow Wrap to take available space
                            child: Wrap( // Use Wrap to allow items to flow to the next line if needed
                              spacing: 8.0, // Horizontal spacing
                              runSpacing: 4.0, // Vertical spacing
                              children: List.generate(_numVariables, (index) {
                                return SizedBox(
                                  width: 70, // Adjust width as needed for inputs
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _objectiveFunctionControllers[index],
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: Colors.black), // Text color black for inputs
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      // Display X without subscript
                                      Text(' X${index + 1}', style: const TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Section for Constraints (S.A.)
                    if (_numRestrictions > 0) ...[
                      const Text(
                        'S.A.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_numRestrictions, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: List.generate(_numVariables, (j) {
                                      return SizedBox(
                                        width: 70, // Adjust width as needed
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _constraintControllers[i][j],
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(color: Colors.black), // Text color black for inputs
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                ),
                                              ),
                                            ),
                                            // Display X without subscript and plus sign
                                            Text(' X${j + 1} ${j < _numVariables - 1 ? '+' : ''}', style: const TextStyle(color: Colors.black)),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 4), // Reduced spacing
                                const Text('≤', style: TextStyle(color: Colors.black)), // Inequality sign
                                const SizedBox(width: 4), // Reduced spacing
                                SizedBox(
                                  width: 80, // Width for the RHS input
                                  child: TextField(
                                    controller: _rhsControllers[i],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.black), // Text color black for inputs
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _generateSolution, // Call the new _generateSolution function
                        child: const Text('Generar'),
                      ),
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
