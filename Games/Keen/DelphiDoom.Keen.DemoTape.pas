{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the demo buffer of the input manager              }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  the demo part of IN_ReadControl of id_in.c                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.DemoTape;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>
  ///   A demo is a list of pairs of bytes: a count and a byte that packs one reading of the control (the
  ///   buttons in the bits 4 and 5, the x motion plus 1 in the bits 2 and 3, the y motion plus 1 in the bits
  ///   0 and 1). One reading for each tic of the game. The recording repeats the pair while the readings are
  ///   the same (the count goes up to 254); the playback gives the byte count + 1 times, like the C
  /// </summary>
  TKeenDemoTape = class
  strict private
    FBuffer: TBytes;
    FSize: Integer;
    FOffset: Integer;
    FRecorded: Boolean;
    FFinished: Boolean;
  public
    /// <summary>An empty tape for a recording; ASize is made even (the pairs)</summary>
    constructor CreateForRecording(ASize: Integer);
    /// <summary>A tape to play, a copy of the bytes (the C counts the pairs down in the buffer of the caller)</summary>
    constructor CreateForPlayback(const ABytes: TBytes; ASize: Integer);
    /// <summary>Adds a reading: one more for the pair at the end if it is the same byte (EKeenException when the buffer is full)</summary>
    procedure RecordReading(AValue: Byte);
    /// <summary>The next reading; EKeenException if the demo was already played to its end (the C quits)</summary>
    function PlayReading: Byte;
    /// <summary>The bytes that the recording has made: the pairs up to the last one</summary>
    function RecordedBytes: TBytes;
    /// <summary>True when the pair that was the last one has been played</summary>
    property Finished: Boolean read FFinished;
    property Size: Integer read FSize;
    property Offset: Integer read FOffset;
  end;

implementation

{ TKeenDemoTape }

constructor TKeenDemoTape.CreateForRecording(ASize: Integer);
begin
  inherited Create;
  if ASize <= 0 then
    raise EKeenException.CreateFmt(SKeenDemoTruncated, [ASize, 2]);
  FSize := ASize and not 1;
  SetLength(FBuffer, ASize);
end;

constructor TKeenDemoTape.CreateForPlayback(const ABytes: TBytes; ASize: Integer);
begin
  inherited Create;
  if (ASize < 2) or (ASize > Length(ABytes)) then
    raise EKeenException.CreateFmt(SKeenDemoTruncated, [Length(ABytes), 2]);
  FSize := ASize and not 1;
  FBuffer := Copy(ABytes, 0, ASize);
end;

procedure TKeenDemoTape.RecordReading(AValue: Byte);
begin
  // a count of 254 is the most that a pair can say. The C tests the offset for 0 to know that nothing is
  // recorded yet, so at the offset 0 it overwrote the first pair forever and never went on: here a flag
  if FRecorded and (FBuffer[FOffset + 1] = AValue) and (FBuffer[FOffset] < 254) then
    Inc(FBuffer[FOffset])
  else
  begin
    if FRecorded then
      Inc(FOffset, 2);
    if FOffset >= FSize then
      raise EKeenException.CreateFmt(SKeenDemoOverflow, [FOffset, FSize]);
    FBuffer[FOffset] := 1;
    FBuffer[FOffset + 1] := AValue;
    FRecorded := True;
  end;
end;

function TKeenDemoTape.PlayReading: Byte;
begin
  if FFinished then
    raise EKeenException.Create(SKeenDemoExceeded);
  Result := FBuffer[FOffset + 1];
  // the count is taken down: when it was 0, this is the last time of the pair
  if FBuffer[FOffset] = 0 then
  begin
    Inc(FOffset, 2);
    if FOffset >= FSize then
      FFinished := True;
  end
  else
    Dec(FBuffer[FOffset]);
end;

function TKeenDemoTape.RecordedBytes: TBytes;
begin
  if not FRecorded then
    Exit(nil);
  Result := Copy(FBuffer, 0, FOffset + 2);
end;

end.
