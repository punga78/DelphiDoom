{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: reading a tape               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Reader;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Demo.Types;

type
  /// <summary>
  ///   Reads a tape written by TGreedDemoWriter from its bytes. A tape that does not start with "GRDM", of another
  ///   version or cut in the middle of a record is EGreedDemoException; a tape without its end record ends where
  ///   its bytes end
  /// </summary>
  TGreedDemoReader = class
  strict private
    FBytes: TBytes;
    FPosition: Integer;
    FHeader: TGreedDemoHeader;
    FPeeked: Boolean;
    FNext: TGreedDemoRecord;
    FClockRepeat: Cardinal;
    function ReadByte: Byte;
    function ReadInt32: Integer;
    function ReadRecord: TGreedDemoRecord;
  public
    /// <summary>Reads the header</summary>
    constructor Create(const ABytes: TBytes);
    /// <summary>The kind of the next record, without taking it; gdrEnd when the tape is over</summary>
    function PeekKind: TGreedDemoRecordKind;
    /// <summary>The next record without taking it</summary>
    function Peek: TGreedDemoRecord;
    /// <summary>Takes the next record; at the end of the tape it gives gdrEnd again and again</summary>
    function Next: TGreedDemoRecord;
    property Header: TGreedDemoHeader read FHeader;
  end;

implementation

constructor TGreedDemoReader.Create(const ABytes: TBytes);
var
  LIndex, LVersion: Integer;
begin
  inherited Create;
  FBytes := ABytes;
  if Length(FBytes) < Length(GREED_DEMO_MAGIC) then
    raise EGreedDemoException.Create(SGreedDemoBadMagic);
  for LIndex := Low(GREED_DEMO_MAGIC) to High(GREED_DEMO_MAGIC) do
    if FBytes[LIndex] <> GREED_DEMO_MAGIC[LIndex] then
      raise EGreedDemoException.Create(SGreedDemoBadMagic);
  FPosition := Length(GREED_DEMO_MAGIC);
  LVersion := ReadInt32;
  if LVersion <> GREED_DEMO_VERSION then
    raise EGreedDemoException.CreateFmt(SGreedDemoBadVersion, [LVersion, GREED_DEMO_VERSION]);
  FHeader.Map := ReadInt32;
  FHeader.Character := ReadInt32;
  FHeader.Difficulty := ReadInt32;
  FHeader.Episode := ReadInt32;
  FHeader.DemoEdition := ReadInt32 <> 0;
  FHeader.LowResolution := ReadInt32 <> 0;
  FHeader.RandomOffset := ReadInt32;
  FHeader.CameraDelay := ReadInt32;
  FHeader.ViewSize := ReadInt32;
  FHeader.Violence := ReadInt32 <> 0;
end;

function TGreedDemoReader.ReadByte: Byte;
begin
  if FPosition >= Length(FBytes) then
    raise EGreedDemoException.CreateFmt(SGreedDemoTruncated, [FPosition]);
  Result := FBytes[FPosition];
  Inc(FPosition);
end;

function TGreedDemoReader.ReadInt32: Integer;
var
  LValue: Cardinal;
  LByte: Cardinal;
begin
  // one byte at a time and in separate statements: the order in which they are read is the order of the file
  LByte := ReadByte;
  LValue := LByte;
  LByte := ReadByte;
  LValue := LValue or (LByte shl 8);
  LByte := ReadByte;
  LValue := LValue or (LByte shl 16);
  LByte := ReadByte;
  LValue := LValue or (LByte shl 24);
  Result := Integer(LValue);
end;

function TGreedDemoReader.ReadRecord: TGreedDemoRecord;
var
  LKind, LCount: Byte;
  LBits: array[0..5] of Byte;
  LButtons: Byte;
  LIndex: Integer;
  LCommand: TGreedCommand;
  LButton: TGreedMouseButton;
begin
  Result := Default(TGreedDemoRecord);
  Result.Kind := gdrEnd;
  // a tape that was not closed (the program was stopped) ends with its last whole record
  if FPosition >= Length(FBytes) then
    Exit;
  LKind := ReadByte;
  case LKind of
    Ord(gdrEnd):
      // nothing after the end is read
      FPosition := Length(FBytes);
    Ord(gdrReading):
      begin
        Result.Kind := gdrReading;
        for LIndex := Low(LBits) to High(LBits) do
          LBits[LIndex] := ReadByte;
        for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
          if LBits[Ord(LCommand) div 8] and (1 shl (Ord(LCommand) mod 8)) <> 0 then
            Include(Result.Reading.Commands, LCommand);
        LButtons := ReadByte;
        for LButton := Low(TGreedMouseButton) to High(TGreedMouseButton) do
          if LButtons and (1 shl Ord(LButton)) <> 0 then
            Include(Result.Reading.MouseButtons, LButton);
        Result.Reading.MouseDeltaX := ReadInt32;
        Result.Reading.MouseDeltaY := ReadInt32;
        LCount := ReadByte;
        SetLength(Result.Reading.Typed, LCount);
        for LIndex := 1 to LCount do
          Result.Reading.Typed[LIndex] := Char(ReadByte);
      end;
    Ord(gdrFrame):
      begin
        Result.Kind := gdrFrame;
        Result.Tics := ReadByte;
      end;
    Ord(gdrClock):
      begin
        Result.Kind := gdrClock;
        Result.Clock := Cardinal(ReadInt32);
        // the answer is given that many times: the record stays the next one until they are over
        FClockRepeat := Cardinal(ReadInt32);
        if FClockRepeat > 0 then
          Dec(FClockRepeat);
      end;
  else
    raise EGreedDemoException.CreateFmt(SGreedDemoBadRecord, [LKind, FPosition - 1]);
  end;
end;

function TGreedDemoReader.Peek: TGreedDemoRecord;
begin
  if not FPeeked then
  begin
    FNext := ReadRecord;
    FPeeked := True;
  end;
  Result := FNext;
end;

function TGreedDemoReader.PeekKind: TGreedDemoRecordKind;
begin
  Result := Peek.Kind;
end;

function TGreedDemoReader.Next: TGreedDemoRecord;
begin
  Result := Peek;
  if (Result.Kind = gdrClock) and (FClockRepeat > 0) then
  begin
    Dec(FClockRepeat);
    Exit;
  end;
  // the end stays the next record for ever
  if Result.Kind <> gdrEnd then
    FPeeked := False;
end;

end.
