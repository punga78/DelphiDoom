{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a music made of a WAV file of the mod       }
{  (Music::load of a file of the SOUND folder)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.WavTrack;

interface

uses
  System.SysUtils, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   A digital music: the samples of a PCM WAV file at the rate of the mixer. Mix_PlayMusic(loop): -1 plays
  ///   forever, 0 or 1 once, more that many times
  /// </summary>
  TXcomWavTrack = class(TInterfacedObject, IXcomMusicTrack)
  strict private
    FSamples: TArray<SmallInt>;
    FPosition: Integer;
    FRemaining: Integer;
    FActive: Boolean;
  public
    /// <param name="AWave">The file; EXcomAudioException when it is not a PCM WAV file</param>
    constructor Create(const AWave: TBytes; ARate: Integer);
    function Format: string;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types, DelphiDoom.XcomAudio.WaveDecoder;

constructor TXcomWavTrack.Create(const AWave: TBytes; ARate: Integer);
begin
  inherited Create;
  FSamples := TXcomWaveDecoder.ToStereo16(AWave, ARate);
end;

function TXcomWavTrack.Format: string;
begin
  Result := 'Wav';
end;

procedure TXcomWavTrack.Start(ALoop: Integer);
begin
  FPosition := 0;
  if ALoop < 0 then
    FRemaining := -1
  else if ALoop <= 1 then
    FRemaining := 1
  else
    FRemaining := ALoop;
  FActive := Length(FSamples) > 0;
end;

procedure TXcomWavTrack.Stop;
begin
  FActive := False;
end;

function TXcomWavTrack.IsPlaying: Boolean;
begin
  Result := FActive;
end;

procedure TXcomWavTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LCount: Integer;
  LSum: Integer;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  LCount := ABytes div 2;
  while FActive and (LCount > 0) do
  begin
    if FPosition >= Length(FSamples) then
    begin
      if FRemaining > 0 then
        Dec(FRemaining);
      if FRemaining = 0 then
      begin
        FActive := False;
        Break;
      end;
      FPosition := 0;
    end;
    LSum := Integer(ABuffer^) + Trunc(FSamples[FPosition] * AVolume);
    if LSum > 32767 then
      LSum := 32767
    else if LSum < -32768 then
      LSum := -32768;
    ABuffer^ := SmallInt(LSum);
    Inc(ABuffer);
    Inc(FPosition);
    Dec(LCount);
  end;
end;

end.
