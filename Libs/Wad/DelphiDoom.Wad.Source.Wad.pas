{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: WAD (IWAD, PWAD, DWAD)                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Wad;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Source.Base;

type
  /// <summary>
  ///   A WAD: header, lumps and a directory at the end. Reads the directory
  ///   when it is created; a lump is read when it is asked for
  /// </summary>
  TWadFileSource = class(TWadStreamSource)
  public
    /// <summary>Raises EWadException when AStream is not a WAD or its directory is damaged</summary>
    constructor Create(const AName: string; AStream: TStream; AOwnsStream: Boolean);
    /// <summary>
    ///   True when ABytes starts with the identification of a WAD
    /// </summary>
    class function IsWad(const ABytes: TBytes): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SNotAWad = '%s is not a WAD: it does not start with IWAD, PWAD or DWAD';
  SBadDirectory = 'The directory of %s is damaged (%d lumps at %d, the file has %d bytes)';

function IsWadIdentification(AIdentification: Integer): Boolean;
begin
  Result := (AIdentification = WAD_ID_IWAD) or (AIdentification = WAD_ID_PWAD) or
    (AIdentification = WAD_ID_DWAD);
end;

{ TWadFileSource }

constructor TWadFileSource.Create(const AName: string; AStream: TStream;
  AOwnsStream: Boolean);
var
  LHeader: TWadHeader;
  LRecords: TArray<TWadDirectoryRecord>;
  LEntries: TArray<TWadEntry>;
  LIndex: Integer;
begin
  inherited Create(AName, TWadSourceKind.Wad, AStream, AOwnsStream);
  if AStream.Size < WAD_HEADER_SIZE then
    raise EWadException.CreateFmt(SNotAWad, [AName]);
  AStream.Position := 0;
  AStream.ReadBuffer(LHeader, SizeOf(LHeader));
  if not IsWadIdentification(LHeader.Identification) then
    raise EWadException.CreateFmt(SNotAWad, [AName]);
  if (LHeader.NumLumps < 0) or (LHeader.InfoTableOfs < 0) or
     (Int64(LHeader.InfoTableOfs) + Int64(LHeader.NumLumps) * WAD_DIRECTORY_RECORD_SIZE >
      AStream.Size) then
    raise EWadException.CreateFmt(SBadDirectory,
      [AName, LHeader.NumLumps, LHeader.InfoTableOfs, AStream.Size]);

  SetLength(LRecords, LHeader.NumLumps);
  if LHeader.NumLumps > 0 then
  begin
    AStream.Position := LHeader.InfoTableOfs;
    AStream.ReadBuffer(LRecords[0], LHeader.NumLumps * WAD_DIRECTORY_RECORD_SIZE);
  end;
  SetLength(LEntries, LHeader.NumLumps);
  for LIndex := 0 to LHeader.NumLumps - 1 do
  begin
    LEntries[LIndex].Name := TWadLumpName.FromRecord(LRecords[LIndex]);
    LEntries[LIndex].Offset := LRecords[LIndex].FilePos;
    LEntries[LIndex].Size := LRecords[LIndex].Size;
  end;
  SetEntries(LEntries);
end;

class function TWadFileSource.IsWad(const ABytes: TBytes): Boolean;
var
  LId: Integer;
begin
  Result := Length(ABytes) >= 4;
  if Result then
  begin
    Move(ABytes[0], LId, SizeOf(LId));
    Result := IsWadIdentification(LId);
  end;
end;

end.
