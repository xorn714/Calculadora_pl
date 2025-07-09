import 'package:flutter/material.dart';
import 'dos_fases_solver.dart';

class SolucionDosFasesScreen extends StatelessWidget {
  final TwoPhaseResult result;

  const SolucionDosFasesScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solución Método Dos Fases'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 16.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Alineación izquierda
                  children: [
                    const Text(
                      'Solución por Método Dos Fases:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      result.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Valor óptimo: ${result.optimalValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Solución: ${result.solution.map((x) => x.toStringAsFixed(2)).join(', ')}',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Pasos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    // Mostrar pasos y tablas
                    ..._buildStepsWithTables(result.steps),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepsWithTables(List<String> steps) {
    List<Widget> widgets = [];
    List<String> currentTable = [];
    bool isBuildingTable = false;

    for (String step in steps) {
      if (step.contains("|")) {
        if (!isBuildingTable) {
          if (currentTable.isNotEmpty) {
            widgets.add(_buildDataTable(currentTable));
            currentTable = [];
          }
          isBuildingTable = true;
        }
        currentTable.add(step);
      } else {
        if (isBuildingTable) {
          if (currentTable.isNotEmpty) {
            widgets.add(_buildDataTable(currentTable));
            currentTable = [];
          }
          isBuildingTable = false;
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              step,
              style: const TextStyle(color: Colors.black),
            ),
          )
        );
      }
    }

    if (currentTable.isNotEmpty) {
      widgets.add(_buildDataTable(currentTable));
    }

    return widgets;
  }

  Widget _buildDataTable(List<String> tableData) {
    if (tableData.isEmpty) return const SizedBox();

    List<String> headers = tableData.first.split("|").map((e) => e.trim()).toList();
    headers = headers.sublist(1);

    List<List<String>> rows = [];
    for (String row in tableData) {
      List<String> cells = row.split("|").map((e) => e.trim()).toList();
      String rowLabel = cells[0];
      List<String> rowData = cells.sublist(1);
      rows.add([rowLabel, ...rowData]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            dataRowMinHeight: 20,
            dataRowMaxHeight: 30,
            columns: [
              const DataColumn(
                label: Text('Fila', 
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )
                ),
              ),
              ...headers.map((header) => DataColumn(
                label: Text(header,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )
                ),
              )),
            ],
            rows: rows.map((row) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    row[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: row[0] == "Z" ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black
                    ),
                  )),
                  ...row.sublist(1).map((cell) => DataCell(Text(
                    cell,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: row[0] == "Z" ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black
                    ),
                  ))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}