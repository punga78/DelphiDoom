{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - loads DDWad.dll                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IWadDll and unloads it when destroyed, after
  ///   having released the interface
  /// </summary>
  /// <remarks>
  ///   Every object obtained from Wad (sources, directories, builders and what the client
  ///   makes of them) must be released before the loader is destroyed, because its code
  ///   lives inside the DLL
  /// </remarks>
  TWadDllLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FWad: IWadDll;
  public
    constructor Create(const ALibraryName: string = DDWAD_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Wad: IWadDll read FWad;
  end;

implementation

{ TWadDllLoader }

constructor TWadDllLoader.Create(const ALibraryName: string);
var
  LCreate: TDDWadCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EWadDllException.CreateCode(WADDLL_ERR_NOT_FOUND,
      Format('Cannot load %s: %s', [FLibraryName, SysErrorMessage(GetLastError)]));

  LCreate := TDDWadCreate(GetProcAddress(FHandle, DDWAD_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EWadDllException.CreateCode(WADDLL_ERR_NOT_FOUND,
      Format('%s does not export %s', [FLibraryName, DDWAD_CREATE_EXPORT]));

  LCode := LCreate(FWad);
  if (LCode <> WADDLL_OK) or not Assigned(FWad) then
    raise EWadDllException.CreateCode(LCode);
end;

destructor TWadDllLoader.Destroy;
begin
  FWad := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited Destroy;
end;

end.
