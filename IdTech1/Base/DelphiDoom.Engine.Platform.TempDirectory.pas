{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the temporary files go                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Platform.TempDirectory;

interface

uses
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   ITempDirectory of the engine: DATA\TMP\ next to the save files (with the working
  ///   directory of the CD-ROM when the game runs from one)
  /// </summary>
  TEngineTempDirectory = class(TInterfacedObject, ITempDirectory)
  strict private
    FSaveFileNames: ISaveFileNames;
  public
    /// <param name="ASaveFileNames">Puts DATA\ in the working folder of the CD-ROM when needed</param>
    constructor Create(const ASaveFileNames: ISaveFileNames);
    function Directory: string;
  end;

implementation

uses
  System.SysUtils;

const
  SSaveFileNamesIsNil = 'TEngineTempDirectory: the names of the saved files are nil';

{ TEngineTempDirectory }

constructor TEngineTempDirectory.Create(const ASaveFileNames: ISaveFileNames);
begin
  inherited Create;
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create(SSaveFileNamesIsNil);
  FSaveFileNames := ASaveFileNames;
end;

function TEngineTempDirectory.Directory: string;
begin
  Result := FSaveFileNames.ResolveName('DATA\') + 'TMP\';
end;

end.
