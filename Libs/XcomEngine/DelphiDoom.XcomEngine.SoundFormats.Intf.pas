{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the format of the sounds of UFO (the       }
{  preferredSound and currentSound options of Mod::loadExtraResources)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.SoundFormats.Intf;

interface

const
  /// <summary>SoundFormat of OpenXcom: no preference</summary>
  XCOM_SOUND_AUTO = 0;
  /// <summary>The sounds of the Windows version 1.4 (SAMPLE.CAT, SAMPLE2.CAT: WAV files)</summary>
  XCOM_SOUND_14 = 1;
  /// <summary>The sounds of the DOS version 1.0 (SOUND2.CAT, SOUND1.CAT: raw 6 bit samples at 8 kHz)</summary>
  XCOM_SOUND_10 = 2;

type
  /// <summary>
  ///   What the resources of a game without soundDefs (UFO) let choose about the sounds: optional interface of
  ///   IXcomResources, asked for by the game when it adopts the data
  /// </summary>
  IXcomSoundFormats = interface
    ['{6B0E3C55-0A0B-4E0C-9D57-2C1C3A5E9B11}']
    /// <summary>Options::preferredSound: the format that is tried first (XCOM_SOUND_*)</summary>
    procedure SetPreferredSound(AFormat: Integer);
    /// <summary>Options::currentSound: the format of the files that were found (XCOM_SOUND_AUTO: none)</summary>
    function CurrentSound: Integer;
  end;

implementation

end.
