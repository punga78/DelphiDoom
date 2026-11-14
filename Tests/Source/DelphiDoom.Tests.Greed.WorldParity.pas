{******************************************************************************}
{                                                                              }
{  DelphiDoom: the whole world of a game of Greed, TGreedGame against the       }
{  original                                                                    }
{                                                                              }
{  The golden files have the fingerprints of games played by the ORIGINAL       }
{  xGreed (Tools\Verifica\175-world\Compila.ps1): the player, every sprite,     }
{  the elevators, the doors, the spawn areas, the planes of the map, the        }
{  script, the globals and the sounds, turn after turn. The test plays the      }
{  same games with TGreedGame on the real data and compares the lines. The      }
{  data of the game are not in the repository: without them the test is         }
{  ignored                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WorldParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedWorldParity = class(TObject)
  strict private
    procedure CheckGolden(const AFolder, AGoldenName: string; ARearView: Boolean; const ASaveTurns: string);
  public
    [Test]
    procedure DovrebbeDareLoStessoMondoDelloOriginaleNelGiocoCompleto;
    [Test]
    procedure DovrebbeDareLoStessoSpecchiettoDelloOriginale;
    [Test]
    procedure DovrebbeSalvareECaricareComeLOriginale;
    [Test]
    procedure DovrebbeDareLeStesseRigheDueVolte;
    [Test]
    procedure UnaPartitaRegistrataDovrebbeRidareIlMondoDelloOriginale;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Greed.RealData,
  DelphiDoom.Tests.Greed.WorldPrint, DelphiDoom.Tests.Greed.WorldRunner;

const
  GOLDEN_FULL = 'world.full.golden.txt';
  GOLDEN_REAR = 'world.rear.golden.txt';
  GOLDEN_SAVE = 'world.save.golden.txt';
  /// the turns of -Salva with which world.save.golden.txt was made
  GOLDEN_SAVE_TURNS = '300,700,1100';
  // the columns of a line: W map seed turn timecount history total and a fingerprint for each section
  COLUMN_MAP = 1;
  COLUMN_SEED = 2;
  COLUMN_FRAME = 3;
  COLUMN_HISTORY = 5;
  COLUMN_FIRST_SECTION = 7;
  /// <map>;<seed>;<turn>;<file>: the values of the world of that game after that turn go to the file (the harness
  /// writes the same file with -Valori), to find the field that differs
  TRACE_VARIABLE = 'DELPHIDOOM_GREED_WORLD_TRACE';

{ TTestGreedWorldParity }

procedure TTestGreedWorldParity.CheckGolden(const AFolder, AGoldenName: string; ARearView: Boolean;
  const ASaveTurns: string);
var
  LGolden, LGame, LMine: TStringList;
  LRunner: TLibraryWorldRunner;
  LIndex, LMap, LSeed, LFrames, LEvery, LGames, LTotalFrames: Integer;
  LParts, LTrace: TArray<string>;
  LKey: string;

  procedure PlayGame;
  var
    LLine, LColumn: Integer;
    LParts, LMineParts: TArray<string>;
    LDifferent: string;
    LSection: TWorldSection;
  begin
    if LGame.Count = 0 then
      Exit;
    // the turns of the game are the ones of its last line; the lines are a turn every so many (the second line)
    LFrames := StrToInt(LGame[LGame.Count - 1].Split([' '])[COLUMN_FRAME]);
    LEvery := LFrames;
    if LGame.Count > 1 then
      LEvery := StrToInt(LGame[1].Split([' '])[COLUMN_FRAME]);
    if LEvery < 1 then
      LEvery := 1;
    LMine.Clear;
    LRunner.DumpFrame := -1;
    if (Length(LTrace) = 4) and (StrToIntDef(LTrace[0], -1) = LMap) and (StrToIntDef(LTrace[1], -1) = LSeed) then
    begin
      LRunner.DumpFrame := StrToIntDef(LTrace[2], -1);
      LRunner.DumpFile := LTrace[3];
    end;
    LRunner.Play(LMap, LSeed, LFrames, LEvery, LMine);
    Inc(LGames);
    Inc(LTotalFrames, LFrames);
    for LLine := 0 to LGame.Count - 1 do
    begin
      if (LLine < LMine.Count) and (LMine[LLine] = LGame[LLine]) then
        Continue;
      // the first line that differs says the turn and the parts of the world
      LParts := LGame[LLine].Split([' ']);
      LDifferent := '';
      if LLine < LMine.Count then
      begin
        LMineParts := LMine[LLine].Split([' ']);
        for LSection := Low(TWorldSection) to High(TWorldSection) do
        begin
          LColumn := COLUMN_FIRST_SECTION + Ord(LSection);
          if (LColumn < Length(LParts)) and (LColumn < Length(LMineParts)) and
            (LParts[LColumn] <> LMineParts[LColumn]) then
            LDifferent := LDifferent + ' ' + WORLD_SECTION_NAMES[LSection];
        end;
        // the column after the sections is the picture of the rear view camera
        LColumn := COLUMN_FIRST_SECTION + Ord(High(TWorldSection)) + 1;
        if (LColumn < Length(LParts)) and (LColumn < Length(LMineParts)) and (LParts[LColumn] <> LMineParts[LColumn]) then
          LDifferent := LDifferent + ' rearview';
      end
      else
        LDifferent := ' (the game of the library ended before)';
      Assert.Fail(Format('map %d seed %d: the world differs from the original at the turn %s (line %d of %d):%s',
        [LMap, LSeed, LParts[COLUMN_FRAME], LLine + 1, LGame.Count, LDifferent]));
    end;
    Assert.AreEqual(LGame.Count, LMine.Count, Format('map %d seed %d: the lines of the game', [LMap, LSeed]));
  end;

begin
  LTrace := GetEnvironmentVariable(TRACE_VARIABLE).Split([';']);
  LGames := 0;
  LTotalFrames := 0;
  LMap := -1;
  LSeed := -1;
  LGolden := TStringList.Create;
  LGame := TStringList.Create;
  LMine := TStringList.Create;
  LRunner := TLibraryWorldRunner.Create(AFolder);
  try
    LRunner.RearView := ARearView;
    LRunner.SaveTurns := ASaveTurns;
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    LKey := '';
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if (LGolden[LIndex] = '') or (LGolden[LIndex][1] <> 'W') then
        Continue;
      LParts := LGolden[LIndex].Split([' ']);
      // a new map or a new seed: the game that was being read is played
      if LParts[COLUMN_MAP] + ' ' + LParts[COLUMN_SEED] <> LKey then
      begin
        PlayGame;
        LGame.Clear;
        LKey := LParts[COLUMN_MAP] + ' ' + LParts[COLUMN_SEED];
        LMap := StrToInt(LParts[COLUMN_MAP]);
        LSeed := StrToInt(LParts[COLUMN_SEED]);
      end;
      LGame.Add(LGolden[LIndex]);
    end;
    PlayGame;
    Assert.IsTrue(LGames > 0, 'the golden file has no games');
    TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('%s: %d games, %d turns (%d tics) equal to the original',
      [AGoldenName, LGames, LTotalFrames, LTotalFrames * WORLD_TICS_PER_FRAME]));
  finally
    LRunner.Free;
    LMine.Free;
    LGame.Free;
    LGolden.Free;
  end;
