{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - shows a folder in the file explorer of Windows        }
{  (CrossPlatform::openExplorer)                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.FolderOpener;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, DelphiDoom.XcomEngine.FolderOpener.Intf;

type
  /// <summary>IXcomFolderOpener on ShellExecute: the explorer opens the folder (a path that is not a folder is ignored)</summary>
  TXcomWinFolderOpener = class(TInterfacedObject, IXcomFolderOpener)
  public
    procedure Open(const APath: string);
  end;

implementation

procedure TXcomWinFolderOpener.Open(const APath: string);
begin
  if (APath <> '') and DirectoryExists(APath) then
    ShellExecute(0, 'open', PChar(APath), nil, nil, SW_SHOWNORMAL);
end;

end.