{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - reads a saved game                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Save.Reader;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.War.Save.Types;

type
  /// <summary>
  ///   Reads the bytes of a saved game and checks them before the game plays a single frame of it: the magic, the
  ///   versions, the size of the file, the checksum and the data of the game it was played with. Everything that is
  ///   wrong is an EWarSaveException with a message that says what
  /// </summary>
  TWarSaveReader = class
  public
    /// <summary>The event of a record</summary>
    class function RecordToEvent(const ARecord: TWarSaveEventRecord): TGameHostEvent; static;
    /// <summary>
    ///   The game in the bytes; ADataSize is the size of the DATA.WAR in use (a game played with another file is
    ///   refused)
    /// </summary>
    class function Read(const ABytes: TBytes; ADataSize: Cardinal): TWarSaveContent; static;
  end;

implementation

uses
  DelphiDoom.War.Save.Checksum;

resourcestring
  SWarSaveTooShort = 'The file is too short to be a saved game of Warcraft32';
  SWarSaveNotASave = 'The file is not a saved game of Warcraft32';
  SWarSaveFormat = 'The saved game has the format %d and this program reads the format %d';
  SWarSaveModel = 'The saved game was played with the rules %d and this program has the rules %d';
  SWarSaveData = 'The saved game was played with a DATA.WAR of %d bytes and the one in use has %d';
  SWarSaveDamaged = 'The saved game is damaged (the checksum does not match)';
  SWarSaveTruncated = 'The saved game is cut short';
  SWarSaveEventKind = 'The saved game has an event of the kind %d, which does not exist';
  SWarSaveCounts = 'The saved game does not have the frames and events its header says';

{ TWarSaveReader }

class function TWarSaveReader.RecordToEvent(const ARecord: TWarSaveEventRecord): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(TGameHostEventKind(ARecord.Kind));
  Result.VirtualKey := ARecord.VirtualKey;
  Result.Character := ARecord.Character;
  Result.Modifiers := [];
  if ARecord.Flags and 1 <> 0 then
    Include(Result.Modifiers, hmShift);
  if ARecord.Flags and 2 <> 0 then
    Include(Result.Modifiers, hmControl);
  if ARecord.Flags and 4 <> 0 then
    Include(Result.Modifiers, hmAlt);
  Result.Button := TGameHostMouseButton((ARecord.Flags shr 3) and 3);
  Result.Focused := ARecord.Flags and 32 <> 0;
  Result.Minimized := ARecord.Flags and 64 <> 0;
  Result.X := ARecord.X;
  Result.Y := ARecord.Y;
end;

class function TWarSaveReader.Read(const ABytes: TBytes; ADataSize: Cardinal): TWarSaveContent;
var
  LHeader: TWarSaveHeader;
  LFrameHeader: TWarSaveFrameHeader;
  LRecord: TWarSaveEventRecord;
  LOffset: Integer;
  LLimit: Integer;
  LStored: Cardinal;
  LFrame: Integer;
  LEvent: Integer;
  LEvents: Cardinal;
begin
  if Length(ABytes) < SizeOf(LHeader) + SizeOf(Cardinal) then
    raise EWarSaveException.Create(SWarSaveTooShort);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if not CompareMem(@LHeader.Magic, @WAR_SAVE_MAGIC, SizeOf(WAR_SAVE_MAGIC)) then
    raise EWarSaveException.Create(SWarSaveNotASave);
  if LHeader.FormatVersion <> WAR_SAVE_FORMAT_VERSION then
    raise EWarSaveException.CreateFmt(SWarSaveFormat, [LHeader.FormatVersion, WAR_SAVE_FORMAT_VERSION]);
  if LHeader.ModelVersion <> WAR_SAVE_MODEL_VERSION then
    raise EWarSaveException.CreateFmt(SWarSaveModel, [LHeader.ModelVersion, WAR_SAVE_MODEL_VERSION]);
  LLimit := Length(ABytes) - SizeOf(Cardinal);
  Move(ABytes[LLimit], LStored, SizeOf(LStored));
  if LStored <> TWarSaveChecksum.Compute(ABytes, LLimit) then
    raise EWarSaveException.Create(SWarSaveDamaged);
  if LHeader.DataSize <> ADataSize then
    raise EWarSaveException.CreateFmt(SWarSaveData, [LHeader.DataSize, ADataSize]);
  if Int64(LHeader.FrameCount) * SizeOf(LFrameHeader) + SizeOf(LHeader) > LLimit then
    raise EWarSaveException.Create(SWarSaveTruncated);
  Result := Default(TWarSaveContent);
  Result.Seed := LHeader.Seed;
  Result.DataSize := LHeader.DataSize;
  Result.StartRace := LHeader.StartRace;
  Result.StartMission := LHeader.StartMission;
  SetLength(Result.Frames, Integer(LHeader.FrameCount));
  LOffset := SizeOf(LHeader);
  LEvents := 0;
  for LFrame := 0 to High(Result.Frames) do
  begin
    if LOffset + SizeOf(LFrameHeader) > LLimit then
      raise EWarSaveException.Create(SWarSaveTruncated);
    Move(ABytes[LOffset], LFrameHeader, SizeOf(LFrameHeader));
    Inc(LOffset, SizeOf(LFrameHeader));
    if LOffset + Integer(LFrameHeader.EventCount) * SizeOf(LRecord) > LLimit then
      raise EWarSaveException.Create(SWarSaveTruncated);
    Result.Frames[LFrame].Delta := LFrameHeader.Delta;
    SetLength(Result.Frames[LFrame].Events, LFrameHeader.EventCount);
    for LEvent := 0 to LFrameHeader.EventCount - 1 do
    begin
      Move(ABytes[LOffset], LRecord, SizeOf(LRecord));
      Inc(LOffset, SizeOf(LRecord));
      if LRecord.Kind > Ord(High(TGameHostEventKind)) then
        raise EWarSaveException.CreateFmt(SWarSaveEventKind, [LRecord.Kind]);
      Result.Frames[LFrame].Events[LEvent] := RecordToEvent(LRecord);
    end;
    Inc(LEvents, LFrameHeader.EventCount);
  end;
  if (LOffset <> LLimit) or (LEvents <> LHeader.EventCount) then
    raise EWarSaveException.Create(SWarSaveCounts);
end;

end.
