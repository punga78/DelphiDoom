{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: PAK (Quake)                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Pak;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Source.Base;

type
  /// <summary>
  ///   A PAK: 'PACK', the offset and the length of the directory; records of 64
  ///   bytes (a path of 56 and the offset and size). Names are kept upper case
  ///   with '/' as separator
  /// </summary>
  TPakFileSource = class(TWadStreamSource)
  public
    /// <summary>Raises EWadException when AStream is not a PAK or its directory is damaged</summary>
    constructor Create(const AName: string; AStream: TStream; AOwnsStream: Boolean);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SNotAPak = '%s is not a PAK';
  SBadPakDirectory = 'The directory of %s is damaged (%d bytes at %d, the file has %d bytes)';

{ TPakFileSource }

constructor TPakFileSource.Create(const AName: string; AStream: TStream;
  AOwnsStream: Boolean);
var
  LId, LDirectoryOffset, LDirectoryLength, LCount, LIndex, LCharIndex: Integer;
  LRecords: TArray<TPakDirectoryRecord>;
  LEntries: TArray<TWadEntry>;
  LName: string;
begin
  inherited Create(AName, TWadSourceKind.Pak, AStream, AOwnsStream);
  if AStream.Size < 12 then
    raise EWadException.CreateFmt(SNotAPak, [AName]);
  AStream.Position := 0;
  AStream.ReadBuffer(LId, SizeOf(LId));
  if LId <> PAK_ID then
    raise EWadException.CreateFmt(SNotAPak, [AName]);
  AStream.ReadBuffer(LDirectoryOffset, SizeOf(LDirectoryOffset));
  AStream.ReadBuffer(LDirectoryLength, SizeOf(LDirectoryLength));
  if (LDirectoryOffset < 0) or (LDirectoryLength < 0) or
     (Int64(LDirectoryOffset) + LDirectoryLength > AStream.Size) then
    raise EWadException.CreateFmt(SBadPakDirectory,
      [AName, LDirectoryLength, LDirectoryOffset, AStream.Size]);

  LCount := LDirectoryLength div PAK_DIRECTORY_RECORD_SIZE;
  SetLength(LRecords, LCount);
  if LCount > 0 then
  begin
    AStream.Position := LDirectoryOffset;
    AStream.ReadBuffer(LRecords[0], LCount * PAK_DIRECTORY_RECORD_SIZE);
  end;
  SetLength(LEntries, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LName := '';
    for LCharIndex := 0 to PAK_NAME_SIZE - 1 do
    begin
      if LRecords[LIndex].Name[LCharIndex] = #0 then
        Break;
      LName := LName + Char(Ord(LRecords[LIndex].Name[LCharIndex]));
    end;
    LEntries[LIndex].Name := TWadLumpName.UpperCase(StringReplace(LName, '\', '/', [rfReplaceAll]));
    LEntries[LIndex].Offset := LRecords[LIndex].FilePos;
    LEntries[LIndex].Size := LRecords[LIndex].Size;
  end;
  SetEntries(LEntries);
end;

end.
