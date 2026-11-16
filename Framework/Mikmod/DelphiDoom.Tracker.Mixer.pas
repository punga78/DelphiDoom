{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - mixes the voices into 16 bit stereo                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Mixer;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Tracker.Voice;

type
  /// <summary>
  ///   A fixed number of voices that are added and written as 16 bit stereo
  /// </summary>
  TTrackerMixer = class
  private
    FSampleRate: Integer;
    FVoices: TObjectList<TTrackerVoice>;
    FGain: Double;
    FLeft: TArray<Double>;
    FRight: TArray<Double>;
    function GetVoice(const AIndex: Integer): TTrackerVoice;
    function GetVoiceCount: Integer;
  public
    /// <param name="ASampleRate">Frames per second of the output</param>
    /// <param name="AVoiceCount">Number of voices</param>
    constructor Create(const ASampleRate, AVoiceCount: Integer);
    destructor Destroy; override;

    /// <summary>
    ///   Adds the voices for AFrames frames and writes them, interleaved
    ///   (left, right), to AOutput from the frame AOffset. The output is
    ///   clamped, never wrapped
    /// </summary>
    procedure Mix(const AOutput: TArray<SmallInt>; const AOffset, AFrames: Integer);

    property SampleRate: Integer read FSampleRate;
    property VoiceCount: Integer read GetVoiceCount;
    property Voices[const AIndex: Integer]: TTrackerVoice read GetVoice;
    /// <summary>
    ///   Scale of the sum of the voices (1 / the square root of their number
    ///   by default, which leaves room for several loud voices)
    /// </summary>
    property Gain: Double read FGain write FGain;
  end;

implementation

uses
  System.Math;

{ TTrackerMixer }

constructor TTrackerMixer.Create(const ASampleRate, AVoiceCount: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FSampleRate := ASampleRate;
  FVoices := TObjectList<TTrackerVoice>.Create(True);
  for LIndex := 0 to AVoiceCount - 1 do
    FVoices.Add(TTrackerVoice.Create);
  FGain := 1 / Sqrt(Max(1, AVoiceCount));
end;

destructor TTrackerMixer.Destroy;
begin
  FVoices.Free;
  inherited Destroy;
end;

function TTrackerMixer.GetVoice(const AIndex: Integer): TTrackerVoice;
begin
  Result := FVoices[AIndex];
end;

function TTrackerMixer.GetVoiceCount: Integer;
begin
  Result := FVoices.Count;
end;

procedure TTrackerMixer.Mix(const AOutput: TArray<SmallInt>; const AOffset, AFrames: Integer);
var
  LVoice: TTrackerVoice;
  LFrame: Integer;
  LLeft, LRight: Double;
begin
  if Length(FLeft) < AFrames then
  begin
    SetLength(FLeft, AFrames);
    SetLength(FRight, AFrames);
  end;
  FillChar(FLeft[0], AFrames * SizeOf(Double), 0);
  FillChar(FRight[0], AFrames * SizeOf(Double), 0);

  for LVoice in FVoices do
  begin
    if LVoice.Active then
      LVoice.Mix(FLeft, FRight, 0, AFrames);
  end;

  for LFrame := 0 to AFrames - 1 do
  begin
    LLeft := Max(-32768.0, Min(32767.0, FLeft[LFrame] * FGain));
    LRight := Max(-32768.0, Min(32767.0, FRight[LFrame] * FGain));
    AOutput[2 * (AOffset + LFrame)] := SmallInt(Round(LLeft));
    AOutput[2 * (AOffset + LFrame) + 1] := SmallInt(Round(LRight));
  end;
end;

end.
