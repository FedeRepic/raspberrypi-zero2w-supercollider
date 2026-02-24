# Instalación de mi-UGens (MiPlaits) en Raspberry Pi Zero 2 W

**Fecha:** 24 de febrero de 2026  
**Sistema:** Raspberry Pi Zero 2 W - Debian GNU/Linux 12 (Bookworm) aarch64  
**SuperCollider:** 3.14.1 (headless)

---

## Resumen

Se instaló exitosamente **mi-UGens**, una colección de UGens basados en módulos eurorack de Mutable Instruments, incluyendo **MiPlaits** (macro-oscillator basado en el módulo Plaits).

---

## Proceso de Instalación

### 1. Clonación del Repositorio

```bash
cd /home/flsr
git clone --recurse-submodules https://github.com/v7b1/mi-UGens.git
```

**Resultado:** Repositorio clonado con todos los submódulos (incluye libsamplerate)

---

### 2. Configuración con CMake

```bash
cd mi-UGens
mkdir build && cd build
cmake .. -DSC_PATH=/home/flsr/supercollider -DCMAKE_BUILD_TYPE=Release
```

**Configuración exitosa:**
- Compiler: GCC 12.2.0
- Build type: Release
- Install directory: `/home/flsr/mi-UGens/build/mi-UGens`

---

### 3. Compilación

```bash
make
```

**Tiempo de compilación:** ~5-7 minutos en RPi Zero 2 W

**Módulos compilados exitosamente:**
- MiBraids (macro-oscillator)
- MiClouds (granular processor)
- MiElements (physical modeling)
- MiGrids (drum sequencer)
- MiMu (compander)
- MiOmi (FM synth)
- **MiPlaits (macro-oscillator)** ✓
- MiRings (resonator)
- MiRipples (filter)
- MiTides (LFO/envelope)
- MiVerb (reverb)
- MiWarps (wavefolder)

---

### 4. Instalación

```bash
make install
sudo cp -r /home/flsr/mi-UGens/build/mi-UGens /usr/local/share/SuperCollider/Extensions/
```

**Archivos instalados:**
- Plugins (`.so`): 12 módulos
- Classes (`.sc`): 12 archivos de clase SuperCollider
- HelpSource (`.schelp`): Documentación para cada módulo

---

## Verificación y Pruebas

### Test 1: Oscilador Básico (Engine 0 - Virtual Analog)

**Archivo:** `/home/flsr/test_miplaits.scd`

```supercollider
s.waitForBoot {
    ~test = {
        var sig = MiPlaits.ar(
            pitch: 48,
            engine: 0,
            harm: 0.5,
            timbre: 0.5,
            morph: 0.3,
            mul: 0.3
        );
        sig[0].dup;
    }.play;
};
```

**Resultado:** ✅ MiPlaits cargado correctamente, audio generado sin errores

---

### Test 2: FM con Timbre Modulado (Engine 2)

**Archivo:** `/home/flsr/miplaits_ex_fm.scd`

```supercollider
s.waitForBoot {
    ~x = {
        var sig = MiPlaits.ar(
            pitch: 60,
            engine: 2,
            harm: 0.3,
            timbre: SinOsc.kr(0.1).range(0.2, 0.8),
            morph: 0.5,
            mul: 0.3
        );
        sig[0].dup;
    }.play;
};
```

**Resultado:** ✅ Síntesis FM funcionando correctamente con modulación de timbre

---

## Configuración de Autostart

### Archivo de Autostart Actualizado

**Ubicación:** `/home/flsr/mycode.scd`

```supercollider
// MiPlaits FM - Autostart (infinito)
s.waitForBoot {
    "[MiPlaits FM Autostart] Servidor iniciado correctamente".postln;
    
    // Engine 2 = FM con timbre modulado
    ~plaits = {
        var sig = MiPlaits.ar(
            pitch: 60,
            engine: 2,
            harm: 0.3,
            timbre: SinOsc.kr(0.1).range(0.2, 0.8),
            morph: 0.5,
            mul: 0.3
        );
        sig[0].dup;
    }.play;
    
    "[MiPlaits FM] Reproduciendo continuamente...".postln;
};
```

### Configuración de Crontab

```bash
crontab -l
# Output: @reboot ~/autostart.sh
```

**Script de autostart:** `/home/flsr/autostart.sh`

```bash
#!/bin/bash
export PATH=/usr/local/bin:$PATH
export QT_QPA_PLATFORM=offscreen
export JACK_NO_AUDIO_RESERVATION=1
sleep 10
sclang ~/mycode.scd
```

