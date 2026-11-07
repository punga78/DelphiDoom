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
  DelphiDoom.Screenshot.Intf;

type
  /// <summary>Answers the Screenshot library with the folder of the saved files of the engine</summary>
  TEngineScreenshotFolders = class(TInterfacedObject, IScreenshotFolders)
  public
    function PathOf(const ARelativeName: string): string;
  end;

implementation

uses
  m_argv;

{ TEngineScreenshotFolders }

function TEngineScreenshotFolders.PathOf(const ARelativeName: string): string;
begin
  Result := M_SaveFileName(ARelativeName);
end;

end.
