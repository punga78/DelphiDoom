{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinStr                                        }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinStr).    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Str;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinStr. <c>X</c> is 1 if the string is not empty</summary>
  TGuiWinStr = class(TGuiWinVar)
  strict protected
    FData: AnsiString;
  strict private
    procedure SetData(const AValue: AnsiString);
    procedure Refresh;
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    /// <summary>Length(): reads the dictionary first when the variable is bound</summary>
    function Length: Integer;
    function LengthWithoutColors: Integer;
    procedure RemoveColors;
    property Value: AnsiString read FData write SetData;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

procedure TGuiWinStr.Refresh;
begin
  if Assigned(Dict) and (GetName <> '') then
    FData := Dict.GetString(GetName);
end;

function TGuiWinStr.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetString(GetName);
end;

procedure TGuiWinStr.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinStr then
    FData := TGuiWinStr(AOther).FData;
end;

procedure TGuiWinStr.SetData(const AValue: AnsiString);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetValue(GetName, FData);
end;

procedure TGuiWinStr.SetFromText(const AValue: AnsiString);
begin
  SetData(AValue);
end;

procedure TGuiWinStr.Update;
begin
  Refresh;
end;

function TGuiWinStr.AsText: AnsiString;
begin
  Result := FData;
end;

function TGuiWinStr.X: Single;
begin
  if FData <> '' then
    Result := 1.0
  else
    Result := 0.0;
end;

function TGuiWinStr.Length: Integer;
begin
  Refresh;
  Result := System.Length(FData);
end;

function TGuiWinStr.LengthWithoutColors: Integer;
begin
  Refresh;
  Result := TIdStrings.LengthWithoutColors(FData);
end;

procedure TGuiWinStr.RemoveColors;
begin
  Refresh;
  FData := TIdStrings.RemoveColors(FData);
end;

end.
