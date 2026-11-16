{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the files of the variables of the scripts              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.VariablesFiles;

interface

uses
  System.SysUtils,
  DelphiDoom.Engine.Platform.Intf,
  DelphiDoom.ScriptHost.Variables.Intf;

type
  /// <summary>
  ///   The files of the variables of the scripts (the world variables of Hexen are a file of
  ///   the savegame): the whole files of the engine, whose reads go to the zone memory and are
  ///   given back to it
  /// </summary>
  TEngineScriptVariablesFiles = class(TInterfacedObject, IScriptVariablesFiles)
  strict private
    FFiles: IEngineFiles;
  public
    constructor Create(const AFiles: IEngineFiles);
    function ReadFile(const AName: string): TBytes;
    procedure WriteFile(const AName: string; const ABytes: TBytes);
  end;

implementation

uses
  z_zone;

{ TEngineScriptVariablesFiles }

constructor TEngineScriptVariablesFiles.Create(const AFiles: IEngineFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TEngineScriptVariablesFiles.ReadFile(const AName: string): TBytes;
var
  LBuffer: Pointer;
  LLength: Integer;
begin
  LBuffer := nil;
  LLength := FFiles.ReadFile(AName, LBuffer);
  SetLength(Result, LLength);
  if LLength > 0 then
    Move(LBuffer^, Result[0], LLength);
  Z_Free(LBuffer);
end;

procedure TEngineScriptVariablesFiles.WriteFile(const AName: string; const ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    FFiles.WriteFile(AName, @ABytes[0], Length(ABytes));
end;

end.
