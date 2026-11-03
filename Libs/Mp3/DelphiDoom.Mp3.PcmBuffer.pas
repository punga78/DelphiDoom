{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - collects the PCM of one decoded frame                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.PcmBuffer;

interface

uses
  mp3_OBuffer;

type
  /// <summary>
  ///   Output buffer of the decoder (the role TOBuffer_MCI plays in the
  ///   engine): the synthesis filters append the samples of one frame, one
  ///   channel at a time, and the buffer interleaves them as 16 bit PCM
  /// </summary>
  TMp3PcmBuffer = class(TOBuffer)
  private
    FChannels: Integer;
    FSamples: array[0..OBUFFERSIZE - 1] of SmallInt;
    FNextIndex: array[0..MAX_CHANNELS - 1] of Integer;
    FCount: Integer;
    FComplete: Boolean;
    function GetByteCount: Integer;
  public
    /// <param name="AChannels">1 (mono) or 2 (stereo)</param>
    constructor Create(AChannels: Integer);

    /// <summary>
    ///   Starts a new frame: forgets the samples collected so far
    /// </summary>
    procedure Reset;

    /// <summary>
    ///   First sample of the frame (interleaved when there are two channels)
    /// </summary>
    function Data: PSmallInt;

    procedure Append(Channel: Cardinal; Value: SmallInt); override;

    /// <summary>
    ///   Called by the layer III decoder when the frame is complete
    /// </summary>
    procedure WriteBuffer; override;
    procedure ClearBuffer; override;
    procedure SetStopFlag; override;

    property Channels: Integer read FChannels;

    /// <summary>
    ///   Samples collected, all channels together
    /// </summary>
    property Count: Integer read FCount;
    property ByteCount: Integer read GetByteCount;

    /// <summary>
    ///   True once WriteBuffer has been called for the current frame. A frame
    ///   the decoder skipped (no main data yet) leaves it False
    /// </summary>
    property Complete: Boolean read FComplete;
  end;

implementation

uses
  System.SysUtils;

{ TMp3PcmBuffer }

constructor TMp3PcmBuffer.Create(AChannels: Integer);
begin
  inherited Create;
  if (AChannels < 1) or (AChannels > MAX_CHANNELS) then
    raise EArgumentOutOfRangeException.Create('AChannels');
  FChannels := AChannels;
  Reset;
end;

procedure TMp3PcmBuffer.Reset;
var
  LChannel: Integer;
begin
  FCount := 0;
  FComplete := False;
  for LChannel := 0 to MAX_CHANNELS - 1 do
    FNextIndex[LChannel] := LChannel;
end;

function TMp3PcmBuffer.Data: PSmallInt;
begin
  Result := @FSamples[0];
end;

function TMp3PcmBuffer.GetByteCount: Integer;
begin
  Result := FCount * SizeOf(SmallInt);
end;

procedure TMp3PcmBuffer.Append(Channel: Cardinal; Value: SmallInt);
begin
  if Integer(Channel) >= FChannels then
    raise ERangeError.CreateFmt('Channel %d is not in the output', [Channel]);
  if FNextIndex[Channel] >= Length(FSamples) then
    raise ERangeError.Create('PCM buffer overflow');

  FSamples[FNextIndex[Channel]] := Value;
  Inc(FNextIndex[Channel], FChannels);
  Inc(FCount);
end;

procedure TMp3PcmBuffer.WriteBuffer;
begin
  FComplete := True;
end;

procedure TMp3PcmBuffer.ClearBuffer;
begin
  Reset;
end;

procedure TMp3PcmBuffer.SetStopFlag;
begin
  // Nothing to stop: the buffer is only memory, there is no audio device
end;

end.
