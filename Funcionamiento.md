# ¿Cómo funciona la Calculadora de Programación Lineal?

Esta calculadora permite resolver problemas de programación lineal de la forma estándar:

- Maximizar o minimizar una función objetivo lineal
- Sujeta a restricciones lineales (igualdades o desigualdades)
- Variables no negativas

## Métodos implementados

### 1. Método Simplex

- Permite resolver problemas con cualquier cantidad de variables y restricciones.
- El usuario ingresa los coeficientes de la función objetivo y las restricciones.
- El algoritmo transforma el problema a su forma estándar y aplica iteraciones del método Simplex.
- Se muestra la tabla final, el valor óptimo de Z y los valores de las variables.

### 2. Método Gráfico

- Solo para problemas de dos variables.
- El usuario ingresa la función objetivo y las restricciones.
- El sistema calcula todas las intersecciones relevantes y evalúa la función objetivo en los vértices de la región factible.
- Se muestra el punto óptimo y el valor de Z, junto con las evaluaciones en los puntos factibles.

### 3. Método de Dos Fases

- Permite resolver problemas con restricciones de tipo ≤, ≥ o =.
- El usuario puede elegir maximizar o minimizar.
- El método transforma el problema agregando variables de holgura, exceso y artificiales según corresponda.
- Realiza la Fase 1 para encontrar una solución factible y la Fase 2 para optimizar la función objetivo original.
- Se muestran los pasos y las tablas intermedias de cada fase.

## Interfaz

- La aplicación es interactiva y amigable.
- Los campos de entrada se generan dinámicamente según el número de variables y restricciones.
- Los resultados incluyen tanto la solución óptima como los pasos intermedios (tablas simplex, evaluaciones, etc.).

## Notas

- Para el método gráfico, solo se permiten dos variables.
- Para los otros métodos, puedes ingresar cualquier cantidad de variables y restricciones.
- El sistema valida que los datos sean numéricos y muestra mensajes de error si hay algún problema en