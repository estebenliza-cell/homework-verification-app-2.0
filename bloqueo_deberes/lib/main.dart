import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MiAppDeberes());
}

class MiAppDeberes extends StatelessWidget {
  const MiAppDeberes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloqueo Deberes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  TimeOfDay? horaBloqueo;
  bool estaBloqueado = false;
  File? fotoTarea;
  final ImagePicker _picker = ImagePicker();

  final String _apiKey =
      'asdowaijdoasjdoadajsndajkdbhaifhoawdoaodjhfoajh';

  bool evaluandoConIA = false;
  String mensajeIA = '';

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (horaSeleccionada != null) {
      setState(() {
        horaBloqueo = horaSeleccionada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Hora programada: ${horaSeleccionada.format(context)}')),
      );
    }
  }

  void _activarBloqueoModoPrueba() {
    setState(() {
      estaBloqueado = true;
      fotoTarea = null;
      mensajeIA = '';
    });
  }

  Future<void> _tomarFotoTarea() async {
    final XFile? imagenTomada =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (imagenTomada != null) {
      setState(() {
        fotoTarea = File(imagenTomada.path);
        mensajeIA = '';
      });
    }
  }

  Future<void> _entregarYDesbloquear() async {
    if (fotoTarea == null) return;

    setState(() {
      evaluandoConIA = true;
      mensajeIA = 'Analizando si la foto es realmente una tarea...';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final bytes = await fotoTarea!.readAsBytes();

      final prompt = TextPart(
          'Analiza esta imagen detenidamente. ¿Corresponde a un cuaderno, libro, guía o hoja con ejercicios o tareas escolares/académicas realizadas a mano o impresas? '
          'Responde strictly comenzando con SI o NO. '
          'Si es SI, explica brevemente qué ves. Si es NO, explica por qué no parece una tarea.');

      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final respuestaTexto = response.text ?? '';

      if (respuestaTexto.toUpperCase().startsWith('SI') ||
          respuestaTexto.toUpperCase().startsWith('SÍ')) {
        setState(() {
          estaBloqueado = false;
          evaluandoConIA = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Tarea verificada por la IA! 🎉\n$respuestaTexto'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          mensajeIA = 'La IA rechazó la foto:\n$respuestaTexto';
          evaluandoConIA = false;
        });
      }
    } catch (e) {
      setState(() {
        mensajeIA = 'Error de conexión con la IA: $e';
        evaluandoConIA = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (estaBloqueado) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.red.shade900,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    '¡TIEMPO DE HACER LA TAREA!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'El teléfono permanecerá bloqueado hasta que envíes una foto de tus deberes terminados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  if (fotoTarea != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        fotoTarea!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  if (evaluandoConIA)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'Evaluando tarea con Gemini AI...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  else if (mensajeIA.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mensajeIA,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.yellowAccent, fontSize: 13),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: evaluandoConIA ? null : _tomarFotoTarea,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(fotoTarea == null
                        ? 'Tomar Foto de la Tarea'
                        : 'Volver a Tomar Foto'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (fotoTarea != null && !evaluandoConIA)
                    ElevatedButton(
                      onPressed: _entregarYDesbloquear,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Entregar Tarea y Desbloquear'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Deberes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.alarm, size: 50, color: Colors.indigo),
                    const SizedBox(height: 10),
                    const Text(
                      'Hora de Bloqueo Programada',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      horaBloqueo == null
                          ? 'Sin programar'
                          : horaBloqueo!.format(context),
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => _seleccionarHora(context),
                      child: const Text('Seleccionar Hora'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _activarBloqueoModoPrueba,
              icon: const Icon(Icons.lock_clock),
              label: const Text('Probar Modo Bloqueo Ahora'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
