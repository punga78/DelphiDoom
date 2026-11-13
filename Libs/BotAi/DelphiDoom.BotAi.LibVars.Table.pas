{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotLibVarTable, the library variables                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\l_libvar.c (the part the chat uses).                            }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.LibVars.Table;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>
  ///   The table of library variables of the bot library: a variable has a text and a float value
  ///   (atof of the text); the names are compared without case as in l_libvar.c.
  /// </summary>
  TBotLibVarTable = class(TInterfacedObject, IBotLibVars)
  strict private
    FTexts: TDictionary<string, AnsiString>;
    class function Key(const AName: AnsiString): string; static;
    class function ToValue(const AText: AnsiString): Single; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>LibVarSet: creates or changes the variable</summary>
    procedure SetText(const AName, AText: AnsiString);
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers;

{ TBotLibVarTable }

constructor TBotLibVarTable.Create;
begin
  inherited Create;
  FTexts := TDictionary<string, AnsiString>.Create;
end;

destructor TBotLibVarTable.Destroy;
begin
  FTexts.Free;
  inherited Destroy;
end;

class function TBotLibVarTable.Key(const AName: AnsiString): string;
begin
  Result := LowerCase(string(AName));
end;

class function TBotLibVarTable.ToValue(const AText: AnsiString): Single;
begin
  Result := TIdCNumbers.Atof(AText);
end;

procedure TBotLibVarTable.SetText(const AName, AText: AnsiString);
begin
  FTexts.AddOrSetValue(Key(AName), AText);
end;

function TBotLibVarTable.GetValue(const AName: AnsiString): Single;
var
  LText: AnsiString;
begin
  if FTexts.TryGetValue(Key(AName), LText) then
    Result := ToValue(LText)
  else
    Result := 0;
end;

function TBotLibVarTable.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := ToValue(GetStringOrCreate(AName, ADefault));
end;

function TBotLibVarTable.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  if not FTexts.TryGetValue(Key(AName), Result) then
  begin
    FTexts.Add(Key(AName), ADefault);
    Result := ADefault;
  end;
end;

end.
