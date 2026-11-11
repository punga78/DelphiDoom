{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a soundDefs entry of the rulesets          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.SoundSet;

interface

type
  /// <summary>How the entries of the CAT file of a set become WAV files</summary>
  TXcomSoundSetFormat = (
    /// <summary>SoundSet::loadCatbyIndex: signed 8 bit samples at 11025 Hz (the soundDefs sets, TFTD)</summary>
    sfIndexed,
    /// <summary>SoundSet::loadCat(file, false): 6 bit samples at 8 kHz (SOUND1.CAT, SOUND2.CAT, INTRO.CAT)</summary>
    sfDos,
    /// <summary>SoundSet::loadCat(file, true): WAV files (SAMPLE.CAT, SAMPLE2.CAT, SAMPLE3.CAT)</summary>
    sfWave);

  /// <summary>
  ///   A set of sounds (GEO.CAT, BATTLE.CAT) of the rulesets: the CAT file and the entries of the file, in the order
  ///   of the set (the sound number n of the set is the entry Sounds[n]; -1 is a hole)
  /// </summary>
  TXcomSoundSet = class
  public
    CatFile: string;
    Sounds: TArray<Integer>;
    /// <summary>The conversion of the entries</summary>
    Format: TXcomSoundSetFormat;
    /// <summary>A whole file (SoundSet::loadCat): the sound number n is the entry n and Sounds is not used</summary>
    WholeFile: Boolean;
  end;

implementation

end.