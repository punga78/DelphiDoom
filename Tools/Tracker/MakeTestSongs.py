#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Brani di prova per il tracker di DelphiDoom e WAD che li contengono.

Uso:
    python MakeTestSongs.py <cartella-di-uscita>
        scrive i quattro brani sintetici (prova.mod/.s3m/.xm/.it) e i WAD
        TRACKER_DOOM.WAD e TRACKER_HERETIC.WAD
    python MakeTestSongs.py <cartella-di-uscita> brano1 [brano2 brano3 brano4]
        usa i moduli indicati (MOD, S3M, XM, IT) al posto di quelli sintetici

Nei WAD i brani sostituiscono la musica dei livelli 1..4 del primo episodio
(Doom: D_E1M1..D_E1M4; Heretic: MUS_E1M1..MUS_E1M4), nell'ordine in cui sono
indicati; i sintetici sono MOD, S3M, XM, IT.

I moduli sintetici usano quattro strumenti (seno, quadra, dente di sega,
rumore) e gli effetti piu' comuni: arpeggio, vibrato, scorrimento di volume,
taglio della nota e portamento. Servono ad ascoltare i formati e gli effetti;
la qualita' si valuta su brani veri.
"""
import os
import random
import struct
import sys

ROWS = 64
CHANNELS = 4
NOTE_NAMES = {'C-': 0, 'C#': 1, 'D-': 2, 'D#': 3, 'E-': 4, 'F-': 5, 'F#': 6, 'G-': 7, 'G#': 8, 'A-': 9,
              'A#': 10, 'B-': 11}

# periodi di ProTracker: C-1 .. B-3 (le note 37..72 del modello, dove C-4 e' la 49)
MOD_PERIODS = [856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
               428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
               214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113]


def note(name):
    """C-4 e' la nota 49; il nome e' come 'C-4', 'F#3'"""
    return 12 * int(name[2]) + NOTE_NAMES[name[:2]] + 1


# ---------------------------------------------------------------- strumenti

def wave_sine():
    import math
    return [int(100 * math.sin(2 * math.pi * i / 32)) for i in range(32)]


def wave_square():
    return [80] * 16 + [-80] * 16


def wave_saw():
    return [int(-100 + 200 * i / 31) for i in range(32)]


def wave_noise():
    rnd = random.Random(7)
    return [int(rnd.randint(-100, 100) * (1 - i / 400.0)) for i in range(400)]


INSTRUMENTS = [
    ('seno', wave_sine(), True, 48),
    ('quadra', wave_square(), True, 28),
    ('sega', wave_saw(), True, 40),
    ('rumore', wave_noise(), False, 50),
]


# ------------------------------------------------------------------- brano

# effetti comuni, con il codice di ogni formato (MOD, S3M, XM, IT)
ARPEGGIO, VIBRATO, VOLSLIDE, PORTAUP, NOTECUT = range(5)
EFFECT_CODES = {
    'mod': {ARPEGGIO: (0x0, None), VIBRATO: (0x4, None), VOLSLIDE: (0xA, None), PORTAUP: (0x1, None),
            NOTECUT: (0xE, 0xC0)},
    'xm': {ARPEGGIO: (0x0, None), VIBRATO: (0x4, None), VOLSLIDE: (0xA, None), PORTAUP: (0x1, None),
           NOTECUT: (0xE, 0xC0)},
    's3m': {ARPEGGIO: (10, None), VIBRATO: (8, None), VOLSLIDE: (4, None), PORTAUP: (6, None),
            NOTECUT: (19, 0xC0)},
    'it': {ARPEGGIO: (10, None), VIBRATO: (8, None), VOLSLIDE: (4, None), PORTAUP: (6, None),
           NOTECUT: (19, 0xC0)},
}


def build_song():
    """Righe: song[row][channel] = (nota, strumento, volume, effetto, parametro) o None"""
    song = [[None] * CHANNELS for _ in range(ROWS)]
    chords = [(('C-4', 'E-4', 'G-4'), 'C-3', (4, 7), ('E-5', 'G-5')),
              (('A-3', 'C-4', 'E-4'), 'A-3', (3, 7), ('E-5', 'C-5')),
              (('F-3', 'A-3', 'C-4'), 'F-3', (4, 7), ('C-5', 'A-4')),
              (('G-3', 'B-3', 'D-4'), 'G-3', (4, 7), ('D-5', 'B-4'))]
    for index, (chord, bass, offsets, lead) in enumerate(chords):
        start = index * 16
        # pad: il fondamentale con l'arpeggio
        song[start][1] = (note(chord[0]), 2, 28, ARPEGGIO, (offsets[0] << 4) | offsets[1])
        # basso: ogni otto righe, con una dissolvenza
        for part in (0, 8):
            song[start + part][2] = (note(bass), 3, 56, VOLSLIDE, 0x02)
        # melodia: due note per accordo, con il vibrato
        song[start][0] = (note(lead[0]), 1, 56, VIBRATO, 0x46)
        song[start + 8][0] = (note(lead[1]), 1, 56, VIBRATO, 0x46)
        # percussioni
        for beat in range(0, 16, 4):
            if beat % 8 == 0:
                song[start + beat][3] = (note('C-5'), 4, 60, NOTECUT, 0x02)
            else:
                song[start + beat][3] = (note('C-5'), 4, 45, None, 0)
    # un portamento verso l'alto sulla melodia, all'ultima riga
    song[62][0] = (note('G-5'), 1, 56, PORTAUP, 0x08)
    return song


def effect_for(fmt, effect, param):
    if effect is None:
        return 0, 0
    code, high = EFFECT_CODES[fmt][effect]
    if high is not None:
        param = high | (param & 0x0F)
    return code, param


# --------------------------------------------------------------------- MOD

def write_mod(path):
    data = bytearray()
    title = b'DelphiDoom tracker test'
    data += title[:20].ljust(20, b'\0')
    for name, wave, loop, volume in INSTRUMENTS:
        length = len(wave)
        data += name.encode('ascii')[:22].ljust(22, b'\0')
        data += struct.pack('>H', length // 2)
        data += bytes([0, volume])
        if loop:
            data += struct.pack('>HH', 0, length // 2)
        else:
            data += struct.pack('>HH', 0, 1)
    for _ in range(31 - len(INSTRUMENTS)):
        data += b'\0' * 22 + struct.pack('>H', 0) + bytes([0, 0]) + struct.pack('>HH', 0, 1)
    data += bytes([1, 127])
    data += bytes([0]) + bytes(127)
    data += b'M.K.'
    for row in build_song():
        for cell in row:
            if cell is None:
                data += b'\0\0\0\0'
                continue
            n, inst, vol, effect, param = cell
            period = MOD_PERIODS[n - 37]
            code, value = effect_for('mod', effect, param)
            # il volume si imposta con l'effetto C solo se manca un altro effetto
            if effect is None:
                code, value = 0xC, vol
            data += bytes([(inst & 0xF0) | (period >> 8), period & 0xFF, ((inst & 0x0F) << 4) | code, value])
    for name, wave, loop, volume in INSTRUMENTS:
        data += bytes([w & 0xFF for w in wave])
    open(path, 'wb').write(bytes(data))


# --------------------------------------------------------------------- S3M

def write_s3m(path):
    song = build_song()
    out = bytearray(0x60)
    out[0:28] = b'DelphiDoom tracker test'.ljust(28, b'\0')
    out[0x1C] = 0x1A
    out[0x1D] = 16
    struct.pack_into('<HHH', out, 0x20, 2, len(INSTRUMENTS), 1)
    struct.pack_into('<HHH', out, 0x26, 0, 0x1320, 2)
    out[0x2C:0x30] = b'SCRM'
    out[0x30] = 64
    out[0x31] = 6
    out[0x32] = 125
    out[0x33] = 0xB0
    out[0x35] = 0
    channel_settings = bytearray([255] * 32)
    for channel in range(CHANNELS):
        channel_settings[channel] = channel if channel < 2 else 8 + channel
    out[0x40:0x60] = channel_settings
    out += bytes([0, 255])
    pointers_at = len(out)
    out += bytes(2 * len(INSTRUMENTS) + 2)
    while len(out) % 16:
        out.append(0)

    instrument_offsets = []
    data_offsets = []
    # instrument headers first, then the pattern, then the data
    header_size = 0x50
    base = len(out)
    for index in range(len(INSTRUMENTS)):
        instrument_offsets.append(base + index * header_size)
    pattern_offset = base + len(INSTRUMENTS) * header_size
    packed = bytearray()
    for row in song:
        for channel, cell in enumerate(row):
            if cell is None:
                continue
            n, inst, vol, effect, param = cell
            code, value = effect_for('s3m', effect, param)
            flag = channel | 32 | 64
            if effect is not None:
                flag |= 128
            packed.append(flag)
            packed += bytes([(((n - 1) // 12) << 4) | ((n - 1) % 12), inst])
            packed.append(min(vol, 64))
            if effect is not None:
                packed += bytes([code, value])
        packed.append(0)
    pattern = struct.pack('<H', len(packed) + 2) + bytes(packed)
    data_start = pattern_offset + len(pattern)
    while data_start % 16:
        data_start += 1
    cursor = data_start
    for name, wave, loop, volume in INSTRUMENTS:
        data_offsets.append(cursor)
        cursor += len(wave)
        while cursor % 16:
            cursor += 1

    headers = bytearray()
    for index, (name, wave, loop, volume) in enumerate(INSTRUMENTS):
        header = bytearray(header_size)
        header[0] = 1
        header[1:13] = (name + '.raw').encode('ascii')[:12].ljust(12, b'\0')
        header[0x0D] = (data_offsets[index] // 16) >> 16
        struct.pack_into('<H', header, 0x0E, (data_offsets[index] // 16) & 0xFFFF)
        struct.pack_into('<III', header, 0x10, len(wave), 0, len(wave) if loop else 0)
        header[0x1C] = volume
        header[0x1F] = 1 if loop else 0
        struct.pack_into('<I', header, 0x20, 16726)
        header[0x30:0x30 + 28] = name.encode('ascii').ljust(28, b'\0')
        header[0x4C:0x50] = b'SCRS'
        headers += header
    out += headers + pattern
    while len(out) < data_start:
        out.append(0)
    for index, (name, wave, loop, volume) in enumerate(INSTRUMENTS):
        while len(out) < data_offsets[index]:
            out.append(0)
        out += bytes([(w + 128) & 0xFF for w in wave])
    for index, offset in enumerate(instrument_offsets):
        struct.pack_into('<H', out, pointers_at + 2 * index, offset // 16)
    struct.pack_into('<H', out, pointers_at + 2 * len(INSTRUMENTS), pattern_offset // 16)
    open(path, 'wb').write(bytes(out))


# ---------------------------------------------------------------------- XM

def write_xm(path):
    song = build_song()
    out = bytearray()
    out += b'Extended Module: '
    out += b'DelphiDoom tracker test'.ljust(20, b'\0')
    out += bytes([0x1A])
    out += b'MakeTestSongs'.ljust(20, b'\0')
    out += struct.pack('<H', 0x0104)
    header = struct.pack('<HHHHHHHH', 1, 0, CHANNELS, 1, len(INSTRUMENTS), 1, 6, 125) + bytes([0]) + bytes(255)
    out += struct.pack('<I', 4 + len(header)) + header
    packed = bytearray()
    for row in song:
        for cell in row:
            if cell is None:
                packed.append(0x80)
                continue
            n, inst, vol, effect, param = cell
            code, value = effect_for('xm', effect, param)
            packed.append(0x80 | 0x01 | 0x02 | 0x04 | 0x08 | 0x10)
            packed += bytes([n, inst, 0x10 + min(vol, 64), code, value])
    out += struct.pack('<IBHH', 9, 0, ROWS, len(packed)) + bytes(packed)
    for name, wave, loop, volume in INSTRUMENTS:
        envelope = bytearray(48)
        struct.pack_into('<HHHH', envelope, 0, 0, 64, 20, 48)
        head = bytearray(263)
        struct.pack_into('<I', head, 0, 263)
        head[4:26] = name.encode('ascii').ljust(22, b'\0')
        struct.pack_into('<H', head, 27, 1)
        struct.pack_into('<I', head, 29, 40)
        head[129:177] = bytes(envelope)
        head[225] = 2
        head[233] = 0
        struct.pack_into('<H', head, 239, 256)
        out += head
        sample = bytearray(40)
        struct.pack_into('<III', sample, 0, len(wave), 0, len(wave) if loop else 0)
        sample[12] = volume
        sample[14] = 1 if loop else 0
        sample[15] = 128
        sample[18:18 + 22] = name.encode('ascii').ljust(22, b'\0')
        out += sample
        previous = 0
        deltas = bytearray()
        for w in wave:
            deltas.append((w - previous) & 0xFF)
            previous = w
        out += deltas
    open(path, 'wb').write(bytes(out))


# ---------------------------------------------------------------------- IT

def write_it(path):
    song = build_song()
    out = bytearray(192)
    out[0:4] = b'IMPM'
    out[4:30] = b'DelphiDoom tracker test'.ljust(26, b'\0')
    struct.pack_into('<HHHH', out, 32, 2, len(INSTRUMENTS), len(INSTRUMENTS), 1)
    struct.pack_into('<HHH', out, 40, 0x0214, 0x0214, 1 | 4 | 8)
    out[48] = 128
    out[49] = 48
    out[50] = 6
    out[51] = 125
    out[52] = 128
    for channel in range(64):
        out[64 + channel] = (16 if channel % 2 == 0 else 48) if channel < CHANNELS else 160
        out[128 + channel] = 64
    out += bytes([0, 255])
    pointers_at = len(out)
    out += bytes(4 * (2 * len(INSTRUMENTS) + 1))
    while len(out) % 16:
        out.append(0)

    instrument_offsets = []
    for index in range(len(INSTRUMENTS)):
        instrument_offsets.append(len(out))
        head = bytearray(554)
        head[0:4] = b'IMPI'
        head[17] = 0
        struct.pack_into('<H', head, 20, 256)
        head[24] = 128
        head[25] = 32
        head[32:32 + 26] = INSTRUMENTS[index][0].encode('ascii').ljust(26, b'\0')
        for n in range(120):
            head[64 + 2 * n] = n
            head[65 + 2 * n] = index + 1
        out += head
    sample_offsets = []
    sample_headers = len(out)
    out += bytes(80 * len(INSTRUMENTS))
    pattern_offset = len(out)
    packed = bytearray()
    for row in song:
        for channel, cell in enumerate(row):
            if cell is None:
                continue
            n, inst, vol, effect, param = cell
            code, value = effect_for('it', effect, param)
            mask = 0x01 | 0x02 | 0x04 | (0x08 if effect is not None else 0)
            packed += bytes([(channel + 1) | 0x80, mask, n - 1, inst, min(vol, 64)])
            if effect is not None:
                packed += bytes([code, value])
        packed.append(0)
    out += struct.pack('<HH', len(packed), ROWS) + bytes(4) + bytes(packed)
    for index, (name, wave, loop, volume) in enumerate(INSTRUMENTS):
        sample_offsets.append(sample_headers + 80 * index)
        data_at = len(out)
        out += bytes([(w + 128) & 0xFF for w in wave])
        head = bytearray(80)
        head[0:4] = b'IMPS'
        head[17] = 64
        head[18] = 1 | (16 if loop else 0)
        head[19] = volume
        head[20:20 + 26] = name.encode('ascii').ljust(26, b'\0')
        head[46] = 0
        struct.pack_into('<IIII', head, 48, len(wave), 0, len(wave) if loop else 0, 16726)
        struct.pack_into('<I', head, 72, data_at)
        out[sample_headers + 80 * index:sample_headers + 80 * index + 80] = head
    for index, offset in enumerate(instrument_offsets):
        struct.pack_into('<I', out, pointers_at + 4 * index, offset)
    for index, offset in enumerate(sample_offsets):
        struct.pack_into('<I', out, pointers_at + 4 * (len(INSTRUMENTS) + index), offset)
    struct.pack_into('<I', out, pointers_at + 4 * 2 * len(INSTRUMENTS), pattern_offset)
    open(path, 'wb').write(bytes(out))


# --------------------------------------------------------------------- WAD

def write_wad(path, lumps):
    data = bytearray(12)
    directory = bytearray()
    for name, content in lumps:
        directory += struct.pack('<ii8s', len(data), len(content), name.encode('ascii'))
        data += content
    struct.pack_into('<4sii', data, 0, b'PWAD', len(lumps), len(data))
    data += directory
    open(path, 'wb').write(bytes(data))


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    folder = argv[1]
    os.makedirs(folder, exist_ok=True)
    if len(argv) > 2:
        paths = argv[2:6]
    else:
        paths = []
        for extension, writer in (('mod', write_mod), ('s3m', write_s3m), ('xm', write_xm), ('it', write_it)):
            path = os.path.join(folder, 'prova.' + extension)
            writer(path)
            paths.append(path)
    songs = [open(path, 'rb').read() for path in paths]
    write_wad(os.path.join(folder, 'TRACKER_DOOM.WAD'),
              [('D_E1M%d' % (i + 1), song) for i, song in enumerate(songs)])
    write_wad(os.path.join(folder, 'TRACKER_HERETIC.WAD'),
              [('MUS_E1M%d' % (i + 1), song) for i, song in enumerate(songs)])
    for index, path in enumerate(paths):
        print('livello %d: %s (%d byte)' % (index + 1, os.path.basename(path), len(songs[index])))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
