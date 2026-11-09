{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the settings                    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): m_defs.pas                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Settings.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Save.Intf;

type
  /// <summary>The kind of a setting of the file (ttype_t): boolean settings are written as 0 and 1</summary>
  TGreedSettingKind = (gskString, gskBoolean, gskInteger);

  /// <summary>
  ///   The 42 settings of the file xGreed.ini (the defaults table of m_defs.pas) with their values, in the order of the
  ///   original. The keys that the game binds (bt_north ... bt_motionmode) are scan codes
  /// </summary>
  IGreedSettings = interface
    ['{D4B7E1F0-8C36-4A59-B2E8-17A09C5D3F46}']
    function GetCount: Integer;
    function NameOf(AIndex: Integer): string;
    function KindOf(const AName: string): TGreedSettingKind;
    /// <summary>EGreedException for a name that is not a setting, or of another kind</summary>
    function GetInteger(const AName: string): Integer;
    function GetBoolean(const AName: string): Boolean;
    function GetString(const AName: string): string;
    procedure SetInteger(const AName: string; AValue: Integer);
    procedure SetBoolean(const AName: string; AValue: Boolean);
    procedure SetString(const AName: string; const AValue: string);
    /// <summary>Every setting to its default (the start of M_LoadDefaults)</summary>
    procedure Reset;
    /// <summary>
    ///   Reads Name=Value lines over the current values: a name that is not a setting is ignored, a boolean is
    ///   true unless the value is empty or "0", an integer takes the value only if it is not empty (and a value
    ///   that is not a number is 0), a string takes the value as it is. True if the text has lines (M_LoadDefaults)
    /// </summary>
    function LoadFromText(const AText: string): Boolean;
    /// <summary>One Name=Value line for each setting (M_SaveDefaults), lines separated by CR LF</summary>
    function SaveToText: string;
    /// <summary>gameepisode: 1, 2 or 3 (a value other than 2 and 3 is the game 1)</summary>
    function GetEpisode: Integer;
    procedure SetEpisode(AValue: Integer);
    /// <summary>The game that the episode says</summary>
    function GetGameVariant: TGreedGameVariant;
    /// <summary>
    ///   The -game1, -game2, -game3 of the command line (M_ResolveCommandLineEpisode): the first one present wins;
    ///   AGame is 1, 2 or 3 for the one that was found, 0 for none
    /// </summary>
    procedure ApplyCommandLineGame(AGame: Integer);
    property Count: Integer read GetCount;
    property Episode: Integer read GetEpisode write SetEpisode;
  end;

  /// <summary>Where the file of the settings is: loaded at the start and saved when the game closes</summary>
  IGreedSettingsStore = interface
    ['{F83A2C61-5E94-4B07-A1D5-C0792B6E48F3}']
    /// <summary>
    ///   M_LoadDefaults: the defaults, then the file if it exists. True if the file had lines. The command line
    ///   game (0 for none) is applied after the episode of the file
    /// </summary>
    function Load(const ASettings: IGreedSettings; ACommandLineGame: Integer): Boolean;
    /// <summary>M_SaveDefaults</summary>
    procedure Save(const ASettings: IGreedSettings);
  end;

implementation

end.
