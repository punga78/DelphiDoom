{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - loads DDMikmod.dll and creates the IMikMod it exports  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Mikmod.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IMikMod and unloads it when
  ///   destroyed, after having shut the sound library down and released the
  ///   interface
  /// </summary>
  /// <remarks>
  ///   Every IMikMod and IMikModPlayer obtained from MikMod must be released
  ///   before the loader is destroyed, because their code lives inside the DLL
  /// </remarks>
  TMikModLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FMikMod: IMikMod;
  public
    constructor Create(const ALibraryName: string = DDMIKMOD_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property MikMod: IMikMod read FMikMod;
  end;

implementation

{ TMikModLoader }

constructor TMikModLoader.Create(const ALibraryName: string);
var
  LCreate: TDDMikmodCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EMikModException.CreateCode(MIKMOD_ERR_LOAD_LIBRARY,
      Format('Cannot load %s: %s', [FLibraryName, SysErrorMessage(GetLastError)]));

  // GetProcAddress takes an ANSI name: the string constant converts as is
  LCreate := TDDMikmodCreate(GetProcAddress(FHandle, DDMIKMOD_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EMikModException.CreateCode(MIKMOD_ERR_LOAD_LIBRARY,
      Format('%s does not export %s', [FLibraryName, DDMIKMOD_CREATE_EXPORT]));

  LCode := LCreate(FMikMod);
  if (LCode <> MIKMOD_OK) or not Assigned(FMikMod) then
    raise EMikModException.CreateCode(LCode);
end;

destructor TMikModLoader.Destroy;
begin
  if Assigned(FMikMod) then
  begin
    FMikMod.Shutdown;
    FMikMod := nil;
  end;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
