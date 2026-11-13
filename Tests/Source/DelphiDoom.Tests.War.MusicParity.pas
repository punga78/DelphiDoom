{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the music of Libs\War with wa_playMidi of the remake  }
{                                                                              }
{  Tests\Data\War\music.golden.txt is made by Tools\Verifica\198\              }
{  Compila-MusicRef.ps1: the code of wa_playMidi (war_audio.c) and the MIDI    }
{  reader tml.h of TinySoundFont, compiled with gcc, run on 12 files made      }
{  by the harness (fixed seeds, 1 to 3 tracks, random events of every kind,    }
{  tempo changes, loops) and called with the chunks of samples that the file   }
{  lists; each call that the original makes to the synth is a line with the    }
{  sample at which its block of 64 started. The file is in the golden itself   }
{  (hexadecimal), so there is no generator to keep equal: the player of       }
{  Libs\War, with the real sequencer of Libs\Midi, must make the same calls    }
{  at the same samples, velocities included (bits of the float). The notes    }
{  that the player stops at the end (AO) are a choice of the port and are     }
{  not compared.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('war')]
  [Category('parity')]
  TTestWarMusicParity = class
  strict private
    function Run(const ALine: string; out AFinished: Boolean; out APosition: Int64): TStringList;
  public
    [Test]
    procedure DovrebbeFareLeStesseChiamateAlSintetizzatoreDelCSuDodiciCanzoni;
  end;

implementation

uses
  System.IOUtils, System.Math, DelphiDoom.Midi.Intf, DelphiDoom.Midi.Factory, DelphiDoom.War.Music.Intf, DelphiDoom.War.Music.Types,
  DelphiDoom.War.Music.Factory, DelphiDoom.War.Music.Player, DelphiDoom.War.Audio.Types,
  DelphiDoom.Tests.War.MusicFakes, DelphiDoom.Tests.War.RealData;

function HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2));
end;

function BitsToSingle(ABits: Cardinal): Single;
begin
  Move(ABits, Result, SizeOf(Result));
end;

{ TTestWarMusicParity }

function TTestWarMusicParity.Run(const ALine: string; out AFinished: Boolean; out APosition: Int64): TStringList;
var
  LParts: TArray<string>;
  LSynth: TFakeMusicSynth;
  LHold: IWarMusicSynth;
  LPlayer: IWarMusicPlayer;
  LChunks: TArray<Integer>;
  LBuffer: TArray<SmallInt>;
  LLoop: Boolean;
  LTotal, LDone: Int64;
  LChunk, LIndex: Integer;
  LCall: string;
begin
  // S id tracks division loop samples volume-bits hex
  LParts := ALine.Split([' ']);
  LLoop := LParts[4] = '1';
  LTotal := StrToInt64(LParts[5]);
  LSynth := TFakeMusicSynth.Create;
  LHold := LSynth;
  LPlayer := TWarMusicFactory.CreatePlayer(LHold, TWarMusicFactory.CreateTimeline(TMidiFactory.CreateSequencer(nil)));
  LPlayer.SetVolume(BitsToSingle(Cardinal(StrToInt64('$' + LParts[6]))), True);
  Assert.IsTrue(LPlayer.Play(HexToBytes(LParts[7]), LLoop, 0), 'The song was not read: ' + LParts[1]);
  LChunks := [441, 1000, 64, 8192, 37, 4410];
  SetLength(LBuffer, 8192);
  LDone := 0;
  LIndex := 0;
  while LDone < LTotal do
  begin
    LChunk := LChunks[LIndex mod Length(LChunks)];
    Inc(LIndex);
    if LChunk > LTotal - LDone then
      LChunk := LTotal - LDone;
    LPlayer.Mix(@LBuffer[0], LChunk);
    Inc(LDone, LChunk);
    if LPlayer.State = wmsEnded then
      Break;
  end;
  AFinished := LPlayer.State = wmsEnded;
  APosition := LSynth.Rendered;
  Result := TStringList.Create;
  for LCall in LSynth.Calls do
    // the stop of the notes at the end is not a call of the original
    if LCall.Split([' '])[1] <> 'AO' then
      Result.Add(LCall);
end;

procedure TTestWarMusicParity.DovrebbeFareLeStesseChiamateAlSintetizzatoreDelCSuDodiciCanzoni;
var
  LLines: TArray<string>;
  LLine: string;
  LParts: TArray<string>;
  LExpected, LActual: TStringList;
  LFinished: Boolean;
  LPosition: Int64;
  LScenarios, LIndex, LCalls: Integer;
  LStart: string;
  LStartIndex: Integer;
begin
  LLines := TFile.ReadAllLines(TWarRealData.GoldenPath('music.golden.txt'));
  LScenarios := 0;
  LCalls := 0;
  LExpected := TStringList.Create;
  try
    LStart := '';
    for LStartIndex := 0 to High(LLines) do
    begin
      LLine := LLines[LStartIndex];
      if LLine = '' then
        Continue;
      if LLine[1] = 'S' then
      begin
        LStart := LLine;
        LExpected.Clear;
        Continue;
      end;
      if LLine[1] = 'E' then
      begin
        // "E pos TYPE ..." is what the fake synth writes: "pos TYPE ..."
        LExpected.Add(Copy(LLine, 3, MaxInt));
        Continue;
      end;
      if LLine[1] <> 'X' then
        Continue;
      LParts := LLine.Split([' ']);
      LActual := Run(LStart, LFinished, LPosition);
      try
        // the first call that differs is more useful than the number of calls
        for LIndex := 0 to Min(LExpected.Count, LActual.Count) - 1 do
          Assert.AreEqual(LExpected[LIndex], LActual[LIndex], 'Song ' + LParts[1] + ', call ' + IntToStr(LIndex));
        Assert.AreEqual<Integer>(LExpected.Count, LActual.Count, 'Number of calls of the song ' + LParts[1]);
        Assert.AreEqual<Boolean>(LParts[2] = '1', LFinished, 'Finished: song ' + LParts[1]);
        Assert.AreEqual<Int64>(StrToInt64(LParts[3]), LPosition, 'Samples: song ' + LParts[1]);
        Inc(LScenarios);
        Inc(LCalls, LExpected.Count);
      finally
        LActual.Free;
      end;
    end;
  finally
    LExpected.Free;
  end;
  Assert.AreEqual<Integer>(12, LScenarios);
  Assert.IsTrue(LCalls > 500, 'The songs have calls to compare');
end;

end.
