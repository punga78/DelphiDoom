{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - what the states ask of the loaded game     }
{  data (the part of Mod of OpenXcom that the interface uses)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Resources.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.RuleInterface;

type
  /// <summary>
  ///   The graphics, fonts, palettes and interface rules of the game in use: Mod::getSurface, getFont, getPalette,
  ///   getInterface and setPalette. What it returns is owned by the implementation (the states never free it)
  /// </summary>
  IXcomResources = interface
    ['{2B7E41D8-96C3-4A05-8E1F-C4D0A63B9E72}']
    /// <summary>EXcomEngineException if there is no such surface</summary>
    function GetSurface(const AName: string): TXcomSurface;
    /// <summary>EXcomEngineException if there is no such font</summary>
    function GetFont(const AName: string): TXcomFont;
    /// <summary>nil when the ruleset has no such interface</summary>
    function GetInterface(const AId: string): TXcomRuleInterface;
    /// <summary>The first color of the 256 of a palette (PAL_GEOSCAPE...); EXcomEngineException if missing</summary>
    function GetPalette(const AName: string): PXcomColor;
    /// <summary>The color of the cursor for a palette (Mod::GEOSCAPE_CURSOR...: 252 for the geoscape ones, 144 otherwise)</summary>
    function CursorColor(const APalette: string): Integer;
    /// <summary>Mod::setPalette: the graphics and fonts of the game take the colors (so blits do not remap them)</summary>
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    /// <summary>Mod::getSoundDefinitions() is not empty: the rulesets define the sounds (TFTD does)</summary>
    function HasSoundDefinitions: Boolean;
    /// <summary>
    ///   Mod::getSound(set, index) as a WAV file: the index-th sound of the set (GEO.CAT, BATTLE.CAT) of the soundDefs of
    ///   the rulesets, read from its CAT file (nil when there is none or it is not readable)
    /// </summary>
    function SoundWave(const ASet: string; AIndex: Integer): TBytes;
    /// <summary>A number of the constants of the rulesets (ufoFire, buttonPress...), or the default</summary>
    function Constant(const AName: string; ADefault: Integer): Integer;
  end;

implementation

end.
