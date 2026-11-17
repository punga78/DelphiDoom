{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - opens a folder                            }
{  (CrossPlatform::openExplorer) Derived from OpenXcom (the OpenXcom           }
{  Developers), available under the GNU General Public License, version 3 or   }
{  (at your option) any later version; see Games\XcomFormats\README.md for     }
{  the license of this unit                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FolderOpener.Intf;

interface

type
  /// <summary>Shows a folder to the user (the file explorer); the menus never open a window themselves</summary>
  IXcomFolderOpener = interface
    ['{6A1D9B58-2E47-4C0F-9F3A-7B5C8E1D4A62}']
    procedure Open(const APath: string);
  end;

implementation

end.