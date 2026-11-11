{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - the audio output of Windows (WAV files from memory)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.AudioDevice;

interface

uses
  Winapi.Windows, Winapi.MMSystem, System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomAudioDevice on PlaySound: one WAV file at a time, played from memory without waiting (a new sound
  ///   replaces the one that plays). The files stay alive in a ring until they are surely over, because an
  ///   asynchronous PlaySound reads the memory it is given. Only the effects are played: the music is not connected
  /// </summary>
  TXcomWinAudioDevice = class(TInterfacedObject, IXcomAudioDevice)
  strict private
    const
      RING_SIZE = 4;
    var
      FRing: array[0..RING_SIZE - 1] of TBytes;
      FNext: Integer;
  public
    function IsAvailable: Boolean;
    procedure SetVolume(ASound, AMusic, AUi: Integer);
    procedure PlayWave(const AWave: TBytes);
  end;

implementation

function TXcomWinAudioDevice.IsAvailable: Boolean;
begin
  Result := waveOutGetNumDevs > 0;
end;

procedure TXcomWinAudioDevice.SetVolume(ASound, AMusic, AUi: Integer);
begin
  // the volumes are applied to the samples of each sound (TXcomGame.PlaySound)
end;

procedure TXcomWinAudioDevice.PlayWave(const AWave: TBytes);
begin
  if Length(AWave) = 0 then
    Exit;
  FRing[FNext] := Copy(AWave);
  Winapi.MMSystem.PlaySound(PChar(@FRing[FNext][0]), 0, SND_MEMORY or SND_ASYNC or SND_NODEFAULT);
  FNext := (FNext + 1) mod RING_SIZE;
end;

end.