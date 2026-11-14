{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the reader of a script            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.ScriptParser;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.ScriptParser,
  DelphiDoom.Parity.Types;

type
  [TestFixture]
  [Category('parity')]
  TTestParityScriptParser = class(TObject)
  strict private
    procedure AssertRaises(const AText: string; const AExpectedPart: string);
  public
    [Test]
    procedure UnTestoVuotoNonDovrebbeAverePassi;
    [Test]
    procedure DovrebbeSaltareCommentiERigheVuote;
    [Test]
    procedure DovrebbeLeggereUnaTenutaConTuttiITasti;
    [Test]
    procedure IndietroDovrebbeEssereUnAvantiNegativo;
    [Test]
    procedure LaSterzataDovrebbeEssereInPassiDa256;
    [Test]
    procedure DovrebbeLeggereUnVaiConIValoriPredefiniti;
    [Test]
    procedure DovrebbeLeggereUnVaiConLeSueOpzioni;
    [Test]
    procedure DovrebbeLeggereUnGuarda;
    [Test]
    procedure DovrebbeLeggereUnSali;
    [Test]
    procedure DovrebbeLeggereUnaCaccia;
    [Test]
    procedure DovrebbeLeggereUnaSosta;
    [Test]
    procedure UnVaiDovrebbePoterCombattereLungoLaStrada;
    [Test]
    procedure LeParoleNonDovrebberoDipendereDalleMaiuscole;
    [Test]
    procedure DovrebbeAccettareFineRigaDiWindowsETabulazioni;
    [Test]
    procedure IlNumeroDiRigaDovrebbeContareAncheLeRigheSaltate;
    [Test]
    procedure UnPassoSconosciutoDovrebbeDareEccezioneConLaRiga;
    [Test]
    procedure DovrebbeLeggereITastiDiUnGiocoSoloSeNominati;
    [Test]
    procedure DovrebbeLeggereSalvaECaricaConLoSlot;
    [Test]
    procedure DovrebbeLeggereUnTastoEUnaFotoComeTenuteDiUnTic;
    [Test]
    procedure UnaParolaSconosciutaDovrebbeDareEccezione;
    [Test]
    procedure UnaParolaDiUnAltroPassoDovrebbeDareEccezione;
    [Test]
    procedure UnNumeroMancanteDovrebbeDareEccezione;
    [Test]
    procedure UnNumeroSbagliatoDovrebbeDareEccezione;
    [Test]
    [TestCase('avanti oltre 50', 'hold 5 forward 51')]
    [TestCase('lato oltre 40', 'hold 5 side -41')]
    [TestCase('sterzata oltre 5', 'hold 5 turn 6')]
    [TestCase('sguardo oltre 7', 'hold 5 look 8')]
    [TestCase('arma zero', 'hold 5 weapon 0')]
    [TestCase('zero tic', 'hold 0')]
    [TestCase('raggio zero', 'goto 1 2 radius 0')]
    [TestCase('tempo zero', 'goto 1 2 timeout 0')]
    [TestCase('velocita zero', 'goto 1 2 speed 0')]
    procedure UnNumeroFuoriDaiLimitiDovrebbeDareEccezione(const ALine: string);
  end;

implementation

procedure TTestParityScriptParser.AssertRaises(const AText: string; const AExpectedPart: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    TParityScriptParser.Parse(AText);
  except
    on E: EParityException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(LMessage <> '', 'no exception for: ' + AText);
  Assert.Contains(LMessage, AExpectedPart);
end;

procedure TTestParityScriptParser.UnTestoVuotoNonDovrebbeAverePassi;
begin
  Assert.AreEqual<Integer>(0, Length(TParityScriptParser.Parse('')));
end;

procedure TTestParityScriptParser.DovrebbeSaltareCommentiERigheVuote;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('# the way to the exit'#10#10'   '#10'hold 3 fire # shoot'#10'#hold 9');
  Assert.AreEqual<Integer>(1, Length(LSteps));
  Assert.AreEqual(3, LSteps[0].Tics);
  Assert.IsTrue(LSteps[0].Command.Fire);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnaTenutaConTuttiITasti;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse(
    'hold 35 forward 50 side -20 turn 2 look -3 center fire use jump crouch weapon 4')[0];
  Assert.AreEqual(Ord(skHold), Ord(LStep.Kind));
  Assert.AreEqual(35, LStep.Tics);
  Assert.AreEqual(50, LStep.Command.Forward);
  Assert.AreEqual(-20, LStep.Command.Side);
  Assert.AreEqual(512, LStep.Command.Turn);
  Assert.AreEqual(-3, LStep.Command.Look);
  Assert.IsTrue(LStep.Command.LookCenter);
  Assert.IsTrue(LStep.Command.Fire);
  Assert.IsTrue(LStep.Command.Use);
  Assert.IsTrue(LStep.Command.Jump);
  Assert.IsTrue(LStep.Command.Crouch);
  Assert.AreEqual(4, LStep.Command.Weapon);
end;

procedure TTestParityScriptParser.IndietroDovrebbeEssereUnAvantiNegativo;
begin
  Assert.AreEqual(-25, TParityScriptParser.Parse('hold 4 back 25')[0].Command.Forward);
end;

procedure TTestParityScriptParser.LaSterzataDovrebbeEssereInPassiDa256;
begin
  Assert.AreEqual(-1280, TParityScriptParser.Parse('hold 4 turn -5')[0].Command.Turn);
  Assert.AreEqual(256, TParityScriptParser.Parse('hold 4 turn 1')[0].Command.Turn);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnVaiConIValoriPredefiniti;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('goto 1200 -340')[0];
  Assert.AreEqual(Ord(skGoto), Ord(LStep.Kind));
  Assert.AreEqual(1200, LStep.X);
  Assert.AreEqual(-340, LStep.Y);
  Assert.IsFalse(LStep.HasZ);
  Assert.AreEqual(TParityScriptParser.DEFAULT_RADIUS, LStep.Radius);
  Assert.AreEqual(TParityScriptParser.DEFAULT_SPEED, LStep.Command.Forward);
  Assert.AreEqual(TParityScriptParser.DEFAULT_TIMEOUT, LStep.Tics);
  Assert.IsFalse(LStep.Command.Fire);
  Assert.IsFalse(LStep.Command.Use);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnVaiConLeSueOpzioni;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('goto 10 20 z -64 radius 16 speed 25 timeout 90 fire use')[0];
  Assert.IsTrue(LStep.HasZ);
  Assert.AreEqual(-64, LStep.Z);
  Assert.AreEqual(16, LStep.Radius);
  Assert.AreEqual(25, LStep.Command.Forward);
  Assert.AreEqual(90, LStep.Tics);
  Assert.IsTrue(LStep.Command.Fire);
  Assert.IsTrue(LStep.Command.Use);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnGuarda;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('face 7 -9 timeout 40 fire')[0];
  Assert.AreEqual(Ord(skFace), Ord(LStep.Kind));
  Assert.AreEqual(7, LStep.X);
  Assert.AreEqual(-9, LStep.Y);
  Assert.AreEqual(40, LStep.Tics);
  Assert.IsTrue(LStep.Command.Fire);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnSali;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('climb 128')[0];
  Assert.AreEqual(Ord(skClimb), Ord(LStep.Kind));
  Assert.IsTrue(LStep.HasZ);
  Assert.AreEqual(128, LStep.Z);
  Assert.AreEqual(TParityScriptParser.DEFAULT_TIMEOUT, LStep.Tics);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnaCaccia;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('hunt 300')[0];
  Assert.AreEqual(Ord(skHunt), Ord(LStep.Kind));
  Assert.AreEqual(300, LStep.Tics);
  Assert.IsTrue(LStep.Fight);
  Assert.AreEqual(TParityScriptParser.DEFAULT_ENEMY_RANGE, LStep.EnemyRange);
  Assert.AreEqual(640, TParityScriptParser.Parse('hunt 300 range 640')[0].EnemyRange);
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnaSosta;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('heal 90 1500 range 700')[0];
  Assert.AreEqual(Ord(skHeal), Ord(LStep.Kind));
  Assert.AreEqual(90, LStep.Health);
  Assert.AreEqual(1500, LStep.Tics);
  Assert.IsTrue(LStep.Fight);
  Assert.AreEqual(700, LStep.EnemyRange);
  AssertRaises('heal 90', 'missing');
end;

procedure TTestParityScriptParser.UnVaiDovrebbePoterCombattereLungoLaStrada;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('goto 1 2')[0];
  Assert.IsFalse(LStep.Fight);
  Assert.AreEqual(0, LStep.EnemyRange);
  LStep := TParityScriptParser.Parse('goto 1 2 fight')[0];
  Assert.IsTrue(LStep.Fight);
  Assert.AreEqual(TParityScriptParser.DEFAULT_ENEMY_RANGE, LStep.EnemyRange);
  LStep := TParityScriptParser.Parse('goto 1 2 range 500 fight')[0];
  Assert.IsTrue(LStep.Fight);
  Assert.AreEqual(500, LStep.EnemyRange);
end;

procedure TTestParityScriptParser.LeParoleNonDovrebberoDipendereDalleMaiuscole;
var
  LStep: TParityScriptStep;
begin
  LStep := TParityScriptParser.Parse('HOLD 2 Forward 10 FIRE')[0];
  Assert.AreEqual(10, LStep.Command.Forward);
  Assert.IsTrue(LStep.Command.Fire);
end;

procedure TTestParityScriptParser.DovrebbeAccettareFineRigaDiWindowsETabulazioni;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('hold'#9'2'#9'fire'#13#10'climb 5'#13#10);
  Assert.AreEqual<Integer>(2, Length(LSteps));
  Assert.IsTrue(LSteps[0].Command.Fire);
  Assert.AreEqual(5, LSteps[1].Z);
end;

procedure TTestParityScriptParser.IlNumeroDiRigaDovrebbeContareAncheLeRigheSaltate;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('# one'#10#10'hold 1'#10'# four'#10'hold 2');
  Assert.AreEqual(3, LSteps[0].Line);
  Assert.AreEqual(5, LSteps[1].Line);
end;

procedure TTestParityScriptParser.UnPassoSconosciutoDovrebbeDareEccezioneConLaRiga;
begin
  AssertRaises('hold 1'#10'dance 5', 'line 2');
  AssertRaises('hold 1'#10'dance 5', 'dance');
end;

procedure TTestParityScriptParser.DovrebbeLeggereITastiDiUnGiocoSoloSeNominati;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('hold 5 forward 50'#10'hold 5 forward 50 afterburner'#10'hold 1 bomb'#10 +
    'goto 1 2 afterburner');
  Assert.IsFalse(LSteps[0].Command.Afterburner);
  Assert.IsFalse(LSteps[0].Command.Bomb);
  Assert.IsTrue(LSteps[1].Command.Afterburner);
  Assert.IsFalse(LSteps[1].Command.Bomb);
  Assert.IsTrue(LSteps[2].Command.Bomb);
  Assert.IsTrue(LSteps[3].Command.Afterburner);
  AssertRaises('goto 1 2 bomb', 'bomb');
  AssertRaises('face 1 2 afterburner', 'afterburner');
end;

procedure TTestParityScriptParser.DovrebbeLeggereSalvaECaricaConLoSlot;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('save 3'#10'load 0'#10'hold 1');
  Assert.IsTrue(LSteps[0].Kind = skSave);
  Assert.IsTrue(LSteps[0].Command.Save);
  Assert.IsFalse(LSteps[0].Command.Load);
  Assert.AreEqual(3, LSteps[0].Command.Slot);
  Assert.IsTrue(LSteps[1].Kind = skLoad);
  Assert.IsTrue(LSteps[1].Command.Load);
  Assert.IsFalse(LSteps[1].Command.Save);
  Assert.AreEqual(0, LSteps[1].Command.Slot);
  Assert.IsFalse(LSteps[2].Command.Save or LSteps[2].Command.Load);
  AssertRaises('save', 'number is missing');
  AssertRaises('save 6', 'not between');
  AssertRaises('load -1', 'not between');
  AssertRaises('save 1 fire', 'fire');
  AssertRaises('load 1 timeout 5', 'timeout');
end;

procedure TTestParityScriptParser.DovrebbeLeggereUnTastoEUnaFotoComeTenuteDiUnTic;
var
  LSteps: TArray<TParityScriptStep>;
begin
  LSteps := TParityScriptParser.Parse('key 27'#10'shot 3'#10'hold 2');
  Assert.IsTrue(LSteps[0].Kind = skHold);
  Assert.AreEqual(1, LSteps[0].Tics);
  Assert.AreEqual(27, LSteps[0].Command.Key);
  Assert.AreEqual(0, LSteps[0].Command.Shot);
  Assert.IsTrue(LSteps[1].Kind = skHold);
  Assert.AreEqual(1, LSteps[1].Tics);
  Assert.AreEqual(3, LSteps[1].Command.Shot);
  Assert.AreEqual(0, LSteps[1].Command.Key);
  Assert.AreEqual(0, LSteps[2].Command.Key + LSteps[2].Command.Shot);
  AssertRaises('key', 'number is missing');
  AssertRaises('key 0', 'not between');
  AssertRaises('key 256', 'not between');
  AssertRaises('shot 0', 'not between');
  AssertRaises('key 27 fire', 'fire');
end;

procedure TTestParityScriptParser.UnaParolaSconosciutaDovrebbeDareEccezione;
begin
  AssertRaises('hold 1 sing', 'sing');
end;

procedure TTestParityScriptParser.UnaParolaDiUnAltroPassoDovrebbeDareEccezione;
begin
  AssertRaises('hold 1 radius 5', 'radius');
  AssertRaises('goto 1 2 forward 5', 'forward');
  AssertRaises('climb 5 fire', 'fire');
  AssertRaises('face 1 2 use', 'use');
  AssertRaises('hold 5 timeout 3', 'timeout');
  AssertRaises('hunt 5 timeout 3', 'timeout');
  AssertRaises('hunt 5 fire', 'fire');
  AssertRaises('hold 5 fight', 'fight');
end;

procedure TTestParityScriptParser.UnNumeroMancanteDovrebbeDareEccezione;
begin
  AssertRaises('goto 5', 'missing');
  AssertRaises('hold 5 forward', 'missing');
  AssertRaises('hold', 'missing');
end;

procedure TTestParityScriptParser.UnNumeroSbagliatoDovrebbeDareEccezione;
begin
  AssertRaises('hold many', 'many');
  AssertRaises('goto 1.5 2', '1.5');
end;

procedure TTestParityScriptParser.UnNumeroFuoriDaiLimitiDovrebbeDareEccezione(const ALine: string);
begin
  AssertRaises(ALine, 'between');
end;

end.
