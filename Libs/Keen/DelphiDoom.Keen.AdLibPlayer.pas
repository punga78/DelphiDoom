{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the sound effects on the AdLib card               }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SDL_ALPlaySound, SDL_ALStopSound, SDL_ALSoundService, SDL_StartAL and        }
{  SDL_ShutAL of id_sd.c                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.AdLibPlayer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.AdLibSound;

const
  // the registers of the AdLib card (id_sd.h)
  KEEN_AL_CHAR = $20;
  KEEN_AL_SCALE = $40;
  KEEN_AL_ATTACK = $60;
  KEEN_AL_SUSTAIN = $80;
  KEEN_AL_WAVE = $E0;
  KEEN_AL_FREQ_LOW = $A0;
  KEEN_AL_FREQ_HIGH = $B0;
  KEEN_AL_EFFECTS = $BD;
  /// <summary>modifiers[0] and carriers[0]: the operator cells of the channel 0, the one of the sound effects</summary>
  KEEN_AL_MODULATOR_0 = 0;
  KEEN_AL_CARRIER_0 = 3;

type
  /// <summary>
  ///   Plays an AdLib sound on the channel 0, one byte at each service (140 times a second): the instrument is
  ///   programmed when the sound starts, then each byte is the low part of the frequency (with the octave of the
  ///   sound and the key on) or, if 0, the note off
  /// </summary>
  TKeenAdLibPlayer = class
  strict private
    FPort: IKeenAdLibPort;
    FSound: TKeenAdLibSound;
    FPlaying: Boolean;
    FPosition: Integer;
    FLengthLeft: Cardinal;
    FBlock: Byte;
    FOnFinished: TProc;
    procedure Finish;
  public
    constructor Create(const APort: IKeenAdLibPort);
    /// <summary>SDL_StartAL: the rhythm register is cleared</summary>
    procedure Start;
    /// <summary>SDL_ShutAL: the rhythm register is cleared and the note of the channel 0 is turned off</summary>
    procedure Shut;
    /// <summary>SDL_ALPlaySound; an instrument with both sustain registers 0 is an EKeenException (Quit in the C)</summary>
    procedure Play(const ASound: TKeenAdLibSound);
    /// <summary>SDL_ALStopSound</summary>
    procedure Stop;
    /// <summary>SDL_ALSoundService: what the timer interrupt does</summary>
    procedure Service;
    property Playing: Boolean read FPlaying;
    /// <summary>SDL_SoundFinished: called when a sound ends by itself (not with Stop)</summary>
    property OnFinished: TProc read FOnFinished write FOnFinished;
  end;

implementation

{ TKeenAdLibPlayer }

constructor TKeenAdLibPlayer.Create(const APort: IKeenAdLibPort);
begin
  inherited Create;
  if not Assigned(APort) then
    raise EArgumentNilException.Create('APort');
  FPort := APort;
end;

procedure TKeenAdLibPlayer.Start;
begin
  FPort.Write(KEEN_AL_EFFECTS, 0);
end;

procedure TKeenAdLibPlayer.Shut;
begin
  FPort.Write(KEEN_AL_EFFECTS, 0);
  FPort.Write(KEEN_AL_FREQ_HIGH, 0);
end;

procedure TKeenAdLibPlayer.Stop;
begin
  FPlaying := False;
  FPort.Write(KEEN_AL_FREQ_HIGH, 0);
end;

procedure TKeenAdLibPlayer.Finish;
begin
  FPlaying := False;
  FPort.Write(KEEN_AL_FREQ_HIGH, 0);
  if Assigned(FOnFinished) then
    FOnFinished();
end;

procedure TKeenAdLibPlayer.Play(const ASound: TKeenAdLibSound);
begin
  Stop;
  // the C sets the sound before it looks at the instrument, and Quit never comes back: here nothing plays
  if (ASound.Instrument.ModulatorSustain or ASound.Instrument.CarrierSustain) = 0 then
    raise EKeenException.Create(SKeenAdLibSuspicious);
  FLengthLeft := ASound.Length;
  FSound := ASound;
  FPosition := 0;
  FBlock := ((ASound.Block and 7) shl 2) or $20;
  FPlaying := True;
  FPort.Write(KEEN_AL_MODULATOR_0 + KEEN_AL_CHAR, ASound.Instrument.ModulatorChar);
  FPort.Write(KEEN_AL_MODULATOR_0 + KEEN_AL_SCALE, ASound.Instrument.ModulatorScale);
  FPort.Write(KEEN_AL_MODULATOR_0 + KEEN_AL_ATTACK, ASound.Instrument.ModulatorAttack);
  FPort.Write(KEEN_AL_MODULATOR_0 + KEEN_AL_SUSTAIN, ASound.Instrument.ModulatorSustain);
  FPort.Write(KEEN_AL_MODULATOR_0 + KEEN_AL_WAVE, ASound.Instrument.ModulatorWave);
  FPort.Write(KEEN_AL_CARRIER_0 + KEEN_AL_CHAR, ASound.Instrument.CarrierChar);
  FPort.Write(KEEN_AL_CARRIER_0 + KEEN_AL_SCALE, ASound.Instrument.CarrierScale);
  FPort.Write(KEEN_AL_CARRIER_0 + KEEN_AL_ATTACK, ASound.Instrument.CarrierAttack);
  FPort.Write(KEEN_AL_CARRIER_0 + KEEN_AL_SUSTAIN, ASound.Instrument.CarrierSustain);
  FPort.Write(KEEN_AL_CARRIER_0 + KEEN_AL_WAVE, ASound.Instrument.CarrierWave);
end;

procedure TKeenAdLibPlayer.Service;
var
  LSample: Byte;
begin
  if not FPlaying then
    Exit;
  if FLengthLeft = 0 then
  begin
    // a length of 0: the C counts down from 4 billion and plays what is after the data; here the sound ends
    Finish;
    Exit;
  end;
  // the bytes that the chunk does not have are silence (the C reads what is after the chunk)
  if FPosition < System.Length(FSound.Data) then
    LSample := FSound.Data[FPosition]
  else
    LSample := 0;
  Inc(FPosition);
  if LSample = 0 then
    FPort.Write(KEEN_AL_FREQ_HIGH, 0)
  else
  begin
    FPort.Write(KEEN_AL_FREQ_LOW, LSample);
    FPort.Write(KEEN_AL_FREQ_HIGH, FBlock);
  end;
  Dec(FLengthLeft);
  if FLengthLeft = 0 then
    Finish;
end;

end.
