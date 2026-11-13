{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - spacing of the answers of the units               }
{                                                                              }
{  Port of the test of wa_playAcknowledgementSound (war_audio.c), war1         }
{  (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.AckThrottle;

interface

type
  /// <summary>
  ///   When many units answer an order together only one answer is heard: the next one is allowed after
  ///   WAR_MIN_ACK_SOUND_INTERVAL seconds (lastAcknowledgementRealTime of the map)
  /// </summary>
  TWarAcknowledgementThrottle = class
  strict private
    FLastTime: Single;
  public
    /// <summary>The time starts at 0, like the field of the map in the original</summary>
    constructor Create;
    /// <summary>True, and remembers ANowSeconds, if the answer can be played now</summary>
    function TryAcquire(ANowSeconds: Single): Boolean;
    /// <summary>The map is new: the last answer is forgotten</summary>
    procedure Reset;
  end;

implementation

uses
  DelphiDoom.War.Audio.Types;

{ TWarAcknowledgementThrottle }

constructor TWarAcknowledgementThrottle.Create;
begin
  inherited Create;
  FLastTime := 0;
end;

function TWarAcknowledgementThrottle.TryAcquire(ANowSeconds: Single): Boolean;
var
  LElapsed: Single;
  LInterval: Single;
begin
  LElapsed := ANowSeconds - FLastTime;
  LInterval := WAR_MIN_ACK_SOUND_INTERVAL;
  Result := LElapsed >= LInterval;
  if Result then
    FLastTime := ANowSeconds;
end;

procedure TWarAcknowledgementThrottle.Reset;
begin
  FLastTime := 0;
end;

end.
