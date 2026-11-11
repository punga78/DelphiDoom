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
  /// <summary>
  ///   A set of sounds (GEO.CAT, BATTLE.CAT) of the rulesets: the CAT file and the entries of the file, in the order
  ///   of the set (the sound number n of the set is the entry Sounds[n]; -1 is a hole)
  /// </summary>
  TXcomSoundSet = class
  public
    CatFile: string;
    Sounds: TArray<Integer>;
  end;

implementation

end.