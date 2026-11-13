{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinRectangle                                  }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h                }
{  (idWinRectangle). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Rectangle;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinRectangle (the dictionary holds it as a vec4: x, y, w, h)</summary>
  TGuiWinRectangle = class(TGuiWinVar)
  strict private
    FData: TGuiRectangle;
    procedure SetData(const AValue: TGuiRectangle);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    property Value: TGuiRectangle read FData write SetData;
  end;

implementation

function TGuiWinRectangle.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := TGuiRectangle.FromVec4(Dict.GetVec4(GetName));
end;

procedure TGuiWinRectangle.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinRectangle then
    FData := TGuiWinRectangle(AOther).FData;
end;

procedure TGuiWinRectangle.SetData(const AValue: TGuiRectangle);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetVec4(GetName, FData.ToVec4);
end;

procedure TGuiWinRectangle.SetFromText(const AValue: AnsiString);
var
  LValues: array[0..3] of Single;
begin
  LValues[0] := FData.X;
  LValues[1] := FData.Y;
  LValues[2] := FData.W;
  LValues[3] := FData.H;
  ScanFloats(AValue, LValues);
  SetData(TGuiRectangle.Create(LValues[0], LValues[1], LValues[2], LValues[3]));
end;

procedure TGuiWinRectangle.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := TGuiRectangle.FromVec4(Dict.GetVec4(LName));
end;

function TGuiWinRectangle.AsText: AnsiString;
begin
  Result := FData.ToVec4.ToString;
end;

function TGuiWinRectangle.X: Single;
begin
  Result := FData.X;
end;

end.
