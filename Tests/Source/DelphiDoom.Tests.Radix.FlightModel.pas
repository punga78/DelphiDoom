{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixFlightModel                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.FlightModel;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Flight.Model;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixFlightModel = class(TObject)
  public
    [Test]
    [TestCase('fermo', '0,False,0')]
    [TestCase('avanti', '1048576,False,983040')]
    [TestCase('indietro', '-1048576,False,-983040')]
    [TestCase('tronca verso zero', '17,False,15')]
    [TestCase('tronca verso zero negativo', '-17,False,-15')]
    [TestCase('getti di manovra', '1048576,True,917504')]
    [TestCase('getti negativo', '-9,True,-7')]
    procedure DovrebbeFrenareIlMomentoAOgniTic(AMomentum: Integer; AJets: Boolean; AExpected: Integer);
    [Test]
    procedure DovrebbeFermarsiSenzaSpinta;
    [Test]
    procedure DovrebbeNonTraboccareAlMomentoMassimo;
    [Test]
    [TestCase('in piano', '1048576,0,0')]
    [TestCase('muso in su', '1048576,160,40960')]
    [TestCase('muso in giu', '1048576,-160,-40960')]
    [TestCase('a marcia indietro col muso in su', '-1048576,160,-40960')]
    [TestCase('fermo col muso in su', '0,1600,0')]
    procedure DovrebbeDareSalitaODiscesaDalBeccheggio(ASpeed, ALookDir16, AExpected: Integer);
    [Test]
    procedure DovrebbeTogliereLaSpintaDelTicPrecedente;
    [Test]
    procedure DovrebbeFarDecadereIlMomentoVerticaleSenzaBeccheggio;
    [Test]
    procedure DovrebbeTenereUnaSalitaCostanteASpintaCostante;
    [Test]
    procedure DovrebbeAumentareIlFattoreDiMovimentoConIGetti;
    [Test]
    [TestCase('in volo libero', '655360,0,614400,0,False')]
    [TestCase('ferma contro un muro', '655360,0,0,0,True')]
    [TestCase('meno di meta strada', '655360,0,300000,0,True')]
    [TestCase('meta strada giusta', '655360,0,327680,0,False')]
    [TestCase('in diagonale fermata', '393216,-393216,65536,-65536,True')]
    [TestCase('troppo lenta per contare', '196608,0,0,0,False')]
    [TestCase('ferma e basta', '0,0,0,0,False')]
    [TestCase('un salto piu lungo della velocita', '655360,0,9000000,0,False')]
    procedure UnaNavettaFermataDaUnMuroDovrebbeEssereContata(AMomentumX, AMomentumY, ADeltaX, ADeltaY: Integer;
      AExpected: Boolean);
  end;

implementation

const
  FRACUNIT = 65536;

{ TTestRadixFlightModel }

procedure TTestRadixFlightModel.DovrebbeFrenareIlMomentoAOgniTic(AMomentum: Integer; AJets: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixFlightModel.Drag(AMomentum, AJets));
end;

procedure TTestRadixFlightModel.UnaNavettaFermataDaUnMuroDovrebbeEssereContata(AMomentumX, AMomentumY, ADeltaX,
  ADeltaY: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixFlightModel.IsStopped(AMomentumX, AMomentumY, ADeltaX, ADeltaY));
end;

procedure TTestRadixFlightModel.DovrebbeFermarsiSenzaSpinta;
var
  LMomentum: Integer;
  LTics: Integer;
begin
  LMomentum := 18 * FRACUNIT;
  LTics := 0;
  while (LMomentum <> 0) and (LTics < 1000) do
  begin
    LMomentum := TRadixFlightModel.Drag(LMomentum, False);
    Inc(LTics);
  end;
  Assert.AreEqual(0, LMomentum);
  Assert.IsTrue(LTics < 300, 'la navetta si ferma in meno di nove secondi');
end;

procedure TTestRadixFlightModel.DovrebbeNonTraboccareAlMomentoMassimo;
begin
  Assert.AreEqual(2013265919, TRadixFlightModel.Drag(MaxInt, False));
  Assert.AreEqual(-2013265920, TRadixFlightModel.VerticalDrag(Low(Integer)));
end;

procedure TTestRadixFlightModel.DovrebbeDareSalitaODiscesaDalBeccheggio(ASpeed, ALookDir16, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixFlightModel.PitchThrust(ASpeed, ALookDir16));
end;

procedure TTestRadixFlightModel.DovrebbeTogliereLaSpintaDelTicPrecedente;
begin
  // the momentum was only the thrust of the tic before: nothing is left of it
  Assert.AreEqual(0, TRadixFlightModel.VerticalMomentum(40960, 40960, 0));
  // 16 units of other momentum (a lift, a key) are dragged, the old thrust is not
  Assert.AreEqual(15 * FRACUNIT + 1000, TRadixFlightModel.VerticalMomentum(16 * FRACUNIT + 40960, 40960, 1000));
end;

procedure TTestRadixFlightModel.DovrebbeFarDecadereIlMomentoVerticaleSenzaBeccheggio;
begin
  Assert.AreEqual(8 * FRACUNIT * 15 div 16, TRadixFlightModel.VerticalMomentum(8 * FRACUNIT, 0, 0));
  Assert.AreEqual(-(8 * FRACUNIT * 15 div 16), TRadixFlightModel.VerticalMomentum(-8 * FRACUNIT, 0, 0));
end;

procedure TTestRadixFlightModel.DovrebbeTenereUnaSalitaCostanteASpintaCostante;
var
  LMomentum: Integer;
  LThrust: Integer;
  LTic: Integer;
begin
  LThrust := TRadixFlightModel.PitchThrust(16 * FRACUNIT, 320);
  LMomentum := 0;
  for LTic := 1 to 400 do
    LMomentum := TRadixFlightModel.VerticalMomentum(LMomentum, LThrust, LThrust);
  // at the first tic the old thrust that is taken away was never added: its trace decays
  Assert.IsTrue(Abs(LThrust - LMomentum) <= 16, Format('%d contro %d', [LThrust, LMomentum]));
end;

procedure TTestRadixFlightModel.DovrebbeAumentareIlFattoreDiMovimentoConIGetti;
begin
  Assert.AreEqual(2048, TRadixFlightModel.MoveFactor(2048, False));
  Assert.AreEqual(5000, TRadixFlightModel.MoveFactor(2048, True));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixFlightModel);

end.
