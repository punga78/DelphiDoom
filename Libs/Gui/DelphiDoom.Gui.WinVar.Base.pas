{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinVar, a variable of a window                }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h, Winvar.cpp    }
{  (idWinVar). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Base;

interface

uses
  DelphiDoom.Scanner.IdDict;

const
  /// <summary>VAR_GUIPREFIX: the variables of the state of the gui</summary>
  GUI_VAR_PREFIX = 'gui::';
  GUI_VAR_PREFIX_LENGTH = 5;

type
  /// <summary>
  ///   idWinVar: a typed value of a window that can be bound to a key of the state dictionary of the
  ///   gui (a name that starts with <c>gui::</c>). A bound variable reads the dictionary on
  ///   <c>Update</c> and writes it when it is set. The dictionary is not owned. Not ported: the save game
  ///   and demo file functions and <c>Size</c>.
  /// </summary>
  TGuiWinVar = class abstract
  strict private
    FDict: TIdDict;
    FName: AnsiString;
    FEval: Boolean;
  protected
    /// <summary>The dictionary the variable is bound to, nil if it is not</summary>
    property Dict: TIdDict read FDict;
    /// <summary>sscanf of floats separated by commas or by blanks (the comma form of idWinVec4::Set)</summary>
    class function ScanFloats(const AText: AnsiString; var AValues: array of Single): Integer; static;
  public
    constructor Create;
    /// <summary>
    ///   idWinVar::Init: a name of more than 5 characters that starts with "gui:" binds the variable to the
    ///   key after the first 5 characters (the original strips "gui::" after comparing only "gui:") and the
    ///   result is True (the caller adds it to the variables to update); any other name is the value
    ///   (<c>SetFromText</c>). The subclasses read the dictionary after this.
    /// </summary>
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; virtual;
    procedure SetGuiInfo(const ADict: TIdDict; const AName: AnsiString);
    /// <summary>The key of the dictionary; a name that starts with '*' is the key that the dictionary holds under that name</summary>
    function GetName: AnsiString;
    procedure SetName(const AName: AnsiString);
    /// <summary>idWinVar::operator=: the binding and the name (the subclasses copy their value too)</summary>
    procedure AssignVar(const AOther: TGuiWinVar); virtual;
    function NeedsUpdate: Boolean;
    /// <summary>idWinVar::Set(const char *)</summary>
    procedure SetFromText(const AValue: AnsiString); virtual; abstract;
    procedure Update; virtual; abstract;
    /// <summary>c_str()</summary>
    function AsText: AnsiString; virtual; abstract;
    /// <summary>x(): the value in an expression (the first component of a vector)</summary>
    function X: Single; virtual; abstract;
    /// <summary>False once a script or a transition has set the variable: the registers no longer drive it</summary>
    property Eval: Boolean read FEval write FEval;
    property BoundDict: TIdDict read FDict;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers;

constructor TGuiWinVar.Create;
begin
  inherited Create;
  FEval := True;
end;

class function TGuiWinVar.ScanFloats(const AText: AnsiString; var AValues: array of Single): Integer;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := AText;
  // "%f,%f": the commas are separators too (a blank before a comma is accepted, which sscanf does not)
  for LIndex := 1 to Length(LText) do
    if LText[LIndex] = ',' then
      LText[LIndex] := ' ';
  Result := TIdCNumbers.ScanFloats(LText, AValues);
end;

procedure TGuiWinVar.SetGuiInfo(const ADict: TIdDict; const AName: AnsiString);
begin
  FDict := ADict;
  SetName(AName);
end;

function TGuiWinVar.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  FDict := nil;
  if (Length(AName) > 5) and (Copy(AName, 1, 4) = 'gui:') then
  begin
    SetGuiInfo(AStateDict, Copy(AName, GUI_VAR_PREFIX_LENGTH + 1, MaxInt));
    Result := True;
  end
  else
  begin
    SetFromText(AName);
    Result := False;
  end;
end;

function TGuiWinVar.GetName: AnsiString;
begin
  if (FName <> '') and Assigned(FDict) and (FName[1] = '*') then
    Exit(FDict.GetString(Copy(FName, 2, MaxInt)));
  Result := FName;
end;

procedure TGuiWinVar.SetName(const AName: AnsiString);
begin
  FName := AName;
end;

procedure TGuiWinVar.AssignVar(const AOther: TGuiWinVar);
begin
  FDict := AOther.FDict;
  FName := AOther.FName;
end;

function TGuiWinVar.NeedsUpdate: Boolean;
begin
  Result := Assigned(FDict);
end;

end.
