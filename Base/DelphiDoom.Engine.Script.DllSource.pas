{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the DLLs of the PAK files come from              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.DllSource;

interface

uses
  DelphiDoom.Pak.Intf,
  DelphiDoom.Platform.Intf,
  DelphiDoom.ScriptHost.Dll.Intf;

type
  /// <summary>
  ///   Finds a DLL in the PAK file system (or on disk) and copies it to a temporary file. It was
  ///   in ps_dll.pas
  /// </summary>
  TEngineScriptDllSource = class(TInterfacedObject, IScriptDllSource)
  strict private
    FPakFiles: IPakFileSystem;
    FTempFiles: ITempFiles;
    class function GameFolders: TArray<string>; static;
  public
    /// <exception cref="EArgumentNilException">If a dependency is nil</exception>
    constructor Create(const APakFiles: IPakFileSystem; const ATempFiles: ITempFiles);
    function KeyOf(const AName: string): string;
    function Extract(const AName: string; out APath: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdef,
  w_folders,
  DelphiDoom.Wad.Pak.Types;

{ TEngineScriptDllSource }

constructor TEngineScriptDllSource.Create(const APakFiles: IPakFileSystem;
  const ATempFiles: ITempFiles);
begin
  inherited Create;
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create('APakFiles');
  if not Assigned(ATempFiles) then
    raise EArgumentNilException.Create('ATempFiles');
  FPakFiles := APakFiles;
  FTempFiles := ATempFiles;
end;

class function TEngineScriptDllSource.GameFolders: TArray<string>;
var
  LIndex: Integer;
begin
  // read at each call: d_main sets the folders after the start
  Result := nil;
  if doomdef.gamedirectories = nil then
    Exit;
  SetLength(Result, doomdef.gamedirectories.Count);
  for LIndex := 0 to doomdef.gamedirectories.Count - 1 do
    Result[LIndex] := doomdef.gamedirectories[LIndex];
end;

function TEngineScriptDllSource.KeyOf(const AName: string): string;
begin
  Result := strupper(fshortname(AName));
end;

function TEngineScriptDllSource.Extract(const AName: string; out APath: string): Boolean;
var
  LStream: TDStream;
  LShortName: string;
begin
  APath := '';
  LShortName := fshortname(AName);
  LStream := FPakFiles.Open(AName, TPakLookupMode.Preferred, GameFolders, '');
  if LStream.IOResult <> 0 then
  begin
    LStream.Free;
    LStream := FPakFiles.Open(LShortName, TPakLookupMode.Short, nil, FOLDER_DLL);
    if LStream.IOResult <> 0 then
    begin
      LStream.Free;
      Result := False;
      Exit;
    end;
  end;

  try
    APath := FTempFiles.NewTempFile(LShortName);
    SaveStreamToFile(LStream, APath);
  finally
    LStream.Free;
  end;
  Result := True;
end;

end.
