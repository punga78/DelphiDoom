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
  DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   ITempDirectory of the engine: DATA\TMP\ next to the save files (with the working
  ///   directory of the CD-ROM when the game runs from one)
  /// </summary>
  TEngineTempDirectory = class(TInterfacedObject, ITempDirectory)
  public
    function Directory: string;
  end;

implementation

uses
  m_argv;

{ TEngineTempDirectory }

function TEngineTempDirectory.Directory: string;
begin
  Result := M_SaveFileName('DATA\') + 'TMP\';
end;

end.
