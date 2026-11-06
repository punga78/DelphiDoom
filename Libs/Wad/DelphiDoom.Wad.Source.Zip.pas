{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: ZIP (PK3)                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Zip;

interface

uses
  System.SysUtils, System.Classes, System.Zip, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   A ZIP (PK3): every file in it is a lump named by its path, upper case
  ///   with '/' as separator; folders are not lumps
  /// </summary>
  TZipFileSource = class(TInterfacedObject, IWadSource)
  private
    FName: string;
    FZip: TZipFile;
    FEntries: TArray<TWadEntry>;
    FZipIndex: TArray<Integer>;
  public
    /// <summary>Raises EWadException when AFileName is not a ZIP</summary>
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SNotAZip = '%s is not a ZIP file';
  SBadZipIndex = 'Lump %d does not exist in %s (it has %d)';

{ TZipFileSource }

constructor TZipFileSource.Create(const AFileName: string);
var
  LIndex, LCount: Integer;
  LName: string;
begin
  inherited Create;
  FName := AFileName;
  FZip := TZipFile.Create;
  try
    FZip.Open(AFileName, TZipMode.zmRead);
  except
    FreeAndNil(FZip);
    raise EWadException.CreateFmt(SNotAZip, [AFileName]);
  end;
  SetLength(FEntries, FZip.FileCount);
  SetLength(FZipIndex, FZip.FileCount);
  LCount := 0;
  for LIndex := 0 to FZip.FileCount - 1 do
  begin
    LName := StringReplace(FZip.FileNames[LIndex], '\', '/', [rfReplaceAll]);
    if (LName = '') or (LName[Length(LName)] = '/') then
      Continue;
    FEntries[LCount].Name := TWadLumpName.UpperCase(LName);
    FEntries[LCount].Offset := 0;
    FEntries[LCount].Size := Integer(FZip.FileInfos[LIndex].UncompressedSize);
    FZipIndex[LCount] := LIndex;
    Inc(LCount);
  end;
  SetLength(FEntries, LCount);
  SetLength(FZipIndex, LCount);
end;

destructor TZipFileSource.Destroy;
begin
  FZip.Free;
  inherited Destroy;
end;

function TZipFileSource.GetName: string;
begin
  Result := FName;
end;

function TZipFileSource.GetKind: TWadSourceKind;
begin
  Result := TWadSourceKind.Zip;
end;

function TZipFileSource.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TZipFileSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EWadException.CreateFmt(SBadZipIndex, [AIndex, FName, Length(FEntries)]);
  Result := FEntries[AIndex];
end;

function TZipFileSource.ReadEntry(AIndex: Integer): TBytes;
begin
  GetEntry(AIndex);
  FZip.Read(FZipIndex[AIndex], Result);
end;

end.
