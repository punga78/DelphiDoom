{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the loading of the game data (what         }
{  StartState::load does with the mods and the languages)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.GameLoader.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Resources.Intf;

type
  /// <summary>
  ///   Loads the data of the game (rulesets, graphics, fonts, strings). It runs in a worker thread while the
  ///   start screen shows its text, so it must not touch the state or the window; an error is an exception, that
  ///   the start screen shows
  /// </summary>
  IXcomGameLoader = interface
    ['{A93C5E17-480D-4B6F-9D2A-17E8B0C4F5D3}']
    /// <param name="AResources">The data of the game; the game owns it (reference counted) from here</param>
    /// <param name="ALanguage">The strings of the language of the options; the game owns it from here</param>
    procedure Load(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
  end;

implementation

end.
