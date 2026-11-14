{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - the table of the ten best pilots   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.ScoreTable;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Radix.Debriefing,
  DelphiDoom.Radix.Score.Table;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixScoreTable = class(TObject)
  strict private
    FTable: TRadixScoreTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaRigaDovrebbeEssereDi51Byte;
    [Test]
    procedure LaTabellaNuovaDovrebbeEssereVuota;
    [Test]
    procedure IlPunteggioDiUnLivelloDovrebbeContareDueVolteLObiettivoSecondario;
    [Test]
    procedure IlPunteggioPrevistoDovrebbeEssereQuelloDiNoveLivelli;
    [Test]
    procedure UnPunteggioZeroNonDovrebbeEntrareInUnaTabellaVuota;
    [Test]
    procedure IlPrimoPilotaDovrebbePrendereIlPrimoPosto;
    [Test]
    procedure IPilotiDovrebberoEssereOrdinatiDalMigliore;
    [Test]
    procedure APariPunteggioIlNuovoDovrebbeAndareDopo;
    [Test]
    procedure UnPunteggioPeggioreDelDecimoNonDovrebbeEntrare;
    [Test]
    procedure LUndicesimoMiglioreDovrebbeFarUscireLUltimo;
    [Test]
    procedure IlNomeDovrebbeEssereTagliatoASediciCaratteri;
    [Test]
    procedure IlFileDovrebbeEssereDi510ByteETornareUguale;
    [Test]
    procedure UnFileDiUnAltraLunghezzaDovrebbeDareEccezioneELasciareLaTabellaVuota;
    [Test]
    procedure UnaRigaManomessaDovrebbeEssereSvuotataEContata;
    [Test]
    procedure UnaRigaFuoriDallaTabellaDovrebbeDareEccezione;
  end;

implementation

uses
  DelphiDoom.Radix.Types;

procedure TTestRadixScoreTable.Setup;
begin
  FTable := TRadixScoreTable.Create;
end;

procedure TTestRadixScoreTable.TearDown;
begin
  FTable.Free;
end;

procedure TTestRadixScoreTable.UnaRigaDovrebbeEssereDi51Byte;
begin
  Assert.AreEqual(TRadixScoreTable.ENTRY_SIZE, SizeOf(TRadixScoreEntry));
  Assert.AreEqual(510, TRadixScoreTable.FILE_SIZE);
end;

procedure TTestRadixScoreTable.LaTabellaNuovaDovrebbeEssereVuota;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RADIX_SCORE_COUNT - 1 do
  begin
    Assert.IsFalse(FTable.IsUsed(LIndex));
    Assert.AreEqual(0, FTable[LIndex].Rating);
    Assert.AreEqual(RADIX_SCORE_DIGEST_SIZE, Integer(Length(FTable[LIndex].Digest)));
  end;
end;

procedure TTestRadixScoreTable.IlPunteggioDiUnLivelloDovrebbeContareDueVolteLObiettivoSecondario;
var
  LScore: TRadixDebriefingScore;
begin
  LScore.Secondary := 1000;
  LScore.KillRatio := 200;
  LScore.FlyingTime := 30;
  LScore.Secrets := 4;
  LScore.ProficientFlying := 50000;
  Assert.AreEqual(52234, TRadixScoreTable.LevelScore(LScore));
end;

procedure TTestRadixScoreTable.IlPunteggioPrevistoDovrebbeEssereQuelloDiNoveLivelli;
var
  LScore: TRadixDebriefingScore;
begin
  LScore.Secondary := 65536;
  LScore.KillRatio := 65536;
  LScore.FlyingTime := 65536;
  LScore.Secrets := 65536;
  LScore.ProficientFlying := 65536;
  Assert.AreEqual(6 * 65536 * 9, TRadixScoreTable.ProjectedRating(LScore));
end;

procedure TTestRadixScoreTable.UnPunteggioZeroNonDovrebbeEntrareInUnaTabellaVuota;
begin
  Assert.AreEqual(TRadixScoreTable.NO_POSITION, FTable.PositionOf(0));
  Assert.AreEqual(TRadixScoreTable.NO_POSITION, FTable.Add('NOBODY', 1, 1, 2, 0));
  Assert.IsFalse(FTable.IsUsed(0));
end;

procedure TTestRadixScoreTable.IlPrimoPilotaDovrebbePrendereIlPrimoPosto;
begin
  Assert.AreEqual(1, FTable.PositionOf(10));
  Assert.AreEqual(1, FTable.Add('ACE', 2, 5, 3, 10));
  Assert.IsTrue(FTable.IsUsed(0));
  Assert.AreEqual('ACE', string(FTable[0].Name));
  Assert.AreEqual(2, FTable[0].Episode);
  Assert.AreEqual(5, FTable[0].Map);
  Assert.AreEqual(3, Integer(FTable[0].Skill));
  Assert.AreEqual(10, FTable[0].Rating);
  Assert.IsFalse(FTable.IsUsed(1));
end;

procedure TTestRadixScoreTable.IPilotiDovrebberoEssereOrdinatiDalMigliore;
begin
  FTable.Add('B', 1, 1, 0, 200);
  FTable.Add('C', 1, 1, 0, 100);
  Assert.AreEqual(1, FTable.Add('A', 1, 1, 0, 300));
  Assert.AreEqual(3, FTable.PositionOf(150));
  Assert.AreEqual('A', string(FTable[0].Name));
  Assert.AreEqual('B', string(FTable[1].Name));
  Assert.AreEqual('C', string(FTable[2].Name));
end;

procedure TTestRadixScoreTable.APariPunteggioIlNuovoDovrebbeAndareDopo;
begin
  FTable.Add('FIRST', 1, 1, 0, 100);
  Assert.AreEqual(2, FTable.Add('SECOND', 1, 2, 0, 100));
  Assert.AreEqual('FIRST', string(FTable[0].Name));
  Assert.AreEqual('SECOND', string(FTable[1].Name));
end;

procedure TTestRadixScoreTable.UnPunteggioPeggioreDelDecimoNonDovrebbeEntrare;
var
  LIndex: Integer;
begin
  for LIndex := 1 to RADIX_SCORE_COUNT do
    FTable.Add(AnsiString('P' + IntToStr(LIndex)), 1, 1, 0, 100 * LIndex);
  Assert.AreEqual(TRadixScoreTable.NO_POSITION, FTable.Add('LATE', 1, 1, 0, 100));
  Assert.AreEqual(TRadixScoreTable.NO_POSITION, FTable.PositionOf(50));
  Assert.AreEqual('P1', string(FTable[9].Name));
end;

procedure TTestRadixScoreTable.LUndicesimoMiglioreDovrebbeFarUscireLUltimo;
var
  LIndex: Integer;
begin
  for LIndex := 1 to RADIX_SCORE_COUNT do
    FTable.Add(AnsiString('P' + IntToStr(LIndex)), 1, 1, 0, 100 * LIndex);
  Assert.AreEqual(6, FTable.Add('NEW', 3, 9, 1, 550));
  Assert.AreEqual('NEW', string(FTable[5].Name));
  Assert.AreEqual('P10', string(FTable[0].Name));
  Assert.AreEqual('P2', string(FTable[9].Name));
end;

procedure TTestRadixScoreTable.IlNomeDovrebbeEssereTagliatoASediciCaratteri;
begin
  FTable.Add('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1, 1, 0, 5);
  Assert.AreEqual('ABCDEFGHIJKLMNOP', string(FTable[0].Name));
end;

procedure TTestRadixScoreTable.IlFileDovrebbeEssereDi510ByteETornareUguale;
var
  LBytes: TBytes;
  LOther: TRadixScoreTable;
begin
  FTable.Add('ONE', 1, 3, 2, 700);
  FTable.Add('TWO', 2, 4, 1, 900);
  LBytes := FTable.Encode;
  Assert.AreEqual(510, Integer(Length(LBytes)));
  // the first row: the length of the name, then the name
  Assert.AreEqual(3, Integer(LBytes[0]));
  Assert.AreEqual(Ord('T'), Integer(LBytes[1]));
  // the rating of the first row, after name (17), episode, map (4 + 4) and skill (1)
  Assert.AreEqual(900, PInteger(@LBytes[26])^);
  LOther := TRadixScoreTable.Create;
  try
    Assert.AreEqual(0, LOther.Decode(LBytes));
    Assert.AreEqual('TWO', string(LOther[0].Name));
    Assert.AreEqual(4, LOther[0].Map);
    Assert.AreEqual('ONE', string(LOther[1].Name));
    Assert.AreEqual(700, LOther[1].Rating);
    Assert.IsFalse(LOther.IsUsed(2));
  finally
    LOther.Free;
  end;
end;

procedure TTestRadixScoreTable.UnFileDiUnAltraLunghezzaDovrebbeDareEccezioneELasciareLaTabellaVuota;
var
  LBytes: TBytes;
  LRaised: Boolean;
begin
  FTable.Add('ONE', 1, 3, 2, 700);
  LBytes := FTable.Encode;
  SetLength(LBytes, 509);
  LRaised := False;
  try
    FTable.Decode(LBytes);
  except
    on ERadixException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsFalse(FTable.IsUsed(0));
end;

procedure TTestRadixScoreTable.UnaRigaManomessaDovrebbeEssereSvuotataEContata;
var
  LBytes: TBytes;
begin
  FTable.Add('HONEST', 1, 3, 2, 700);
  FTable.Add('CHEAT', 1, 3, 2, 800);
  LBytes := FTable.Encode;
  // the rating of the first row (CHEAT) is raised by hand
  PInteger(@LBytes[26])^ := 999999;
  Assert.AreEqual(1, FTable.Decode(LBytes));
  Assert.AreEqual('HONEST', string(FTable[0].Name));
  Assert.IsFalse(FTable.IsUsed(1));
end;

procedure TTestRadixScoreTable.UnaRigaFuoriDallaTabellaDovrebbeDareEccezione;
var
  LRaised: Boolean;
  LEntry: TRadixScoreEntry;
begin
  LRaised := False;
  try
    LEntry := FTable[RADIX_SCORE_COUNT];
    Assert.AreEqual(0, LEntry.Rating);
  except
    on ERadixException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

end.