end;

procedure TTestGreedWorldParity.DovrebbeDareLoStessoMondoDelloOriginaleNelGiocoCompleto;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('the data of the full game are not on this machine (Reference\_dati\greed\full)');
  CheckGolden(TGreedRealData.FullFolder, GOLDEN_FULL, False, '');
end;

procedure TTestGreedWorldParity.DovrebbeDareLoStessoSpecchiettoDelloOriginale;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('the data of the full game are not on this machine (Reference\_dati\greed\full)');
  // the player uses the rear view camera: each line has also the fingerprint of the picture of the camera
  CheckGolden(TGreedRealData.FullFolder, GOLDEN_REAR, True, '');
end;

procedure TTestGreedWorldParity.DovrebbeSalvareECaricareComeLOriginale;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('the data of the full game are not on this machine (Reference\_dati\greed\full)');
  // the game is saved and loaded again three times: the bytes of each saved game are in the history of the lines,
  // and what the game is after each load is in the lines that follow
  CheckGolden(TGreedRealData.FullFolder, GOLDEN_SAVE, False, GOLDEN_SAVE_TURNS);
end;

procedure TTestGreedWorldParity.DovrebbeDareLeStesseRigheDueVolte;
var
  LRunner: TLibraryWorldRunner;
  LFirst, LSecond, LOther: TStringList;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('the data of the full game are not on this machine (Reference\_dati\greed\full)');
  LFirst := TStringList.Create;
  LSecond := TStringList.Create;
  LOther := TStringList.Create;
  LRunner := TLibraryWorldRunner.Create(TGreedRealData.FullFolder);
  try
    // the same seed gives the same game, another seed another game
    LRunner.Play(0, 5, 120, 20, LFirst);
    LRunner.Play(0, 5, 120, 20, LSecond);
    LRunner.Play(0, 6, 120, 20, LOther);
    Assert.AreEqual(7, LFirst.Count);
    Assert.AreEqual(LFirst.Text, LSecond.Text);
    Assert.AreNotEqual(LFirst[LFirst.Count - 1].Split([' '])[COLUMN_HISTORY],
      LOther[LOther.Count - 1].Split([' '])[COLUMN_HISTORY]);
  finally
    LRunner.Free;
    LOther.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGreedWorldParity.UnaPartitaRegistrataDovrebbeRidareIlMondoDelloOriginale;
