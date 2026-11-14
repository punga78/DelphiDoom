{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiCvarSet, a table of console variables         }
{                                                                              }
{  The default implementation of IGuiCvars: names without distinction of       }
{  case, values as text, with the variables of the gui registered by           }
{  idWindow and idDeviceContext (gui_debug, gui_edit, gui_smallFontLimit,      }
{  gui_mediumFontLimit, r_skipGuiShaders, sys_lang) at their defaults.         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Cvars;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Gui.Cvars.Intf;

type
  /// <summary>A table of console variables for the windows of a gui; a host with a real console implements IGuiCvars itself</summary>
  TGuiCvarSet = class(TInterfacedObject, IGuiCvars)
  strict private
    FValues: TDictionary<string, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>idCVar construction: the variable exists with the default, and an existing one keeps its value</summary>
    procedure Register(const AName, AValue: AnsiString);
    function Exists(const AName: AnsiString): Boolean;
    function GetString(const AName: AnsiString): AnsiString;
    function GetInteger(const AName: AnsiString): Integer;
    function GetFloat(const AName: AnsiString): Single;
    function GetBool(const AName: AnsiString): Boolean;
    procedure SetString(const AName, AValue: AnsiString);
    procedure SetInteger(const AName: AnsiString; const AValue: Integer);
    /// <summary>The value is text as printf("%f") writes it (six decimals)</summary>
    procedure SetFloat(const AName: AnsiString; const AValue: Single);
    procedure SetBool(const AName: AnsiString; const AValue: Boolean);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers;

constructor TGuiCvarSet.Create;
begin
  inherited Create;
  FValues := TDictionary<string, AnsiString>.Create(TIStringComparer.Ordinal);
  Register('gui_debug', '0');
  Register('gui_edit', '0');
  Register('gui_smallFontLimit', '0.30');
  Register('gui_mediumFontLimit', '0.60');
  Register('r_skipGuiShaders', '0');
  Register('sys_lang', 'english');
end;

destructor TGuiCvarSet.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

procedure TGuiCvarSet.Register(const AName, AValue: AnsiString);
begin
  if not FValues.ContainsKey(string(AName)) then
    FValues.Add(string(AName), AValue);
end;

function TGuiCvarSet.Exists(const AName: AnsiString): Boolean;
begin
  Result := FValues.ContainsKey(string(AName));
end;

function TGuiCvarSet.GetString(const AName: AnsiString): AnsiString;
begin
  if not FValues.TryGetValue(string(AName), Result) then
    Result := '';
end;

function TGuiCvarSet.GetInteger(const AName: AnsiString): Integer;
begin
  Result := TIdCNumbers.Atoi(GetString(AName));
end;

function TGuiCvarSet.GetFloat(const AName: AnsiString): Single;
begin
  Result := TIdCNumbers.Atof(GetString(AName));
end;

function TGuiCvarSet.GetBool(const AName: AnsiString): Boolean;
begin
  Result := GetInteger(AName) <> 0;
end;

procedure TGuiCvarSet.SetString(const AName, AValue: AnsiString);
begin
  FValues.AddOrSetValue(string(AName), AValue);
end;

procedure TGuiCvarSet.SetInteger(const AName: AnsiString; const AValue: Integer);
begin
  SetString(AName, AnsiString(IntToStr(AValue)));
end;

procedure TGuiCvarSet.SetFloat(const AName: AnsiString; const AValue: Single);
begin
  SetString(AName, AnsiString(Format('%.6f', [Double(AValue)], TFormatSettings.Invariant)));
end;

procedure TGuiCvarSet.SetBool(const AName: AnsiString; const AValue: Boolean);
begin
  if AValue then
    SetString(AName, '1')
  else
    SetString(AName, '0');
end;

end.
