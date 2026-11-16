{******************************************************************************}
{                                                                              }
{  DelphiDoom: where the #include of the scripts finds its text                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.IncludeSource;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>Files of the disk and of the PAK files, and the lumps of the WAD files</summary>
  TEngineIncludeSource = class(TInterfacedObject, IScriptIncludeSource)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function ReadFile(const AName: string): string;
    function ReadAllFiles(const AName: string): string;
    function ReadLump(const AName: string): string;
  end;

implementation

uses
  System.SysUtils,
  w_pak;

{ TEngineIncludeSource }

constructor TEngineIncludeSource.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineIncludeSource.ReadFile(const AName: string): string;
begin
  Result := PAK_ReadFileAsString(AName);
end;

function TEngineIncludeSource.ReadAllFiles(const AName: string): string;
begin
  Result := PAK_ReadAllFilesAsString(AName);
end;

function TEngineIncludeSource.ReadLump(const AName: string): string;
var
  LLump: Integer;
begin
  LLump := FLumps.CheckNumForName(AName);
  if LLump >= 0 then
    Result := FLumps.TextOf(LLump)
  else
    Result := '';
end;

end.
