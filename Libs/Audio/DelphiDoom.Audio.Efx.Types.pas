{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - types of the EFX reverb presets                 }
{                                                                              }
{  Port of the EFX file of Doom 3 (id Software, GPL v3): openal\include\       }
{  efxlib.h (idSoundEffect) and openal\include\eax4.h (EAXREVERBPROPERTIES,    }
{  EAXVECTOR). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Efx.Types;

interface

type
  /// <summary>EAXVECTOR: a panning vector</summary>
  TEfxVector = record
    X: Single;
    Y: Single;
    Z: Single;
  end;

  /// <summary>
  ///   EAXREVERBPROPERTIES: the properties of a reverb preset, in the order and with the sizes of the C structure
  ///   (112 bytes: <c>unsigned long</c> and <c>long</c> are 32 bits). A field that the file does not set is zero
  ///   (the original leaves the block it allocates as it finds it)
  /// </summary>
  TEfxReverbProperties = record
    /// <summary>ulEnvironment: sets all the reverb properties</summary>
    Environment: Cardinal;
    /// <summary>flEnvironmentSize: in meters</summary>
    EnvironmentSize: Single;
    EnvironmentDiffusion: Single;
    /// <summary>lRoom: room effect level (at mid frequencies)</summary>
    Room: Integer;
    /// <summary>lRoomHF: relative room effect level at high frequencies</summary>
    RoomHF: Integer;
    /// <summary>lRoomLF: relative room effect level at low frequencies</summary>
    RoomLF: Integer;
    DecayTime: Single;
    DecayHFRatio: Single;
    DecayLFRatio: Single;
    /// <summary>lReflections: early reflections level relative to the room effect</summary>
    Reflections: Integer;
    ReflectionsDelay: Single;
    ReflectionsPan: TEfxVector;
    /// <summary>lReverb: late reverberation level relative to the room effect</summary>
    Reverb: Integer;
    ReverbDelay: Single;
    ReverbPan: TEfxVector;
    EchoTime: Single;
    EchoDepth: Single;
    ModulationTime: Single;
    ModulationDepth: Single;
    AirAbsorptionHF: Single;
    HFReference: Single;
    LFReference: Single;
    RoomRolloffFactor: Single;
    /// <summary>ulFlags: modifies the behavior of the properties</summary>
    Flags: Cardinal;
  end;

  /// <summary>
  ///   idSoundEffect: a named effect. The original keeps a block of memory and its size (always the size of
  ///   <c>EAXREVERBPROPERTIES</c>, the only kind the file reader makes); here it is the properties themselves
  /// </summary>
  TEfxEffect = record
    Name: AnsiString;
    Reverb: TEfxReverbProperties;
  end;

implementation

end.
