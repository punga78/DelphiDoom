{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - the score of a MUS file while it is written       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.MusTrack;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The bytes of the score of a MUS file: events, each followed by the delay
  ///   before the next one when there is any
  /// </summary>
  /// <remarks>
  ///   An event that is not written (most meta events, most controllers)
  ///   can leave two delays one after the other: they are joined in one. The
  ///   score cannot be longer than 65535 bytes, the limit of the MUS header
  /// </remarks>
  TMusTrack = class
  private
    FData: TArray<Byte>;
    FPosition: Integer;
    // Where the code of the last event, and the last delay, are in the data; -1 for none
    FLastEvent: Integer;
    FLastDelay: Integer;
    FRunningDelay: Cardinal;
    procedure WriteBytes(const ABytes: array of Byte; const AStart, ACount: Integer);
  public
    constructor Create;

    /// <summary>Appends an event of ALength bytes</summary>
    /// <exception cref="EM2mException">the score would be too long</exception>
    procedure WriteEvent(const AEvent: array of Byte; const ALength: Integer);

    /// <summary>
    ///   Appends the delay, in MUS clocks, that follows the last event; it
    ///   marks that event as the last of its group
    /// </summary>
    /// <exception cref="EM2mException">AClocks is zero, there is no event before the delay, or the score is too long</exception>
    procedure WriteDelay(const AClocks: Cardinal);

    /// <summary>The bytes written so far</summary>
    function ToBytes: TBytes;

    property Position: Integer read FPosition;
  end;

implementation

uses
  DelphiDoom.M2m.Intf;

const
  MAX_SCORE_BYTES = 65536;
  LAST_OF_GROUP = $80;
  DELAY_DIGIT_MASK = $7F;
  DELAY_BUFFER_SIZE = 6;
  FIRST_DELAY_DIGIT = 5;
  LAST_DELAY_DIGIT = 4;
  DELAY_BITS = 7;
  NONE = -1;

{ TMusTrack }

constructor TMusTrack.Create;
begin
  inherited Create;
  SetLength(FData, MAX_SCORE_BYTES);
  FLastEvent := NONE;
  FLastDelay := NONE;
end;

procedure TMusTrack.WriteBytes(const ABytes: array of Byte; const AStart, ACount: Integer);
begin
  if ACount + FPosition >= MAX_SCORE_BYTES then
    raise EM2mException.CreateCode(M2M_ERROR_CONVERT);
  Move(ABytes[AStart], FData[FPosition], ACount);
  Inc(FPosition, ACount);
end;

procedure TMusTrack.WriteEvent(const AEvent: array of Byte; const ALength: Integer);
begin
  FLastEvent := FPosition;
  FRunningDelay := 0;
  FLastDelay := NONE;
  WriteBytes(AEvent, 0, ALength);
end;

procedure TMusTrack.WriteDelay(const AClocks: Cardinal);
var
  LDelay: Cardinal;
  LScratch: array[0..DELAY_BUFFER_SIZE - 1] of Byte;
  LIndex: Integer;
begin
  if AClocks = 0 then
    raise EM2mException.CreateCode(M2M_ERROR_CONVERT);

  LDelay := AClocks;
  if (FLastDelay <> NONE) and (FLastDelay < FPosition) then
  begin
    // The event between the two delays was dropped: the delays are one
    Inc(LDelay, FRunningDelay);
    FRunningDelay := LDelay;
    FPosition := FLastDelay;
  end
  else
  begin
    FLastDelay := FPosition;
    if (FLastEvent <> NONE) and (FLastEvent < FPosition) then
      FData[FLastEvent] := FData[FLastEvent] or LAST_OF_GROUP
    else
      // The score has to begin with an event
      raise EM2mException.CreateCode(M2M_ERROR_CONVERT);
    FLastEvent := NONE;
  end;

  // At most two digits of seven bits: the delay is cut there
  FillChar(LScratch, SizeOf(LScratch), 0);
  LIndex := FIRST_DELAY_DIGIT;
  while LIndex >= LAST_DELAY_DIGIT do
  begin
    if LDelay = 0 then
      Break;
    LScratch[LIndex] := Byte(LDelay and DELAY_DIGIT_MASK) or LAST_OF_GROUP;
    LDelay := LDelay shr DELAY_BITS;
    Dec(LIndex);
  end;
  // The last digit has no continuation bit
  LScratch[FIRST_DELAY_DIGIT] := LScratch[FIRST_DELAY_DIGIT] and DELAY_DIGIT_MASK;

  WriteBytes(LScratch, LIndex + 1, FIRST_DELAY_DIGIT - LIndex);
end;

function TMusTrack.ToBytes: TBytes;
begin
  SetLength(Result, FPosition);
  if FPosition > 0 then
    Move(FData[0], Result[0], FPosition);
end;

end.
