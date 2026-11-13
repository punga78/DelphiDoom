{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinVec3                                       }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinVec3).   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Vec3;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinVec3 (the text form has no comma variant: "%f %f %f")</summary>
  TGuiWinVec3 = class(TGuiWinVar)
  strict private
    FData: TIdVec3;
    procedure SetData(const AValue: TIdVec3);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    property Value: TIdVec3 read FData write SetData;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers;

function TGuiWinVec3.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetVector(GetName);
end;

procedure TGuiWinVec3.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinVec3 then
    FData := TGuiWinVec3(AOther).FData;
end;

procedure TGuiWinVec3.SetData(const AValue: TIdVec3);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetVector(GetName, FData);
end;

procedure TGuiWinVec3.SetFromText(const AValue: AnsiString);
var
  LValues: array[0..2] of Single;
begin
  LValues[0] := FData.X;
  LValues[1] := FData.Y;
  LValues[2] := FData.Z;
  TIdCNumbers.ScanFloats(AValue, LValues);
  SetData(TIdVec3.Create(LValues[0], LValues[1], LValues[2]));
end;

procedure TGuiWinVec3.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetVector(LName);
end;

function TGuiWinVec3.AsText: AnsiString;
begin
  Result := FData.ToString;
end;

function TGuiWinVec3.X: Single;
begin
  Result := FData.X;
end;

end.
