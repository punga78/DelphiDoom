{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - loads DDSndfile.dll and creates the ISndfile       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an ISndfile and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every ISndfile and ISoundFile obtained from Sndfile must be released
  ///   before the loader is destroyed, because their code lives inside the DLL
  /// </remarks>
  TSndfileLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FSndfile: ISndfile;
  public
    constructor Create(const ALibraryName: string = DDSNDFILE_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Sndfile: ISndfile read FSndfile;
  end;

implementation

{ TSndfileLoader }

constructor TSndfileLoader.Create(const ALibraryName: string);
var
  LCreate: TDDSndfileCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise ESndfileException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDSndfileCreate(GetProcAddress(FHandle, DDSNDFILE_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise ESndfileException.CreateFmt('%s does not export %s',
      [FLibraryName, DDSNDFILE_CREATE_EXPORT]);

  LCode := LCreate(FSndfile);
  if (LCode <> SNDFILE_OK) or not Assigned(FSndfile) then
    raise ESndfileException.CreateCode(LCode);
end;

destructor TSndfileLoader.Destroy;
begin
  FSndfile := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
