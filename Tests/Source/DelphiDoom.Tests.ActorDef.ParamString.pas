{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the text of a parameter with RANDOMPICK and RANDOM     }
{  (DUnitX)                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ActorDef.ParamString;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('actordef')]
  TTestActorDefParamString = class
  public
    [Test]
    procedure DovrebbeTogliereLeVirgoletteDiUnTestoSemplice;
    [Test]
    procedure DovrebbeDareVuotoPerUnTestoVuoto;
    [Test]
    procedure DovrebbeScegliereUnaParolaConRandomPick;
    [Test]
    procedure DovrebbeCalcolareRandomConUnoODueLimiti;
    [Test]
    procedure DovrebbeNonPescareNullaPerUnTestoCheNonERandom;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVecchioSEvalString;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Tests.InfoTables.Fakes,
  DelphiDoom.Tests.InfoTables.LegacyParams,
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.ActorDef.ParamString;

const
  Texts: array[0..21] of string = (
    '', '"abc"', 'abc', 'RANDOMPICK(a, b, c)', 'randompick("x", "y")', 'RANDOMPICK(a)', 'RANDOMPICK',
    'RANDOM(1, 6)', 'random 5', 'RANDOM(2)', 'RANDOM', 'RANDOM(3, 3, 9)', 'Rx', 'r', 'RANDOM(a, b)',
    'RANDOM(10, 20)', '"RANDOM(1, 2)"', 'RANDOMPICK[a, b]', 'RANDOMPICK a b c d', 'random(-5, 5)',
    'RANDOM(0x10)', '"quoted"');

procedure TTestActorDefParamString.DovrebbeTogliereLeVirgoletteDiUnTestoSemplice;
begin
  Assert.AreEqual('abc', TActorDefParamString.Evaluate('"abc"', TFakeParamRandom.Create(1)));
end;

procedure TTestActorDefParamString.DovrebbeDareVuotoPerUnTestoVuoto;
begin
  Assert.AreEqual('', TActorDefParamString.Evaluate('', TFakeParamRandom.Create(1)));
end;

procedure TTestActorDefParamString.DovrebbeScegliereUnaParolaConRandomPick;
var
  LRandom: TFakeParamRandom;
  LRef: IActorDefParamRandom;
  LText: string;
begin
  LRandom := TFakeParamRandom.Create(3);
  LRef := LRandom;
  LText := TActorDefParamString.Evaluate('RANDOMPICK(a, b, c)', LRef);
  Assert.IsTrue((LText = 'a') or (LText = 'b') or (LText = 'c'));
  Assert.AreEqual(1, LRandom.Draws);
end;

procedure TTestActorDefParamString.DovrebbeCalcolareRandomConUnoODueLimiti;
var
  LValue: Integer;
begin
  LValue := StrToInt(TActorDefParamString.Evaluate('RANDOM(5, 8)', TFakeParamRandom.Create(2)));
  Assert.IsTrue((LValue >= 5) and (LValue <= 8));
  LValue := StrToInt(TActorDefParamString.Evaluate('RANDOM(4)', TFakeParamRandom.Create(2)));
  Assert.IsTrue((LValue >= 0) and (LValue <= 4));
end;

procedure TTestActorDefParamString.DovrebbeNonPescareNullaPerUnTestoCheNonERandom;
var
  LRandom: TFakeParamRandom;
  LRef: IActorDefParamRandom;
begin
  LRandom := TFakeParamRandom.Create(3);
  LRef := LRandom;
  TActorDefParamString.Evaluate('Rx', LRef);
  TActorDefParamString.Evaluate('RANDOM', LRef);
  Assert.AreEqual(0, LRandom.Draws);
end;

procedure TTestActorDefParamString.DovrebbeDareLeStesseRisposteDelVecchioSEvalString;
var
  LIndex: Integer;
  LOldRandom: TFakeParamRandom;
  LOldRef: IActorDefParamRandom;
  LNewRandom: TFakeParamRandom;
  LNewRef: IActorDefParamRandom;
begin
  for LIndex := 0 to High(Texts) do
  begin
    LOldRandom := TFakeParamRandom.Create(40 + LIndex);
    LOldRef := LOldRandom;
    LNewRandom := TFakeParamRandom.Create(40 + LIndex);
    LNewRef := LNewRandom;
    Legacy_NRandomSource := function: Integer begin Result := LOldRandom.Next; end;
    Assert.AreEqual(Legacy_EvalString(Texts[LIndex]), TActorDefParamString.Evaluate(Texts[LIndex], LNewRef),
      Texts[LIndex]);
    Assert.AreEqual(LOldRandom.Draws, LNewRandom.Draws, 'draws ' + Texts[LIndex]);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActorDefParamString);

end.
