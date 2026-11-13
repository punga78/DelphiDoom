{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the fade of the music                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Fade;

interface

type
  /// <summary>
  ///   A linear ramp of the volume of the music, in whole samples and 16.16 numbers so that it is the same on
  ///   every machine. The original has no fade (it silences the music while the scene changes): this is the
  ///   fade that the issue asks for. The ramp starts from the gain that the music has when it is asked
  /// </summary>
  TWarMusicFade = class
  strict private
    FSampleRate: Integer;
    FGain: Integer;
    FFrom: Integer;
    FTo: Integer;
    FTotal: Integer;
    FPosition: Integer;
    procedure RampTo(ATarget, ADurationMs: Integer);
    function GainAt(APosition: Integer): Integer;
  public
    constructor Create(ASampleRate: Integer);
    /// <summary>Full volume, no ramp</summary>
    procedure Reset;
    /// <summary>Silence, no ramp</summary>
    procedure Mute;
    /// <summary>From silence to full volume; a duration of 0 or less is full volume at once</summary>
    procedure FadeIn(ADurationMs: Integer);
    /// <summary>From the gain it has to silence; a duration of 0 or less is silence at once</summary>
    procedure FadeOut(ADurationMs: Integer);
    /// <summary>Multiplies ACount samples by the gain, one gain for each sample, and advances the ramp</summary>
    procedure Apply(ABuffer: PSmallInt; ACount: Integer);
    /// <summary>The gain now, from 0 to WAR_MUSIC_GAIN_FULL</summary>
    property Gain: Integer read FGain;
    function IsRamping: Boolean;
    /// <summary>The ramp is over and the gain is 0, or it is 0 and nothing rises</summary>
    function IsSilent: Boolean;
  end;

implementation

uses
  DelphiDoom.War.Music.Types;

{ TWarMusicFade }

constructor TWarMusicFade.Create(ASampleRate: Integer);
begin
  inherited Create;
  FSampleRate := ASampleRate;
  Reset;
end;

procedure TWarMusicFade.Reset;
begin
  FGain := WAR_MUSIC_GAIN_FULL;
  FFrom := FGain;
  FTo := FGain;
  FTotal := 0;
  FPosition := 0;
end;

procedure TWarMusicFade.Mute;
begin
  FGain := 0;
  FFrom := 0;
  FTo := 0;
  FTotal := 0;
  FPosition := 0;
end;

procedure TWarMusicFade.RampTo(ATarget, ADurationMs: Integer);
var
  LTotal: Int64;
begin
  LTotal := Int64(ADurationMs) * FSampleRate div 1000;
  if (ADurationMs <= 0) or (LTotal <= 0) or (FGain = ATarget) then
  begin
    FGain := ATarget;
    FFrom := ATarget;
    FTo := ATarget;
    FTotal := 0;
    FPosition := 0;
    Exit;
  end;
  if LTotal > High(Integer) div 2 then
    LTotal := High(Integer) div 2;
  FFrom := FGain;
  FTo := ATarget;
  FTotal := Integer(LTotal);
  FPosition := 0;
end;

procedure TWarMusicFade.FadeIn(ADurationMs: Integer);
begin
  FGain := 0;
  RampTo(WAR_MUSIC_GAIN_FULL, ADurationMs);
end;

procedure TWarMusicFade.FadeOut(ADurationMs: Integer);
begin
  RampTo(0, ADurationMs);
end;

function TWarMusicFade.GainAt(APosition: Integer): Integer;
begin
  if FTotal = 0 then
    Exit(FTo);
  if APosition >= FTotal then
    Exit(FTo);
  Result := FFrom + Integer((Int64(FTo - FFrom) * APosition) div FTotal);
end;

procedure TWarMusicFade.Apply(ABuffer: PSmallInt; ACount: Integer);
var
  LIndex: Integer;
  LSample: PSmallInt;
begin
  LSample := ABuffer;
  for LIndex := 0 to ACount - 1 do
  begin
    FGain := GainAt(FPosition);
    if FGain <> WAR_MUSIC_GAIN_FULL then
      LSample^ := SmallInt((Int64(LSample^) * FGain) div WAR_MUSIC_GAIN_FULL);
    if (FTotal > 0) and (FPosition < FTotal) then
      Inc(FPosition);
    Inc(LSample);
  end;
  // the gain that the next sample will get, so that IsRamping and IsSilent are true as soon as the ramp is over
  FGain := GainAt(FPosition);
  if (FTotal > 0) and (FPosition >= FTotal) then
  begin
    FFrom := FTo;
    FTotal := 0;
    FPosition := 0;
  end;
end;

function TWarMusicFade.IsRamping: Boolean;
begin
  Result := FTotal > 0;
end;

function TWarMusicFade.IsSilent: Boolean;
begin
  Result := (FTotal = 0) and (FTo = 0);
end;

end.
