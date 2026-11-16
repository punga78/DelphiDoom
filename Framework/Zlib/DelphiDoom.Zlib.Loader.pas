{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - loads DDZlib.dll and creates the IZlib it exports        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Zlib.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IZlib and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every IZlib obtained from Zlib must be released before the loader is
  ///   destroyed, because its code lives inside the DLL
  /// </remarks>
  TZlibLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FZlib: IZlib;
  public
    constructor Create(const ALibraryName: string = DDZLIB_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Zlib: IZlib read FZlib;
  end;

implementation

{ TZlibLoader }

constructor TZlibLoader.Create(const ALibraryName: string);
var
  LCreate: TDDZlibCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EZlibException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDZlibCreate(GetProcAddress(FHandle, DDZLIB_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EZlibException.CreateFmt('%s does not export %s',
      [FLibraryName, DDZLIB_CREATE_EXPORT]);

  LCode := LCreate(FZlib);
  if (LCode <> ZLIB_OK) or not Assigned(FZlib) then
    raise EZlibException.CreateCode(LCode);
end;

destructor TZlibLoader.Destroy;
begin
  FZlib := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