const
  TAPE_MAPS: array[0..3] of Integer = (0, 9, 17, 29);
  TAPE_SEED = 2;
var
  LGolden, LExpected, LRecorded, LPlayed: TStringList;
  LRunner: TLibraryWorldRunner;
  LTape: TMemoryStream;
  LBytes: TBytes;
  LMap, LIndex, LFrames, LEvery: Integer;
  LParts: TArray<string>;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('the data of the full game are not on this machine (Reference\_dati\greed\full)');
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  LRecorded := TStringList.Create;
  LPlayed := TStringList.Create;
  LTape := TMemoryStream.Create;
  LRunner := TLibraryWorldRunner.Create(TGreedRealData.FullFolder);
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(GOLDEN_FULL));
    for LMap in TAPE_MAPS do
    begin
      // the lines of the ORIGINAL for this game
      LExpected.Clear;
      for LIndex := 0 to LGolden.Count - 1 do
      begin
        LParts := LGolden[LIndex].Split([' ']);
        if (Length(LParts) > COLUMN_FRAME) and (LParts[0] = 'W') and (LParts[COLUMN_MAP] = IntToStr(LMap)) and
          (LParts[COLUMN_SEED] = IntToStr(TAPE_SEED)) then
          LExpected.Add(LGolden[LIndex]);
      end;
      Assert.IsTrue(LExpected.Count > 1, Format('the golden file has no game of the map %d with the seed %d',
        [LMap, TAPE_SEED]));
      LFrames := StrToInt(LExpected[LExpected.Count - 1].Split([' '])[COLUMN_FRAME]);
      LEvery := StrToInt(LExpected[1].Split([' '])[COLUMN_FRAME]);
      // the game is played with the commands of the seed and recorded ...
      LTape.Clear;
      LRecorded.Clear;
      LRunner.PlayFrom := nil;
      LRunner.RecordTo := LTape;
      LRunner.Play(LMap, TAPE_SEED, LFrames, LEvery, LRecorded);
      Assert.AreEqual(LExpected.Text, LRecorded.Text, Format('map %d: recording must not change the game', [LMap]));
      // ... and then played from the tape alone: no seed of the commands, no clock
      SetLength(LBytes, LTape.Size);
      Move(LTape.Memory^, LBytes[0], LTape.Size);
      LPlayed.Clear;
      LRunner.RecordTo := nil;
      LRunner.PlayFrom := LBytes;
      LRunner.Play(LMap, TAPE_SEED, LFrames, LEvery, LPlayed);
      Assert.IsFalse(LRunner.TapeOutOfStep, Format('map %d: the tape went out of step', [LMap]));
      Assert.AreEqual(LExpected.Text, LPlayed.Text, Format('map %d: the tape must give the game of the original',
        [LMap]));
    end;
  finally
    LRunner.Free;
    LTape.Free;
    LPlayed.Free;
    LRecorded.Free;
    LExpected.Free;
    LGolden.Free;
  end;
end;

end.