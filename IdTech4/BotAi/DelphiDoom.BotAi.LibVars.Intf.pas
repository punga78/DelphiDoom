{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotLibVarStore, the library variables that can be set }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\l_libvar.c. Licensed under the GNU General Public License,      }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.LibVars.Intf;

interface

uses
  DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>
  ///   The whole of l_libvar.c: the readers of <c>IBotLibVars</c> plus LibVarGetString, LibVarSet,
  ///   LibVarChanged and LibVarSetNotModified. A separate interface so the fakes of the chat, which
  ///   only read variables, keep compiling.
  /// </summary>
  IBotLibVarStore = interface(IBotLibVars)
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F75}']
    /// <summary>LibVarGetString: the text of the variable, empty if it does not exist</summary>
    function GetString(const AName: AnsiString): AnsiString;
    /// <summary>LibVarSet: creates or changes the variable and marks it as modified</summary>
    procedure SetText(const AName, AText: AnsiString);
    /// <summary>LibVarChanged: false if the variable does not exist</summary>
    function Changed(const AName: AnsiString): Boolean;
    /// <summary>LibVarSetNotModified</summary>
    procedure SetNotModified(const AName: AnsiString);
  end;

implementation

end.
