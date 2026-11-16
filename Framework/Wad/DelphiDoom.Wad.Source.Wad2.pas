{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: Quake WAD2 and WAD3                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Wad2;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Source.Base;

type
  /// <summary>
  ///   A Quake WAD2 or Half-Life WAD3: 'WAD2' or 'WAD3', the number of entries and the
  ///   offset of the directory; records of 32 bytes (offset, size on disk, size, type,
  ///   compression, 2 unused bytes and a name of 16). Names are kept upper case. The
  ///   size is the uncompressed one: compressed entries are not decompressed
  /// </summary>
  TWad2FileSource = class(TWadStreamSource)
  public
    /// <summary>Raises EWadException when AStream is not a WAD2/WAD3 or its directory is damaged</summary>
    constructor Create(const AName: string; AStream: TStream; AOwnsStream: Boolean);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SNotAWad2 = '%s is not a WAD2 or WAD3';
  SBadWad2Directory = 'The directory of %s is damaged (%d entries at %d, the file has %d bytes)';

type
  TWad2Record = packed record
    Offset: Integer;
    DiskSize: Integer;
    Size: Integer;
    EntryType: AnsiChar;
    Compression: AnsiChar;
    Padding: array[0..1] of AnsiChar;
    Name: array[0..15] of AnsiChar;
  end;

{ TWad2FileSource }

constructor TWad2FileSource.Create(const AName: string; AStream: TStream;
  AOwnsStream: Boolean);
var
  LId, LCount, LTable, LIndex, LCharIndex: Integer;
  LRecords: TArray<TWad2Record>;
  LEntries: TArray<TWadEntry>;
  LName: string;
begin
  inherited Create(AName, TWadSourceKind.Wad, AStream, AOwnsStream);
  if AStream.Size < WAD_HEADER_SIZE then
    raise EWadException.CreateFmt(SNotAWad2, [AName]);
  AStream.Position := 0;
  AStream.ReadBuffer(LId, SizeOf(LId));
  if (LId <> WAD2_ID) and (LId <> WAD3_ID) then
    raise EWadException.CreateFmt(SNotAWad2, [AName]);
  AStream.ReadBuffer(LCount, SizeOf(LCount));
  AStream.ReadBuffer(LTable, SizeOf(LTable));
  if (LCount < 0) or (LTable < 0) or
     (Int64(LTable) + Int64(LCount) * SizeOf(TWad2Record) > AStream.Size) then
    raise EWadException.CreateFmt(SBadWad2Directory, [AName, LCount, LTable, AStream.Size]);

  SetLength(LRecords, LCount);
  if LCount > 0 then
  begin
    AStream.Position := LTable;
    AStream.ReadBuffer(LRecords[0], LCount * SizeOf(TWad2Record));
  end;
  SetLength(LEntries, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LName := '';
    for LCharIndex := 0 to High(LRecords[LIndex].Name) do
    begin
      if LRecords[LIndex].Name[LCharIndex] = #0 then
        Break;
      LName := LName + Char(Ord(LRecords[LIndex].Name[LCharIndex]));
    end;
    LEntries[LIndex].Name := TWadLumpName.UpperCase(LName);
    LEntries[LIndex].Offset := LRecords[LIndex].Offset;
    LEntries[LIndex].Size := LRecords[LIndex].Size;
  end;
  SetEntries(LEntries);
end;

end.
