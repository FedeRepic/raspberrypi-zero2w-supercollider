# Control OSC de MiPlaits desde Mac a Raspberry Pi

**Fecha:** 24 de febrero de 2026  
**Setup:** Mac (cliente OSC) → Raspberry Pi Zero 2 W (servidor OSC con MiPlaits)

---

## Resumen

Configuración de control OSC bidireccional entre un Mac y la Raspberry Pi Zero 2 W corriendo SuperCollider con MiPlaits. Permite controlar parámetros del sintetizador en tiempo real desde el Mac.

---

## Arquitectura

```
┌─────────────────┐                          ┌──────────────────────────┐
│  Mac (Cliente)  │    OSC Messages          │  Raspberry Pi (Servidor) │
│  SuperCollider  │ ───────────────────────> │  SuperCollider + MiPlaits│
│  Port: Any      │  raspberrypi.local:57120 │  Port: 57120             │
└─────────────────┘                          └──────────────────────────┘
```

---

## Configuración del Mac (Cliente OSC)

### Archivo de Startup

**Ubicación:** `~/.config/SuperCollider/startup.scd`

```supercollider
// SuperCollider Startup Configuration
// Auto-load OSC client for Raspberry Pi control

"[Startup] Loading OSC client configuration...".postln;

// Configure OSC client to Raspberry Pi
// SuperCollider por defecto escucha en el puerto 57120
~raspi = NetAddr("raspberrypi.local", 57120);

// Helper function to send parameters
~sendParam = { |name, value|
    ~raspi.sendMsg('/sc/param', name, value);
    "[OSC] Sent: % = %".format(name, value).postln;
};

// Test connection function
~testConnection = {
    ~raspi.sendMsg('/sc/test', "Hello from Mac!");
    "[OSC] Test message sent to raspberrypi.local:57120".postln;
};

"[Startup] OSC client configured successfully!".postln;
"[Startup] Available commands:".postln;
"  ~sendParam(\\pitch, 60)     - Send parameter to Raspberry Pi".postln;
"  ~testConnection()           - Test OSC connection".postln;
"  ~raspi                      - NetAddr object".postln;
"".postln;
"[Info] Raspberry Pi listening on port 57120 (SC default)".postln;
```

### Uso desde el Mac

```supercollider
// Test de conexión
~testConnection();

// Enviar parámetros individuales
~sendParam(\pitch, 72);      // Cambiar pitch a C5 (72 MIDI)
~sendParam(\harm, 0.7);       // Cambiar harmonics
~sendParam(\timbre, 0.3);     // Cambiar timbre
~sendParam(\morph, 0.8);      // Cambiar morph

// Envío directo (alternativa)
~raspi.sendMsg('/sc/param', 'pitch', 48);
```

---

## Configuración de la Raspberry Pi (Servidor OSC)

### Archivo de Autostart con OSC

**Ubicación:** `/home/flsr/mycode.scd`

```supercollider
// MiPlaits FM - Autostart con OSC Control
s.waitForBoot {
    "[MiPlaits] Servidor iniciado correctamente".postln;
    
    // Variables controlables por OSC
    ~pitch = 60;
    ~harm = 0.3;
    ~timbre = 0.5;
    ~morph = 0.5;
    
    // Engine 2 = FM con parámetros controlables
    ~plaits = {
        var sig = MiPlaits.ar(
            pitch: \pitch.kr(~pitch),
            engine: 2,
            harm: \harm.kr(~harm),
            timbre: \timbre.kr(~timbre),
            morph: \morph.kr(~morph),
            mul: 0.3
        );
        sig[0].dup;
    }.play;
    
    // OSC Responder para recibir parámetros desde el Mac
    OSCdef(\paramReceiver, { |msg|
        var paramName = msg[1];
        var paramValue = msg[2];
        
        "[OSC] Received: % = %".format(paramName, paramValue).postln;
        
        // Actualizar el sintetizador según el parámetro
        case
        { paramName == 'pitch' } {
            ~plaits.set(\pitch, paramValue);
            ~pitch = paramValue;
        }
        { paramName == 'harm' } {
            ~plaits.set(\harm, paramValue);
            ~harm = paramValue;
        }
        { paramName == 'timbre' } {
            ~plaits.set(\timbre, paramValue);
            ~timbre = paramValue;
        }
        { paramName == 'morph' } {
            ~plaits.set(\morph, paramValue);
            ~morph = paramValue;
        };
    }, '/sc/param');
    
    // Test responder
    OSCdef(\testReceiver, { |msg|
        "[OSC] Test message received: %".format(msg[1]).postln;
    }, '/sc/test');
    
    "[MiPlaits] OSC listening on port 57120".postln;
    "[MiPlaits] Reproduciendo continuamente...".postln;
    "[MiPlaits] Controllable params: pitch (%), harm (%), timbre (%), morph (%)".format(
        ~pitch, ~harm, ~timbre, ~morph
    ).postln;
};
```

---

## Parámetros Controlables

| Parámetro | Rango | Descripción |
|-----------|-------|-------------|
| `pitch` | 0-127 | Nota MIDI (60 = C4, 72 = C5) |
| `harm` | 0.0-1.0 | Harmonics/armónicos |
| `timbre` | 0.0-1.0 | Color tonal/timbre |
| `morph` | 0.0-1.0 | Morphing entre variaciones |

---

## Mensajes OSC

### Formato de Mensajes

**Para enviar parámetros:**
```
Address: /sc/param
Args: [paramName (string), paramValue (float)]

Ejemplo: ['/sc/param', 'pitch', 72.0]
```