**Comportamiento:** Al reiniciar la Raspberry Pi, MiPlaits FM inicia automáticamente y se reproduce de forma continua.

---

## Engines Disponibles en MiPlaits

MiPlaits incluye 16 engines de síntesis diferentes:

| Engine | Nombre | Descripción |
|--------|--------|-------------|
| 0 | Virtual Analog | Osciladores virtuales analógicos |
| 1 | Waveshaping | Síntesis por conformación de onda |
| 2 | FM | Síntesis de modulación de frecuencia |
| 3 | Grain | Síntesis granular |
| 4 | Additive | Síntesis aditiva |
| 5 | Wavetable | Osciladores de tabla de ondas |
| 6 | Chord | Generador de acordes |
| 7 | Speech | Síntesis de voz |
| 8 | Swarm | Enjambre de osciladores |
| 9 | Noise | Generadores de ruido |
| 10 | Particle | Síntesis de partículas |
| 11 | String | Modelos de cuerdas |
| 12 | Modal | Resonadores modales |
| 13 | Bass Drum | Bombo sintetizado |
| 14 | Snare Drum | Redoblante sintetizado |
| 15 | Hi-Hat | Charleston sintetizado |

---

## Parámetros Principales de MiPlaits

```supercollider
MiPlaits.ar(
    pitch: 48,          // Altura tonal (MIDI note)
    engine: 0,          // Selección de engine (0-15)
    harm: 0.5,          // Harmonics/timbre parameter
    timbre: 0.5,        // Timbre/color tonal
    morph: 0.5,         // Morphing parameter
    trigger: 0,         // Trigger input
    level: 0.8,         // Level control
    decay: 0.5,         // Decay time (envelope)
    mul: 0.3            // Output amplitude
)
```

---

## Comandos Útiles

### Detener SuperCollider (sin reiniciar)

```bash
killall sclang scsynth jackd
```

### Ver procesos de audio activos

```bash
ps aux | grep -E "sclang|scsynth|jackd"
```

### Verificar estado de JACK

```bash
pgrep -x jackd && echo "JACK RUNNING" || echo "JACK NOT RUNNING"
```

### Ver extensiones instaladas

```bash
ls -la /usr/local/share/SuperCollider/Extensions/
```

---

## Estado del Sistema

### Audio
- **JACK:** Activo (PID: 599)
- **Sample Rate:** 48000 Hz
- **Block Size:** 512 samples (~10.7ms latency)
- **Audio Interface:** Expert Sleepers ES-9 (hw:0)

### Rendimiento
- **CPU Mode:** Performance (1000 MHz)
- **MiPlaits CPU Usage:** ~15-20% (engine 2, FM)
- **RAM Usage:** Estable durante operación continua

---

## Archivos Creados

```
/home/flsr/
├── mi-UGens/                    # Repositorio clonado
│   └── build/
│       └── mi-UGens/            # Plugins compilados
├── test_miplaits.scd            # Test básico (engine 0)
├── miplaits_ex_fm.scd           # Test FM (engine 2, 12s)
└── mycode.scd                   # Autostart FM (infinito)

/usr/local/share/SuperCollider/Extensions/
└── mi-UGens/
    ├── MiPlaits.so              # Plugin compilado
    ├── Classes/MiPlaits.sc      # Clase SuperCollider
    └── HelpSource/Classes/MiPlaits.schelp
```

---

## Referencias

- **mi-UGens Repository:** https://github.com/v7b1/mi-UGens
- **Mutable Instruments:** https://github.com/pichenettes/eurorack
- **Autor:** Volker Böhm (https://vboehm.net)
- **Plaits Original:** Émilie Gillet (Mutable Instruments)

---

## Próximos Pasos Sugeridos

1. **Explorar otros engines:** Probar los 16 engines disponibles
2. **MIDI Control:** Configurar control MIDI externo
3. **Patterns:** Crear secuencias usando Pbind y Pdef
4. **Efectos:** Combinar con MiVerb, MiRipples, MiClouds
5. **Modular setup:** Integrar con otros módulos mi-UGens

---

## Notas

- La compilación de mi-UGens en RPi Zero 2 W toma aproximadamente 5-7 minutos
- MiPlaits requiere SuperCollider 3.10 o superior
- Todos los módulos mi-UGens están ahora disponibles en el sistema
- El autostart está configurado para ejecutar engine 2 (FM) continuamente

**Estado Final:** ✅ **Instalación completada exitosamente**
