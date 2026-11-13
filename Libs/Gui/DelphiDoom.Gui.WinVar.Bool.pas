{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWinBool                                       }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Winvar.h (idWinBool).   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.WinVar.Bool;

interface

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Gui.WinVar.Base;

type
  /// <summary>idWinBool</summary>
  TGuiWinBool = class(TGuiWinVar)
  strict private
    FData: Boolean;
    procedure SetData(const AValue: Boolean);
  public
    function Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean; override;
    procedure AssignVar(const AOther: TGuiWinVar); override;
    procedure SetFromText(const AValue: AnsiString); override;
    procedure Update; override;
    function AsText: AnsiString; override;
    function X: Single; override;
    /// <summary>Writes the dictionary too when the variable is bound</summary>
    property Value: Boolean read FData write SetData;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers;

function TGuiWinBool.Init(const AName: AnsiString; const AStateDict: TIdDict): Boolean;
begin
  Result := inherited Init(AName, AStateDict);
  if Assigned(Dict) then
    FData := Dict.GetBool(GetName);
end;

procedure TGuiWinBool.AssignVar(const AOther: TGuiWinVar);
begin
  inherited AssignVar(AOther);
  if AOther is TGuiWinBool then
    FData := TGuiWinBool(AOther).FData;
end;

procedure TGuiWinBool.SetData(const AValue: Boolean);
begin
  FData := AValue;
  if Assigned(Dict) then
    Dict.SetBool(GetName, FData);
end;

procedure TGuiWinBool.SetFromText(const AValue: AnsiString);
begin
  SetData(TIdCNumbers.Atoi(AValue) <> 0);
end;

procedure TGuiWinBool.Update;
var
  LName: AnsiString;
begin
  LName := GetName;
  if Assigned(Dict) and (LName <> '') then
    FData := Dict.GetBool(LName);
end;

function TGuiWinBool.AsText: AnsiString;
begin
  Result := AnsiString(IntToStr(Ord(FData)));
end;

function TGuiWinBool.X: Single;
begin
  if FData then
    Result := 1.0
  else
    Result := 0.0;
end;

end.
