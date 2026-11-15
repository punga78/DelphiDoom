{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - writes a saved game                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Save.Writer;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.War.Save.Types;

type
  /// <summary>
  ///   Turns a saved game in memory into the bytes of the file: the header, each frame with its events and, at the end,
  ///   the checksum of everything before it
  /// </summary>
  TWarSaveWriter = class
  public
    /// <summary>The event as it is written; the events that no game reads (resize, wheel, quit) are not saved</summary>
    class function EventToRecord(const AEvent: TGameHostEvent): TWarSaveEventRecord; static;
    /// <summary>True for the events that the game can see and so belong to a saved game</summary>
    class function IsSaved(const AEvent: TGameHostEvent): Boolean; static;
    /// <summary>The bytes of the file; EWarSaveException if a frame has more events than a file can hold</summary>
    class function Write(const AContent: TWarSaveContent): TBytes; static;
  end;

implementation

uses
  DelphiDoom.War.Save.Checksum;

resourcestring
  SWarSaveTooManyEvents = 'The frame %d has %d events: a saved game holds at most %d';

{ TWarSaveWriter }

class function TWarSaveWriter.IsSaved(const AEvent: TGameHostEvent): Boolean;
begin
  Result := AEvent.Kind in [hekKeyDown, hekKeyUp, hekMouseMotion, hekMouseDown, hekMouseUp, hekActive];
end;

class function TWarSaveWriter.EventToRecord(const AEvent: TGameHostEvent): TWarSaveEventRecord;
var
  LFlags: Byte;
begin
  Result := Default(TWarSaveEventRecord);
  Result.Kind := Byte(Ord(AEvent.Kind));
  LFlags := 0;
  if hmShift in AEvent.Modifiers then
    LFlags := LFlags or 1;
  if hmControl in AEvent.Modifiers then
    LFlags := LFlags or 2;
  if hmAlt in AEvent.Modifiers then
    LFlags := LFlags or 4;
  LFlags := LFlags or Byte(Ord(AEvent.Button) shl 3);
  if AEvent.Focused then
    LFlags := LFlags or 32;
  if AEvent.Minimized then
    LFlags := LFlags or 64;
  Result.Flags := LFlags;
  Result.VirtualKey := Word(AEvent.VirtualKey);
  Result.Character := AEvent.Character;
  Result.X := SmallInt(AEvent.X);
  Result.Y := SmallInt(AEvent.Y);
end;

class function TWarSaveWriter.Write(const AContent: TWarSaveContent): TBytes;
var
  LHeader: TWarSaveHeader;
  LFrameHeader: TWarSaveFrameHeader;
  LRecord: TWarSaveEventRecord;
  LFrame: Integer;
  LEvent: Integer;
  LEvents: Integer;
  LSize: Integer;
  LOffset: Integer;
  LChecksum: Cardinal;
  LSaved: TArray<TGameHostEvent>;
begin
  LHeader := Default(TWarSaveHeader);
  Move(WAR_SAVE_MAGIC, LHeader.Magic, SizeOf(LHeader.Magic));
  LHeader.FormatVersion := WAR_SAVE_FORMAT_VERSION;
  LHeader.ModelVersion := WAR_SAVE_MODEL_VERSION;
  LHeader.Seed := AContent.Seed;
  LHeader.DataSize := AContent.DataSize;
  LHeader.StartRace := AContent.StartRace;
  LHeader.StartMission := AContent.StartMission;
  LHeader.FrameCount := Cardinal(Length(AContent.Frames));
  LEvents := 0;
  LSize := SizeOf(LHeader) + SizeOf(Cardinal);
  for LFrame := 0 to High(AContent.Frames) do
  begin
    LSaved := nil;
    for LEvent := 0 to High(AContent.Frames[LFrame].Events) do
      if IsSaved(AContent.Frames[LFrame].Events[LEvent]) then
        Inc(LEvents);
    LSize := LSize + SizeOf(LFrameHeader);
  end;
  LSize := LSize + LEvents * SizeOf(LRecord);
  LHeader.EventCount := Cardinal(LEvents);
  SetLength(Result, LSize);
  Move(LHeader, Result[0], SizeOf(LHeader));
  LOffset := SizeOf(LHeader);
  for LFrame := 0 to High(AContent.Frames) do
  begin
    LSaved := nil;
    for LEvent := 0 to High(AContent.Frames[LFrame].Events) do
      if IsSaved(AContent.Frames[LFrame].Events[LEvent]) then
        LSaved := LSaved + [AContent.Frames[LFrame].Events[LEvent]];
    if Length(LSaved) > WAR_SAVE_MAX_EVENTS_PER_FRAME then
      raise EWarSaveException.CreateFmt(SWarSaveTooManyEvents, [LFrame, Length(LSaved),
        WAR_SAVE_MAX_EVENTS_PER_FRAME]);
    LFrameHeader.Delta := AContent.Frames[LFrame].Delta;
    LFrameHeader.EventCount := Word(Length(LSaved));
    Move(LFrameHeader, Result[LOffset], SizeOf(LFrameHeader));
    Inc(LOffset, SizeOf(LFrameHeader));
    for LEvent := 0 to High(LSaved) do
    begin
      LRecord := EventToRecord(LSaved[LEvent]);
      Move(LRecord, Result[LOffset], SizeOf(LRecord));
      Inc(LOffset, SizeOf(LRecord));
    end;
  end;
  LChecksum := TWarSaveChecksum.Compute(Result, LOffset);
  Move(LChecksum, Result[LOffset], SizeOf(LChecksum));
end;

end.
