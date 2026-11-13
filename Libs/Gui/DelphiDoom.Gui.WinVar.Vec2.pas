{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinVec2                                       }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinVec2).   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Vec2;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinVec2</summary>
  TGuiWinVec2 = class(TGuiWinVar)
  strict private
    FData: TIdVec2;
    procedure SetData(const AValue: TIdVec2);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    property Value: TIdVec2 read FData write SetData;
  end;

implementation

function TGuiWinVec2.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetVec2(GetName);
end;

procedure TGuiWinVec2.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinVec2 then
    FData := TGuiWinVec2(AOther).FData;
end;

procedure TGuiWinVec2.SetData(const AValue: TIdVec2);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetVec2(GetName, FData);
end;

procedure TGuiWinVec2.SetFromText(const AValue: AnsiString);
var
  LValues: array[0..1] of Single;
begin
  LValues[0] := FData.X;
  LValues[1] := FData.Y;
  ScanFloats(AValue, LValues);
  SetData(TIdVec2.Create(LValues[0], LValues[1]));
end;

procedure TGuiWinVec2.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetVec2(LName);
end;

function TGuiWinVec2.AsText: AnsiString;
begin
  Result := FData.ToString;
end;

function TGuiWinVec2.X: Single;
begin
  Result := FData.X;
end;

end.
