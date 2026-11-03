{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - loads DDJpeg.dll and creates the IJpeg it exports        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IJpeg and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every IJpeg obtained from Jpeg must be released before the loader is
  ///   destroyed, because its code lives inside the DLL
  /// </remarks>
  TJpegLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FJpeg: IJpeg;
  public
    constructor Create(const ALibraryName: string = DDJPEG_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Jpeg: IJpeg read FJpeg;
  end;

implementation

{ TJpegLoader }

constructor TJpegLoader.Create(const ALibraryName: string);
var
  LCreate: TDDJpegCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EJpegException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDJpegCreate(GetProcAddress(FHandle, DDJPEG_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EJpegException.CreateFmt('%s does not export %s',
      [FLibraryName, DDJPEG_CREATE_EXPORT]);

  LCode := LCreate(FJpeg);
  if (LCode <> DDJPEG_OK) or not Assigned(FJpeg) then
    raise EJpegException.CreateCode(LCode);
end;

destructor TJpegLoader.Destroy;
begin
  FJpeg := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
