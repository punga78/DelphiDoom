{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinVec4                                       }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinVec4).   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Vec4;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinVec4 (colors and the vectors of the render window)</summary>
  TGuiWinVec4 = class(TGuiWinVar)
  strict private
    FData: TIdVec4;
    procedure SetData(const AValue: TIdVec4);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    /// <summary>Sets the vector to zero (and the dictionary if bound)</summary>
    procedure Zero;
    property Value: TIdVec4 read FData write SetData;
  end;

implementation

function TGuiWinVec4.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetVec4(GetName);
end;

procedure TGuiWinVec4.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinVec4 then
    FData := TGuiWinVec4(AOther).FData;
end;

procedure TGuiWinVec4.SetData(const AValue: TIdVec4);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetVec4(GetName, FData);
end;

procedure TGuiWinVec4.SetFromText(const AValue: AnsiString);
var
  LValues: array[0..3] of Single;
begin
  LValues[0] := FData.X;
  LValues[1] := FData.Y;
  LValues[2] := FData.Z;
  LValues[3] := FData.W;
  ScanFloats(AValue, LValues);
  SetData(TIdVec4.Create(LValues[0], LValues[1], LValues[2], LValues[3]));
end;

procedure TGuiWinVec4.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetVec4(LName);
end;

function TGuiWinVec4.AsText: AnsiString;
begin
  Result := FData.ToString;
end;

function TGuiWinVec4.X: Single;
begin
  Result := FData.X;
end;

procedure TGuiWinVec4.Zero;
var
  LZero: TIdVec4;
begin
  LZero.Zero;
  SetData(LZero);
end;

end.
