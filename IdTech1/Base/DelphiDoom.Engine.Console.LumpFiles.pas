{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where savelumptodisk writes                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.LumpFiles;

{$I Doom32.inc}

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf, DelphiDoom.Console.Intf,
  DelphiDoom.Engine.Platform.Intf;

type
  /// <summary>
  ///   The folder of the saves of the command line (what M_SaveFileName gives) and the files of
  ///   the engine (M_WriteFile)
  /// </summary>
  TEngineConsoleLumpFiles = class(TInterfacedObject, IConsoleLumpFiles)
  strict private
    FFiles: IEngineFiles;
    FSaveFileNames: ISaveFileNames;
  public
    /// <summary>EArgumentNilException if a parameter is nil</summary>
    constructor Create(const AFiles: IEngineFiles; const ASaveFileNames: ISaveFileNames);
    function SaveFileName(const AFileName: string): string;
    function WriteFile(const AFileName: string; const AData: TBytes): Boolean;
  end;

implementation

{ TEngineConsoleLumpFiles }

constructor TEngineConsoleLumpFiles.Create(const AFiles: IEngineFiles;
  const ASaveFileNames: ISaveFileNames);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create('ASaveFileNames');
  FFiles := AFiles;
  FSaveFileNames := ASaveFileNames;
end;

function TEngineConsoleLumpFiles.SaveFileName(const AFileName: string): string;
begin
  Result := FSaveFileNames.ResolveName(AFileName);
end;

function TEngineConsoleLumpFiles.WriteFile(const AFileName: string; const AData: TBytes): Boolean;
begin
  Result := FFiles.WriteFile(AFileName, Pointer(AData), Length(AData));
end;

end.