**Para test de conexión:**
```
Address: /sc/test
Args: [message (string)]

Ejemplo: ['/sc/test', 'Hello from Mac!']
```

---

## Instalación y Setup

### En el Mac

1. **Crear directorio de configuración:**
```bash
mkdir -p ~/.config/SuperCollider
```

2. **Crear archivo startup.scd:**
```bash
nano ~/.config/SuperCollider/startup.scd
# Pegar el contenido del startup configuration
```

3. **Iniciar SuperCollider:**
```bash
sclang
# El startup.scd se carga automáticamente
```

### En la Raspberry Pi

El archivo `mycode.scd` ya está configurado y se ejecuta automáticamente al arrancar la Raspberry Pi mediante el script `autostart.sh` en crontab.

**Para reiniciar manualmente:**
```bash
ssh flsr@raspberrypi.local
killall sclang scsynth jackd
sclang ~/mycode.scd
```

---

## Verificación de Conexión

### Desde el Mac

```supercollider
// 1. Iniciar SuperCollider en el Mac
sclang

// 2. El startup.scd debería cargar automáticamente
// Deberías ver: "[Startup] OSC client configured successfully!"

// 3. Test de conexión
~testConnection();
```

### En la Raspberry Pi

Conectarse por SSH y ver los logs:
```bash
ssh flsr@raspberrypi.local
# Ver si está corriendo
ps aux | grep sclang
```

Si envías `~testConnection()` desde el Mac, deberías ver en los logs de la Raspberry Pi:
```
[OSC] Test message received: Hello from Mac!
```

---

## Troubleshooting

### El Mac no puede conectar

1. **Verificar que la Raspberry Pi está accesible:**
```bash
ping raspberrypi.local
```

2. **Verificar que SuperCollider está corriendo en la Raspberry Pi:**
```bash
ssh flsr@raspberrypi.local "ps aux | grep sclang"
```

3. **Verificar puerto 57120 abierto:**
```bash
ssh flsr@raspberrypi.local "netstat -an | grep 57120"
```

### La Raspberry Pi no responde a mensajes OSC

1. **Verificar que OSCdef está activo:**
Desde la Raspberry Pi (SSH):
```bash
# Ver logs de sclang
journalctl -u cron -f
```

2. **Reiniciar SuperCollider en la Raspberry Pi:**
```bash
killall sclang scsynth jackd
sclang ~/mycode.scd
```

### Latencia alta

La comunicación OSC sobre WiFi puede tener latencia. Para mejores resultados:
- Usar conexión Ethernet si es posible
- Reducir el tráfico de red
- Enviar mensajes solo cuando cambien los valores

---

## Ejemplos de Uso Avanzado

### Secuenciador de Notas

```supercollider
// Desde el Mac - secuencia de notas
(
Routine({
    [60, 64, 67, 72, 67, 64].do { |note|
        ~sendParam(\pitch, note);
        0.5.wait;
    };
}).play;
)
```

### Modulación de Timbre con LFO

```supercollider
// Desde el Mac - modular timbre
(
Routine({
    inf.do {
        var timbre = SinOsc.kr(0.2).range(0.2, 0.8).next;
        ~sendParam(\timbre, timbre);
        0.05.wait;
    };
}).play;
)
```

### Control con GUI

```supercollider
// Desde el Mac - interfaz gráfica simple
(
var w = Window("MiPlaits Control", Rect(100, 100, 400, 300));
var pitchSlider, harmSlider, timbreSlider, morphSlider;

w.view.layout = VLayout(
    StaticText().string_("Pitch (MIDI)"),
    pitchSlider = Slider().value_(60/127).action_({ |sl|
        ~sendParam(\pitch, sl.value * 127);
    }),
    
    StaticText().string_("Harmonics"),
    harmSlider = Slider().value_(0.3).action_({ |sl|
        ~sendParam(\harm, sl.value);
    }),
    
    StaticText().string_("Timbre"),
    timbreSlider = Slider().value_(0.5).action_({ |sl|
        ~sendParam(\timbre, sl.value);
    }),
    
    StaticText().string_("Morph"),
    morphSlider = Slider().value_(0.5).action_({ |sl|
        ~sendParam(\morph, sl.value);
    })
);

w.front;
)
```

---

## Notas Técnicas

- **Puerto por defecto de SuperCollider:** 57120 (UDP)
- **Protocolo:** OSC (Open Sound Control) sobre UDP
- **Red:** WiFi local (raspberrypi.local resuelve vía mDNS/Bonjour)
- **Latencia típica:** 10-30ms en red local WiFi
- **Ancho de banda:** Mínimo (< 1 KB/s para updates típicos)

---

## Próximas Mejoras

1. **Bi-direccional:** Que la Raspberry Pi envíe estado al Mac
2. **Múltiples parámetros:** Enviar varios parámetros en un mensaje
3. **Presets:** Sistema de guardado/carga de presets
4. **MIDI → OSC:** Bridge de MIDI controller a OSC
5. **OSC Learn:** Mapeo automático de controles

---

## Referencias

- **OSC Specification:** http://opensoundcontrol.org/spec-1_0
- **SuperCollider OSC Guide:** https://doc.sccode.org/Guides/OSC_communication.html
- **NetAddr Documentation:** https://doc.sccode.org/Classes/NetAddr.html
- **OSCdef Documentation:** https://doc.sccode.org/Classes/OSCdef.html

---

**Estado:** ✅ Sistema OSC configurado y funcionando
