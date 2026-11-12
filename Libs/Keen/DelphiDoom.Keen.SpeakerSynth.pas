{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the PC speaker as samples                         }
{  The timer 2 of the PC and the speaker that id_sd.c programs (ports 42h and   }
{  61h) as a square wave                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SpeakerSynth;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

const
  /// <summary>How loud the square wave of the speaker is (a 16 bit sample goes to 32767)</summary>
  KEEN_SPEAKER_AMPLITUDE = 6000;

type
  /// <summary>
  ///   The speaker of the PC: a tone is a square wave whose period is the divisor of the timer (the clock of the
  ///   timer is 1193181 Hz). Only integers: the samples are the same on every machine
  /// </summary>
  TKeenSpeakerSynth = class(TInterfacedObject, IKeenSpeaker, IKeenSampleSource)
  strict private
    FRate: Integer;
    FDivisor: Integer;
    FOn: Boolean;
    FPhase: Int64;
  public
    /// <param name="ARate">Samples per second</param>
    constructor Create(ARate: Integer);
    procedure Tone(ADivisor: Word);
    procedure Silence;
    procedure Stop;
    procedure AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.PcSpeaker;

{ TKeenSpeakerSynth }

constructor TKeenSpeakerSynth.Create(ARate: Integer);
begin
  inherited Create;
  if ARate <= 0 then
    raise EArgumentOutOfRangeException.Create('ARate');
  FRate := ARate;
end;

procedure TKeenSpeakerSynth.Tone(ADivisor: Word);
begin
  // a divisor of 0 is 65536 for the timer
  if ADivisor = 0 then
    FDivisor := 65536
  else
    FDivisor := ADivisor;
  FOn := True;
end;

procedure TKeenSpeakerSynth.Silence;
begin
  FOn := False;
end;

procedure TKeenSpeakerSynth.Stop;
begin
  FOn := False;
end;

procedure TKeenSpeakerSynth.AddSamples(const ABuffer: TArray<Integer>; ACount: Integer);
var
  LIndex: Integer;
  LPeriod: Int64;
begin
  if not FOn then
    Exit;
  // the phase counts ticks of the timer times the rate: a sample is KEEN_PC_TIMER_CLOCK of them, a period of the
  // wave the divisor times the rate
  LPeriod := Int64(FDivisor) * FRate;
  for LIndex := 0 to ACount - 1 do
  begin
    if FPhase * 2 < LPeriod then
      Inc(ABuffer[LIndex], KEEN_SPEAKER_AMPLITUDE)
    else
      Dec(ABuffer[LIndex], KEEN_SPEAKER_AMPLITUDE);
    Inc(FPhase, KEEN_PC_TIMER_CLOCK);
    if FPhase >= LPeriod then
      FPhase := FPhase mod LPeriod;
  end;
end;

end.
