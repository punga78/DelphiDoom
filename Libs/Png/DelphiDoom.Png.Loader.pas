{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - loads DDPng.dll and creates the IPng it exports           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Zlib.Intf, DelphiDoom.Png.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IPng and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   The DLL contains no zlib: it compresses and decompresses with the
  ///   IZlib it is given, which comes from DDZlib.dll (see TZlibLoader) or
  ///   from an engine linked in the executable. The IPng keeps that IZlib, so
  ///   the order of release is: every IPng obtained from Png, then this
  ///   loader, then the owner of the IZlib (the zlib loader, if any). Every
  ///   IPng must be released before the loader is destroyed, because its code
  ///   lives inside the DLL
  /// </remarks>
  TPngLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FPng: IPng;
  public
    constructor Create(const AZlib: IZlib;
      const ALibraryName: string = DDPNG_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Png: IPng read FPng;
  end;

implementation

{ TPngLoader }

constructor TPngLoader.Create(const AZlib: IZlib; const ALibraryName: string);
var
  LCreate: TDDPngCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EPngException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDPngCreate(GetProcAddress(FHandle, DDPNG_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EPngException.CreateFmt('%s does not export %s',
      [FLibraryName, DDPNG_CREATE_EXPORT]);

  LCode := LCreate(AZlib, FPng);
  if (LCode <> DDPNG_OK) or not Assigned(FPng) then
    raise EPngException.CreateCode(LCode);
end;

destructor TPngLoader.Destroy;
begin
  FPng := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
