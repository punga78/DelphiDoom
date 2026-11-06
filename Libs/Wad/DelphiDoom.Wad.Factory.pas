{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - factory: the composition root                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Factory;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   The only place that knows the concrete classes of the library: opens
  ///   the right source for a path or for bytes, and makes directories,
  ///   caches and builders
  /// </summary>
  TWadFactory = class
  public
    /// <summary>
    ///   A folder, or the file by what it starts with: WAD (IWAD, PWAD, DWAD),
    ///   PAK, ZIP; any other file is a single lump. Raises EWadException when
    ///   the path does not exist or the container is damaged
    /// </summary>
    class function OpenPath(const APath: string): IWadSource; static;
    /// <summary>A WAD or a PAK held in memory; AName only names it in messages</summary>
    class function OpenBytes(const AName: string; const ABytes: TBytes): IWadSource; static;
    class function CreateDirectory: IWadDirectory; static;
    class function CreateFinder(const ADirectory: IWadDirectory): IWadFinder; static;
    class function CreateReader(const ADirectory: IWadDirectory): ILumpReader; static;
    class function CreateCache(const AReader: ILumpReader): ILumpCache; static;
    class function CreateBuilder(AKind: TWadKind = TWadKind.PWad): IWadBuilder; static;
  end;

implementation

uses
  DelphiDoom.Wad.Directory, DelphiDoom.Wad.LumpCache, DelphiDoom.Wad.Builder,
  DelphiDoom.Wad.Source.Wad, DelphiDoom.Wad.Source.Pak, DelphiDoom.Wad.Source.Zip,
  DelphiDoom.Wad.Source.Folder, DelphiDoom.Wad.Source.SingleFile;

const
  SNoSuchPath = 'The path %s does not exist';
  SUnknownContainer = '%s is not a WAD, a PAK or a ZIP';

{ TWadFactory }

class function TWadFactory.OpenPath(const APath: string): IWadSource;
var
  LStream: TFileStream;
  LId: Integer;
begin
  if TDirectory.Exists(APath) then
    Exit(TFolderSource.Create(APath));
  if not TFile.Exists(APath) then
    raise EWadException.CreateFmt(SNoSuchPath, [APath]);

  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  LId := 0;
  try
    if LStream.Size >= SizeOf(LId) then
      LStream.ReadBuffer(LId, SizeOf(LId));
  except
    LStream.Free;
    raise;
  end;
  // from here a source owns the stream, and frees it if its constructor fails
  if (LId = WAD_ID_IWAD) or (LId = WAD_ID_PWAD) or (LId = WAD_ID_DWAD) then
    Result := TWadFileSource.Create(APath, LStream, True)
  else if LId = PAK_ID then
    Result := TPakFileSource.Create(APath, LStream, True)
  else if LId = ZIP_ID then
  begin
    // TZipFile opens the file by itself
    LStream.Free;
    Result := TZipFileSource.Create(APath);
  end
  else
    Result := TSingleFileSource.Create(APath, LStream, True);
end;

class function TWadFactory.OpenBytes(const AName: string; const ABytes: TBytes): IWadSource;
var
  LStream: TBytesStream;
  LId: Integer;
begin
  LId := 0;
  if Length(ABytes) >= SizeOf(LId) then
    Move(ABytes[0], LId, SizeOf(LId));
  if (LId <> WAD_ID_IWAD) and (LId <> WAD_ID_PWAD) and (LId <> WAD_ID_DWAD) and (LId <> PAK_ID) then
    raise EWadException.CreateFmt(SUnknownContainer, [AName]);
  LStream := TBytesStream.Create(ABytes);
  if LId = PAK_ID then
    Result := TPakFileSource.Create(AName, LStream, True)
  else
    Result := TWadFileSource.Create(AName, LStream, True);
end;

class function TWadFactory.CreateDirectory: IWadDirectory;
begin
  Result := TWadDirectory.Create;
end;

class function TWadFactory.CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
begin
  if not Supports(ADirectory, IWadFinder, Result) then
    raise EWadException.Create('The directory does not search by name');
end;

class function TWadFactory.CreateReader(const ADirectory: IWadDirectory): ILumpReader;
begin
  if not Supports(ADirectory, ILumpReader, Result) then
    raise EWadException.Create('The directory does not read lumps');
end;

class function TWadFactory.CreateCache(const AReader: ILumpReader): ILumpCache;
begin
  Result := TLumpCache.Create(AReader);
end;

class function TWadFactory.CreateBuilder(AKind: TWadKind): IWadBuilder;
begin
  Result := TWadBuilder.Create(AKind);
end;

end.
