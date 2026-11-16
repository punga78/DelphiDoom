{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the files of the scripts come from               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.SourceProvider;

interface

uses
  DelphiDoom.Pak.Intf,
  DelphiDoom.ScriptHost.Source.Intf;

type
  /// <summary>
  ///   The files that a script includes and the .ddscript and .ddout of a map, from the PAK file
  ///   system. It was the call of PAK_ReadFileAsString in ps_import.pas and ps_main.pas
  /// </summary>
  TEngineScriptSourceProvider = class(TInterfacedObject, IScriptSourceProvider)
  strict private
    FPakFiles: IPakFileSystem;
  public
    /// <exception cref="EArgumentNilException">If the PAK file system is nil</exception>
    constructor Create(const APakFiles: IPakFileSystem);
    function ReadText(const AFileName: string): string;
  end;

implementation

uses
  System.SysUtils;

{ TEngineScriptSourceProvider }

constructor TEngineScriptSourceProvider.Create(const APakFiles: IPakFileSystem);
begin
  inherited Create;
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create('APakFiles');
  FPakFiles := APakFiles;
end;

function TEngineScriptSourceProvider.ReadText(const AFileName: string): string;
begin
  Result := FPakFiles.ReadText(AFileName);
end;

end.
