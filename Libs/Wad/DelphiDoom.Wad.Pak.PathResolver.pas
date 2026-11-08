{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - how a name of the PAK file system is opened        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.PathResolver;

interface

uses
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Wad.Pak.Intf;

type
  /// <summary>
  ///   The rules of TPakStream.Create and of the POpen* functions of the old TPakManager: a file
  ///   on disk with the name as given wins over the PAK file system; then the index is asked by
  ///   full path, by short name or with the preferred folders (and their serial search when the
  ///   first choice cannot be read); a folder given apart is tried before the mode, or at the end
  ///   for a full path; whatever the mode, the name is tried again as a path with folders
  /// </summary>
  TPakPathResolver = class(TInterfacedObject, IPakPathResolver)
  strict private
    FIndex: IPakIndex;
    function OpenFull(const AName: string; const ADisk: TPakDiskOpener;
      const AEntry: TPakEntryOpener): Boolean;
    function OpenShort(const AName: string; const ADisk: TPakDiskOpener;
      const AEntry: TPakEntryOpener): Boolean;
    function OpenWithDirectory(const AName: string; const ADisk: TPakDiskOpener;
      const AEntry: TPakEntryOpener): Boolean;
    function OpenPreferred(const AName: string; const APreferred: TArray<string>;
      const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
    class function OpenFound(AFound: Integer; const AEntry: TPakEntryOpener): Boolean; static;
  public
    /// <summary>Raises EArgumentNilException when AIndex is nil</summary>
    constructor Create(const AIndex: IPakIndex);
    function Resolve(const AName: string; AMode: TPakLookupMode; const APreferred: TArray<string>;
      const ADirectory: string; const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Wad.Pak.Names;

const
  SIndexMissing = 'TPakPathResolver: the index is nil';

{ TPakPathResolver }

constructor TPakPathResolver.Create(const AIndex: IPakIndex);
begin
  inherited Create;
  if not Assigned(AIndex) then
    raise EArgumentNilException.Create(SIndexMissing);
  FIndex := AIndex;
end;

class function TPakPathResolver.OpenFound(AFound: Integer; const AEntry: TPakEntryOpener): Boolean;
begin
  // an entry that cannot be read is a failure: the old code did not look for another one
  Result := (AFound >= 0) and AEntry(AFound);
end;

function TPakPathResolver.OpenFull(const AName: string; const ADisk: TPakDiskOpener;
  const AEntry: TPakEntryOpener): Boolean;
begin
  Result := ADisk(AName) or OpenFound(FIndex.FindFull(AName), AEntry);
end;

function TPakPathResolver.OpenShort(const AName: string; const ADisk: TPakDiskOpener;
  const AEntry: TPakEntryOpener): Boolean;
begin
  Result := ADisk(AName) or OpenFound(FIndex.FindShort(AName), AEntry);
end;

function TPakPathResolver.OpenWithDirectory(const AName: string; const ADisk: TPakDiskOpener;
  const AEntry: TPakEntryOpener): Boolean;
var
  LName: string;
begin
  Result := False;
  LName := TPakNames.FixPath(AName);
  if (LName <> '') and (LName[1] = '\') then
  begin
    Delete(LName, 1, 1);
    if (LName <> '') and (LName[1] = '\') then
      Exit;
  end;
  LName := TPakNames.Trim(LName);
  if LName = '' then
    Exit;
  Result := ADisk(LName) or OpenFound(FIndex.FindWithDirectory(LName), AEntry);
end;

function TPakPathResolver.OpenPreferred(const AName: string; const APreferred: TArray<string>;
  const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
begin
  Result := ADisk(AName) or OpenFound(FIndex.FindPreferred(AName, APreferred), AEntry) or
    OpenFound(FIndex.FindPreferredSerial(AName, APreferred), AEntry);
end;

function TPakPathResolver.Resolve(const AName: string; AMode: TPakLookupMode;
  const APreferred: TArray<string>; const ADirectory: string; const ADisk: TPakDiskOpener;
  const AEntry: TPakEntryOpener): Boolean;
var
  LTriedDirectory: Boolean;
begin
  LTriedDirectory := False;
  if (ADirectory <> '') and (AMode <> TPakLookupMode.Full) then
  begin
    Result := OpenWithDirectory(ADirectory + '\' + AName, ADisk, AEntry);
    LTriedDirectory := True;
  end
  else
    case AMode of
      TPakLookupMode.Full:
        Result := OpenFull(AName, ADisk, AEntry);
      TPakLookupMode.Short:
        Result := OpenShort(AName, ADisk, AEntry);
      TPakLookupMode.Preferred:
        Result := OpenPreferred(AName, APreferred, ADisk, AEntry);
    else
      Result := False;
    end;

  if not Result then
  begin
    Result := OpenWithDirectory(AName, ADisk, AEntry);
    if not Result and not LTriedDirectory and (ADirectory <> '') then
      Result := OpenWithDirectory(ADirectory + '\' + AName, ADisk, AEntry);
  end;
end;

end.
