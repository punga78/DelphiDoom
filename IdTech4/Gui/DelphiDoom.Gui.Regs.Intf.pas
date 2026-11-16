{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - what the expressions and registers ask of a window}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Intf;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>The tables of the declarations (<c>declManager->FindType(DECL_TABLE)</c>, <c>TableLookup</c>)</summary>
  IGuiTables = interface
    ['{4D1F6A30-8B7C-4E52-9A13-6C0E5B2D7F01}']
    /// <summary>The index of the table, False if there is none with that name</summary>
    function FindTable(const AName: AnsiString; out AIndex: Integer): Boolean;
    function Lookup(const AIndex: Integer; const AValue: Single): Single;
  end;

  /// <summary>The language dictionary (<c>common->GetLanguageDict()->GetString</c>)</summary>
  IGuiLanguage = interface
    ['{4D1F6A30-8B7C-4E52-9A13-6C0E5B2D7F02}']
    function GetString(const AText: AnsiString): AnsiString;
  end;

  /// <summary>How the parser of expressions finds and initializes the variables a name refers to</summary>
  IGuiExpressionHost = interface
    ['{4D1F6A30-8B7C-4E52-9A13-6C0E5B2D7F03}']
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean): TGuiWinVar;
    /// <summary><c>var->Init(name, window)</c>: binds the variable to the state and registers it to update</summary>
    procedure InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
  end;

  /// <summary>What a register list needs of the window it belongs to</summary>
  IGuiRegisterOwner = interface
    ['{4D1F6A30-8B7C-4E52-9A13-6C0E5B2D7F04}']
    function ParseExpression(const ASource: TIdParser): Integer;
    function ExpressionConstant(const AValue: Single): Integer;
    procedure InitVar(const AVar: TGuiWinVar; const AName: AnsiString);
    function TranslateString(const AText: AnsiString): AnsiString;
  end;

implementation

end.
