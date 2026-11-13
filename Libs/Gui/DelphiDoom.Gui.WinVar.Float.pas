{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinFloat                                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinFloat).  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Float;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinFloat</summary>
  TGuiWinFloat = class(TGuiWinVar)
  strict private
    FData: Single;
    procedure SetData(const AValue: Single);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    /// <summary>va("%f")</summary>
    function AsText: AnsiString; override;
    function X: Single; override;
    property Value: Single read FData write SetData;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.IdLib.Text.Strings;

function TGuiWinFloat.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetFloat(GetName);
end;

procedure TGuiWinFloat.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinFloat then
    FData := TGuiWinFloat(AOther).FData;
end;

procedure TGuiWinFloat.SetData(const AValue: Single);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetFloat(GetName, FData);
end;

procedure TGuiWinFloat.SetFromText(const AValue: AnsiString);
begin
  SetData(TIdCNumbers.Atof(AValue));
end;

procedure TGuiWinFloat.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetFloat(LName);
end;

function TGuiWinFloat.AsText: AnsiString;
begin
  Result := TIdStrings.FloatToPlainText(FData);
end;

function TGuiWinFloat.X: Single;
begin
  Result := FData;
end;

end.
