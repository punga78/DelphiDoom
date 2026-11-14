{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: writing a tape               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Writer;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Demo.Types;

type
  /// <summary>
  ///   Writes a tape on a stream, byte by byte in little endian order: the header ("GRDM", the version, the sixteen
  ///   numbers of TGreedDemoHeader as 32 bit integers), then the records, each a byte with its kind and
  ///   - a reading: 6 bytes with a bit for each command (the bit n of the byte n div 8 is the command n), a byte
  ///     with a bit for each button of the mouse, the two movements of the mouse as 32 bit integers, a byte with
  ///     the number of characters typed and a byte for each of them;
  ///   - a frame: a byte with the tics;
  ///   - a clock: the answer as a 32 bit unsigned number and, as another one, how many times in a row the clock
  ///     gave it (the game asks the clock many times in a tic);
  ///   - the end: nothing.
  ///   The stream is not owned
  /// </summary>
  TGreedDemoWriter = class
  strict private
    FStream: TStream;
    FClosed: Boolean;
    FRecords: Integer;
    FClockValue: Cardinal;
    FClockCount: Cardinal;
    procedure WriteByte(AValue: Byte);
    procedure WriteInt32(AValue: Integer);
    procedure FlushClock;
  public
    /// <summary>Writes the header. EArgumentNilException if AStream is nil</summary>
    constructor Create(AStream: TStream; const AHeader: TGreedDemoHeader);
    procedure WriteReading(const AReading: TGreedDemoReading);
    /// <summary>EGreedDemoException if ATics is not 0..255</summary>
    procedure WriteFrame(ATics: Integer);
    procedure WriteClock(AValue: Cardinal);
    /// <summary>Writes the end of the tape; what is written after it is ignored (nothing is written twice)</summary>
    procedure Close;
    /// <summary>The records written, without the end</summary>
    property Records: Integer read FRecords;
    property Closed: Boolean read FClosed;
  end;

implementation

constructor TGreedDemoWriter.Create(AStream: TStream; const AHeader: TGreedDemoHeader);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
  for LIndex := Low(GREED_DEMO_MAGIC) to High(GREED_DEMO_MAGIC) do
    WriteByte(GREED_DEMO_MAGIC[LIndex]);
  WriteInt32(GREED_DEMO_VERSION);
  WriteInt32(AHeader.Map);
  WriteInt32(AHeader.Character);
  WriteInt32(AHeader.Difficulty);
  WriteInt32(AHeader.Episode);
  WriteInt32(Ord(AHeader.DemoEdition));
  WriteInt32(Ord(AHeader.LowResolution));
  WriteInt32(AHeader.RandomOffset);
  WriteInt32(AHeader.CameraDelay);
  WriteInt32(AHeader.ViewSize);
  WriteInt32(Ord(AHeader.Violence));
  WriteInt32(Ord(AHeader.MouseEnabled));
  WriteInt32(AHeader.MouseSensitivity);
  WriteInt32(AHeader.MouseSensitivityX);
  WriteInt32(AHeader.MouseSensitivityY);
  WriteInt32(Ord(AHeader.InvertMouseTurn));
  WriteInt32(Ord(AHeader.InvertMouseLook));
end;

procedure TGreedDemoWriter.WriteByte(AValue: Byte);
begin
  FStream.WriteBuffer(AValue, 1);
end;

procedure TGreedDemoWriter.WriteInt32(AValue: Integer);
var
  LValue: Cardinal;
begin
  LValue := Cardinal(AValue);
  WriteByte(Byte(LValue));
  WriteByte(Byte(LValue shr 8));
  WriteByte(Byte(LValue shr 16));
  WriteByte(Byte(LValue shr 24));
end;

procedure TGreedDemoWriter.WriteReading(const AReading: TGreedDemoReading);
var
  LBits: array[0..5] of Byte;
  LCommand: TGreedCommand;
  LButton: TGreedMouseButton;
  LButtons: Byte;
  LIndex: Integer;
begin
  if FClosed then
    Exit;
  if Length(AReading.Typed) > 255 then
    raise EGreedDemoException.CreateFmt(SGreedDemoTooManyTyped, [Length(AReading.Typed)]);
  FlushClock;
  FillChar(LBits, SizeOf(LBits), 0);
  for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
    if LCommand in AReading.Commands then
      LBits[Ord(LCommand) div 8] := LBits[Ord(LCommand) div 8] or (1 shl (Ord(LCommand) mod 8));
  LButtons := 0;
  for LButton := Low(TGreedMouseButton) to High(TGreedMouseButton) do
    if LButton in AReading.MouseButtons then
      LButtons := LButtons or (1 shl Ord(LButton));
  WriteByte(Ord(gdrReading));
  for LIndex := Low(LBits) to High(LBits) do
    WriteByte(LBits[LIndex]);
  WriteByte(LButtons);
  WriteInt32(AReading.MouseDeltaX);
  WriteInt32(AReading.MouseDeltaY);
  WriteByte(Length(AReading.Typed));
  for LIndex := 1 to Length(AReading.Typed) do
    WriteByte(Byte(Ord(AReading.Typed[LIndex]) and $FF));
  Inc(FRecords);
end;

procedure TGreedDemoWriter.WriteFrame(ATics: Integer);
begin
  if FClosed then
    Exit;
  if (ATics < 0) or (ATics > 255) then
    raise EGreedDemoException.CreateFmt(SGreedDemoTooManyTics, [ATics]);
  FlushClock;
  WriteByte(Ord(gdrFrame));
  WriteByte(ATics);
  Inc(FRecords);
end;

procedure TGreedDemoWriter.FlushClock;
begin
  if FClockCount = 0 then
    Exit;
  WriteByte(Ord(gdrClock));
  WriteInt32(Integer(FClockValue));
  WriteInt32(Integer(FClockCount));
  FClockCount := 0;
  Inc(FRecords);
end;

procedure TGreedDemoWriter.WriteClock(AValue: Cardinal);
begin
  if FClosed then
    Exit;
  // the same answer again is one more of the record that is waiting
  if (FClockCount > 0) and (AValue <> FClockValue) then
    FlushClock;
  FClockValue := AValue;
  Inc(FClockCount);
end;

procedure TGreedDemoWriter.Close;
begin
  if FClosed then
    Exit;
  FlushClock;
  WriteByte(Ord(gdrEnd));
  FClosed := True;
end;

end.
