{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - tables, records and the exception           }
{                                                                              }
{  Port of adlplayer.cpp and AdlibMusic.cpp (X-COM Adlib Player by Volutar,     }
{  OpenXcom, GPL v3 or later): see Libs\Opl\README.md for the license           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Adlib channels the player drives (the OPL state has 12, 9 sound)</summary>
  XCOM_ADLIB_CHANNELS = 12;
  /// <summary>Instruments (tracks) of a song</summary>
  XCOM_ADLIB_INSTRUMENTS = 16;
  /// <summary>Subtracks a song can call</summary>
  XCOM_ADLIB_MAX_SUBTRACKS = 128;
  /// <summary>Bytes of one sample (instrument definition) of a song; the first 11 are used</summary>
  XCOM_ADLIB_SAMPLE_BYTES = 24;
  /// <summary>Notes of the frequency tables (9 octaves of 12)</summary>
  XCOM_ADLIB_NOTES = 108;

  /// <summary>adl_gv_freq_table: the F-number of every note</summary>
  XCOM_ADLIB_FREQUENCIES: array[0..XCOM_ADLIB_NOTES - 1] of SmallInt = (
    $0B5, $0C0, $0CC, $0D8, $0E5, $0F2, $101, $110, $120, $131, $143, $157,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE,
    $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2AE);

  /// <summary>adl_gv_octave_table: the octave (block) of every note</summary>
  XCOM_ADLIB_OCTAVES: array[0..XCOM_ADLIB_NOTES - 1] of ShortInt = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7);

  /// <summary>adl_gv_detune_table: the pitch bend scale of every note</summary>
  XCOM_ADLIB_DETUNES: array[0..XCOM_ADLIB_NOTES - 1] of ShortInt = (
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5,
    3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5);

  /// <summary>adl_gv_instr_order: the order the tracks are decoded in each tick</summary>
  XCOM_ADLIB_INSTRUMENT_ORDER: array[0..XCOM_ADLIB_INSTRUMENTS - 1] of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 9);

  /// <summary>adl_gv_operators1: the register offset of the first operator of every channel</summary>
  XCOM_ADLIB_OPERATORS: array[0..XCOM_ADLIB_CHANNELS - 1] of Byte = (0, 1, 2, 8, 9, 10, 16, 17, 18, 24, 25, 26);

  /// <summary>slot_array of adlplayer.cpp (int8_t: the -1 of the unused slots is odd)</summary>
  XCOM_ADLIB_SLOT_ARRAY: array[0..31] of ShortInt = (
    0, 2, 4, 1, 3, 5, -1, -1,
    6, 8, 10, 7, 9, 11, -1, -1,
    12, 14, 16, 13, 15, 17, -1, -1,
    18, 20, 22, 19, 21, 23, -1, -1);

type
  /// <summary>Raised when a song or a request cannot be followed (the C reads and writes outside its arrays)</summary>
  EXcomAdlibException = class(Exception);

  /// <summary>struc_adlib_channels: the state of one adlib channel</summary>
  TXcomAdlibChannel = record
    CurNote: Byte;
    CurInstrument: Byte;
    CurSample: Byte;
    CurFreq: Byte;
    HiFreq: Byte;
    CurVolume: Byte;
    Duration: Integer;
    Pan: Integer;
  end;

  /// <summary>struc_instruments: the state of one track; addresses are offsets into the song, -1 is the null pointer</summary>
  TXcomAdlibInstrument = record
    SampleId: Byte;
    PrevCmd: Byte;
    Volume: Byte;
    CurPitchBend: SmallInt;
    CurDelay: Integer;
    CurAddress: Integer;
    StartAddress: Integer;
    ReturnAddress: Integer;
  end;

  TXcomAdlibInstruments = array[0..XCOM_ADLIB_INSTRUMENTS - 1] of TXcomAdlibInstrument;

implementation

end.
