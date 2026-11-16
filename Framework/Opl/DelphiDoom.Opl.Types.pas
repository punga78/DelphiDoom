{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - constants, records and the exception     }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  Copyright (C) 1999,2000 Tatsuyuki Satoh, MultiArcadeMachineEmurator          }
{  development; modified for X-COM (increased polyphony) by Volutar             }
{                                                                              }
{  This library is free software; you can redistribute it and/or modify it      }
{  under the terms of the GNU Lesser General Public License as published by     }
{  the Free Software Foundation; either version 2.1 of the License, or (at      }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>FREQ_BITS: frequency turn</summary>
  OPL_FREQ_BITS = 24;
  /// <summary>FREQ_RATE: counter bits = 20, octave 7</summary>
  OPL_FREQ_RATE = 1 shl (OPL_FREQ_BITS - 20);
  /// <summary>TL_BITS</summary>
  OPL_TL_BITS = OPL_FREQ_BITS + 2;
  /// <summary>OPL_OUTSB: final output shift to 16 bit</summary>
  OPL_OUTSB = OPL_TL_BITS + 1 - 16;
  OPL_MAXOUT = $7FFF shl OPL_OUTSB;
  OPL_MINOUT = -($8000 shl OPL_OUTSB);

  /// <summary>SIN_ENT: sinwave entries</summary>
  OPL_SIN_ENT = 2048;
  /// <summary>ENV_BITS: envelope counter lower bits</summary>
  OPL_ENV_BITS = 16;
  /// <summary>EG_ENT: envelope output entries</summary>
  OPL_EG_ENT = 4096;
  OPL_EG_OFF = (2 * OPL_EG_ENT) shl OPL_ENV_BITS;
  OPL_EG_DED = OPL_EG_OFF;
  OPL_EG_DST = OPL_EG_ENT shl OPL_ENV_BITS;
  OPL_EG_AED = OPL_EG_DST;
  OPL_EG_AST = 0;
  /// <summary>EG_STEP: 96.0 / EG_ENT, the OPL is a 0.1875 dB step</summary>
  OPL_EG_STEP = 96.0 / 4096;
  OPL_TL_MAX = OPL_EG_ENT * 2;
  OPL_VIB_ENT = 512;
  OPL_VIB_SHIFT = 32 - 9;
  OPL_AMS_ENT = 512;
  OPL_AMS_SHIFT = 32 - 9;
  OPL_VIB_RATE = 256;
  /// <summary>Channels the chip state holds (the X-COM fork raised 9 to 12; only 9 are calculated)</summary>
  OPL_MAX_CHANNELS = 12;
  /// <summary>Channels that produce sound</summary>
  OPL_SOUND_CHANNELS = 9;
  /// <summary>Entries of the attack and decay tables (the C arrays have 75; the extra entry is the 0 the C reads past them)</summary>
  OPL_RATE_TABLE_SIZE = 76;
  OPL_ARRATE = 141280;
  OPL_DRRATE = 1956000;

  /// <summary>Envelope phases (ENV_MOD_*)</summary>
  OPL_ENV_RELEASE = 0;
  OPL_ENV_DECAY = 1;
  OPL_ENV_ATTACK = 2;

  /// <summary>Chip types of the C: OPL_TYPE_YM3526 (0) and OPL_TYPE_YM3812 (waveform select)</summary>
  OPL_TYPE_WAVESEL = 1;

type
  /// <summary>Chip variants that this port builds (the Y8950 with the ADPCM unit is not ported)</summary>
  TOplChipType = (octYm3526 = 0, octYm3812 = 1);

  /// <summary>Raised for a request the chip cannot honour (bad buffer, bad stripe, bad parameters)</summary>
  EOplException = class(Exception);

  /// <summary>OPL_SLOT: one operator</summary>
  TOplSlot = record
    TL: Integer;
    TLL: Integer;
    /// <summary>KSR: key scale rate, the shift down bits of the key code (0 or 2)</summary>
    KsrShift: Byte;
    /// <summary>Index of AR_TABLE[AR << 2] in the chip, -1 for RATE_0 (all zero)</summary>
    ArBase: Integer;
    DrBase: Integer;
    SL: Integer;
    RrBase: Integer;
    ksl: Byte;
    /// <summary>ksr: key code shifted by KsrShift, the value the rates were last looked up with</summary>
    ksr: Byte;
    mul: Cardinal;
    Cnt: Cardinal;
    Incr: Cardinal;
    EgTyp: Byte;
    evm: Byte;
    evc: Integer;
    eve: Integer;
    evs: Integer;
    evsa: Integer;
    evsd: Integer;
    evsr: Integer;
    ams: Byte;
    vib: Byte;
    /// <summary>Wave selector: 0, 2048, 4096 or 6144, the first entry of the sine offset table of the waveform</summary>
    WaveBase: Integer;
  end;

  /// <summary>OPL_CH: one channel with two operators</summary>
  TOplChannel = record
    Slots: array[0..1] of TOplSlot;
    CON: Byte;
    FB: Byte;
    /// <summary>connect1 points to the carrier output (True) or to the feedback of operator 2 (False)</summary>
    Connect1ToCarrier: Boolean;
    op1_out: array[0..1] of Integer;
    block_fnum: Cardinal;
    kcode: Byte;
    fc: Cardinal;
    ksl_base: Cardinal;
    keyon: Byte;
  end;

implementation

end.
