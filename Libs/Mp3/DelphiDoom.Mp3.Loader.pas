{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - loads DDMp3.dll and creates the IMp3 it exports           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Mp3.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IMp3 and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every IMp3 and IMp3Decoder obtained from Mp3 (also through a
  ///   TMp3Client) must be released before the loader is destroyed, because
  ///   their code lives inside the DLL
  /// </remarks>
  TMp3Loader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FMp3: IMp3;
  public
    constructor Create(const ALibraryName: string = DDMP3_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Mp3: IMp3 read FMp3;
  end;

implementation

{ TMp3Loader }

constructor TMp3Loader.Create(const ALibraryName: string);
var
  LCreate: TDDMp3Create;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EMp3Exception.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDMp3Create(GetProcAddress(FHandle, DDMP3_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EMp3Exception.CreateFmt('%s does not export %s',
      [FLibraryName, DDMP3_CREATE_EXPORT]);

  LCode := LCreate(FMp3);
  if (LCode <> MP3_OK) or not Assigned(FMp3) then
    raise EMp3Exception.CreateCode(LCode);
end;

destructor TMp3Loader.Destroy;
begin
  FMp3 := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
