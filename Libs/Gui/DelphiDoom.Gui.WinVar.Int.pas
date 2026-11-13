{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinInt                                        }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinInt).    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Int;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinInt. <c>X</c> is 0: the original asserts "no suitable conversion" and returns 0 in a release build</summary>
  TGuiWinInt = class(TGuiWinVar)
  strict private
    FData: Integer;
    procedure SetData(const AValue: Integer);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    property Value: Integer read FData write SetData;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers;

function TGuiWinInt.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetInt(GetName);
end;

procedure TGuiWinInt.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinInt then
    FData := TGuiWinInt(AOther).FData;
end;

procedure TGuiWinInt.SetData(const AValue: Integer);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetInt(GetName, FData);
end;

procedure TGuiWinInt.SetFromText(const AValue: AnsiString);
begin
  SetData(TIdCNumbers.Atoi(AValue));
end;

procedure TGuiWinInt.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetInt(LName);
end;

function TGuiWinInt.AsText: AnsiString;
begin
  Result := AnsiString(IntToStr(FData));
end;

function TGuiWinInt.X: Single;
begin
  Result := 0.0;
end;

end.
