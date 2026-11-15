{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the scenario that gives    }
{  the fingerprint of the MIDI synthesizer (the same one that was run on the    }
{  old TXcomMidiSynth before the move)                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.MidiScenario;

// The generator and the hash wrap around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>Sends a channel message to the synthesizer under test</summary>
  TMidiScenarioSend = reference to procedure(AStatus, AData1, AData2: Byte);
  /// <summary>Adds AFrames stereo frames to the buffer (what Render of the synthesizer does)</summary>
  TMidiScenarioRender = reference to procedure(ABuffer: PSmallInt; AFrames: Integer);

  /// <summary>
  ///   A fixed run of 600 steps (patch changes of every family, notes on and off, drums, controllers, pitch bends,
  ///   more notes than voices) on a buffer that already has samples in it; the result is the FNV-1a 64 bit of every
  ///   buffer that came out, so two synthesizers that sound the same give the same number
  /// </summary>
  TMidiScenario = class sealed
  public
    const
      STEP_COUNT = 600;
      SEED = 20261115;
    class function Fingerprint(const ASend: TMidiScenarioSend; const ARender: TMidiScenarioRender): UInt64; static;
  end;

implementation

type
  TGenerator = record
    State: Cardinal;
    function Next(ALimit: Integer): Integer;
  end;

function TGenerator.Next(ALimit: Integer): Integer;
begin
  State := State * 1664525 + 1013904223;
  Result := Integer((State shr 8) mod Cardinal(ALimit));
end;

class function TMidiScenario.Fingerprint(const ASend: TMidiScenarioSend; const ARender: TMidiScenarioRender): UInt64;
const
  CONTROLLERS: array[0..5] of Byte = (7, 10, 11, 120, 121, 123);
var
  LGenerator: TGenerator;
  LBuffer: array of SmallInt;
  LStep: Integer;
  LKind: Integer;
  LChannel: Integer;
  LFrames: Integer;
  LIndex: Integer;
  LBytes: PByte;
begin
  LGenerator.State := SEED;
  Result := UInt64($CBF29CE484222325);
  SetLength(LBuffer, 2 * 700);
  for LStep := 0 to STEP_COUNT - 1 do
  begin
    LKind := LGenerator.Next(12);
    LChannel := LGenerator.Next(16);
    case LKind of
      0:
        ASend($C0 or LChannel, LGenerator.Next(128), 0);
      1, 2, 3, 4:
        ASend($90 or LChannel, 24 + LGenerator.Next(80), 1 + LGenerator.Next(127));
      5, 6:
        ASend($80 or LChannel, 24 + LGenerator.Next(80), 0);
      7:
        ASend($90 or LChannel, 24 + LGenerator.Next(80), 0);
      8:
        ASend($B0 or LChannel, CONTROLLERS[LGenerator.Next(Length(CONTROLLERS))], LGenerator.Next(128));
      9:
        ASend($E0 or LChannel, LGenerator.Next(128), LGenerator.Next(128));
      10:
        // the drums: kicks, hats and the rest
        ASend($99, 35 + LGenerator.Next(12), 1 + LGenerator.Next(127));
      11:
        // more notes than the 32 voices
        for LIndex := 0 to 39 do
          ASend($90 or LGenerator.Next(16), 36 + LGenerator.Next(48), 64 + LGenerator.Next(60));
    end;
    LFrames := 64 + LGenerator.Next(636);
    for LIndex := 0 to LFrames * 2 - 1 do
      LBuffer[LIndex] := SmallInt(LGenerator.Next(4001) - 2000);
    ARender(@LBuffer[0], LFrames);
    LBytes := PByte(@LBuffer[0]);
    for LIndex := 0 to LFrames * 4 - 1 do
    begin
      Result := (Result xor LBytes^) * UInt64($100000001B3);
      Inc(LBytes);
    end;
  end;
end;

end.
