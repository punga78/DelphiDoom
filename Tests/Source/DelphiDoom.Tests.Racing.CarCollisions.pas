{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingCarCollisions                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.CarCollisions;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Racing.CarCollisions;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingCarCollisions = class(TObject)
  strict private
    FA, FB: TRacingCarState;
    function Run(var ABumps: TArray<TRacingBump>; const ABefore: TArray<Boolean>;
      var AAfter: TArray<Boolean>): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure NonDovrebbeToccareDueAutoLontane;
    [Test]
    procedure DovrebbeSpingereDueAutoCheSiToccanoLontanoUnaDallAltra;
    [Test]
    procedure DovrebbeSpingerePiuForteQuantoPiuSiSovrappongono;
    [Test]
    procedure DovrebbeFrenareELanciareUnUrtoSeSiAvvicinanoInFretta;
    [Test]
    procedure NonDovrebbeUrtareSeSiAvvicinanoPianoPianoMaSpingerle;
    [Test]
    procedure NonDovrebbeUrtareDiNuovoFinoAChePassanoDallaStessaCoppiaInContatto;
    [Test]
    procedure DovrebbeSpingereAlungoLAsseXDueAutoNelloStessoPunto;
    [Test]
    procedure NonDovrebbeFareNienteConUnaSolaAuto;
  end;

implementation

{ TTestRacingCarCollisions }

procedure TTestRacingCarCollisions.Setup;
begin
  FA := Default(TRacingCarState);
  FB := Default(TRacingCarState);
  FA.Key := 11;
  FB.Key := 22;
  FA.EngineSpeed := 8000;
  FB.EngineSpeed := 8000;
end;

function TTestRacingCarCollisions.Run(var ABumps: TArray<TRacingBump>; const ABefore: TArray<Boolean>;
  var AAfter: TArray<Boolean>): Integer;
begin
  ABumps := TRacingCarCollisions.Resolve([@FA, @FB], ABefore, AAfter);
  Result := Length(ABumps);
end;

procedure TTestRacingCarCollisions.NonDovrebbeToccareDueAutoLontane;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
begin
  FA.X := 0;
  FB.X := RACING_CAR_CONTACT_DISTANCE + 1;
  Assert.AreEqual(0, Run(LBumps, nil, LAfter));
  Assert.AreEqual<Integer>(0, FA.MomentumX);
  Assert.AreEqual<Integer>(0, FB.MomentumX);
  Assert.AreEqual<Integer>(8000, FA.EngineSpeed);
end;

procedure TTestRacingCarCollisions.DovrebbeSpingereDueAutoCheSiToccanoLontanoUnaDallAltra;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
begin
  FA.X := 20 * 65536;
  FB.X := 0;
  Run(LBumps, nil, LAfter);
  Assert.IsTrue(FA.MomentumX > 0, 'A va a destra');
  Assert.IsTrue(FB.MomentumX < 0, 'B va a sinistra');
  Assert.AreEqual<Integer>(0, FA.MomentumY);
  Assert.AreEqual(FA.MomentumX, -FB.MomentumX);
end;

procedure TTestRacingCarCollisions.DovrebbeSpingerePiuForteQuantoPiuSiSovrappongono;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
  LLight: Integer;
begin
  FA.X := 30 * 65536;
  Run(LBumps, nil, LAfter);
  LLight := FA.MomentumX;
  Setup;
  FA.X := 10 * 65536;
  Run(LBumps, nil, LAfter);
  Assert.IsTrue(FA.MomentumX > LLight);
end;

procedure TTestRacingCarCollisions.DovrebbeFrenareELanciareUnUrtoSeSiAvvicinanoInFretta;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
begin
  FA.X := 20 * 65536;
  FA.MomentumX := -5 * 65536;
  FB.X := 0;
  FB.MomentumX := 5 * 65536;
  Assert.AreEqual(1, Run(LBumps, nil, LAfter));
  Assert.AreEqual<Cardinal>(11, LBumps[0].KeyA);
  Assert.AreEqual<Cardinal>(22, LBumps[0].KeyB);
  Assert.AreEqual<Integer>(7000, FA.EngineSpeed);
  Assert.AreEqual<Integer>(7000, FB.EngineSpeed);
end;

procedure TTestRacingCarCollisions.NonDovrebbeUrtareSeSiAvvicinanoPianoPianoMaSpingerle;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
begin
  FA.X := 20 * 65536;
  FA.MomentumX := 5 * 65536;
  FB.X := 0;
  FB.MomentumX := 5 * 65536;
  Assert.AreEqual(0, Run(LBumps, nil, LAfter));
  Assert.AreEqual<Integer>(8000, FA.EngineSpeed);
  Assert.IsTrue(FA.MomentumX > 5 * 65536);
end;

procedure TTestRacingCarCollisions.NonDovrebbeUrtareDiNuovoFinoAChePassanoDallaStessaCoppiaInContatto;
var
  LBumps: TArray<TRacingBump>;
  LFirst, LSecond: TArray<Boolean>;
begin
  FA.X := 20 * 65536;
  FA.MomentumX := -5 * 65536;
  FB.X := 0;
  FB.MomentumX := 5 * 65536;
  Assert.AreEqual(1, Run(LBumps, nil, LFirst));
  FA.MomentumX := -5 * 65536;
  FB.MomentumX := 5 * 65536;
  Assert.AreEqual(0, Run(LBumps, LFirst, LSecond), 'ancora in contatto');
  FA.X := 100 * 65536;
  Run(LBumps, LSecond, LFirst);
  FA.X := 20 * 65536;
  FA.MomentumX := -5 * 65536;
  FB.MomentumX := 5 * 65536;
  Assert.AreEqual(1, Run(LBumps, LFirst, LSecond), 'si e staccata e urta di nuovo');
end;

procedure TTestRacingCarCollisions.DovrebbeSpingereAlungoLAsseXDueAutoNelloStessoPunto;
var
  LBumps: TArray<TRacingBump>;
  LAfter: TArray<Boolean>;
begin
  Run(LBumps, nil, LAfter);
  Assert.IsTrue(FA.MomentumX > 0);
  Assert.IsTrue(FB.MomentumX < 0);
end;

procedure TTestRacingCarCollisions.NonDovrebbeFareNienteConUnaSolaAuto;
var
  LAfter: TArray<Boolean>;
  LBumps: TArray<TRacingBump>;
begin
  LBumps := TRacingCarCollisions.Resolve([@FA], nil, LAfter);
  Assert.AreEqual<Integer>(0, Length(LBumps));
  Assert.AreEqual<Integer>(0, FA.MomentumX);
end;

end.
