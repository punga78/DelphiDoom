{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the folders of the screenshots                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Screenshot.Folders;

interface

uses
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Screenshot.Intf;

type
  /// <summary>Answers the Screenshot library with the folder of the saved files of the engine</summary>
  TEngineScreenshotFolders = class(TInterfacedObject, IScreenshotFolders)
  strict private
    FSaveFileNames: ISaveFileNames;
  public
    /// <param name="ASaveFileNames">Gives the name that a file has in the folder of the saved files</param>
    constructor Create(const ASaveFileNames: ISaveFileNames);
    function PathOf(const ARelativeName: string): string;
  end;

implementation

uses
  System.SysUtils;

const
  SSaveFileNamesIsNil = 'TEngineScreenshotFolders: the names of the saved files are nil';

{ TEngineScreenshotFolders }

constructor TEngineScreenshotFolders.Create(const ASaveFileNames: ISaveFileNames);
begin
  inherited Create;
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create(SSaveFileNamesIsNil);
  FSaveFileNames := ASaveFileNames;
end;

function TEngineScreenshotFolders.PathOf(const ARelativeName: string): string;
begin
  Result := FSaveFileNames.ResolveName(ARelativeName);
end;

end.
