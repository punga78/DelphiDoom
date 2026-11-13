{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the score of a MUS file while it is written            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.M2m.MusTrack;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.M2m.MusTrack;

type
  [TestFixture]
  [Category('m2m')]
  TTestMusTrack = class(TObject)
  private
    FTrack: TMusTrack;
    procedure AssertScore(const AExpected: array of Byte);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestScriveGliEventi;
    [Test]
    procedure TestUnRitardoSegnaLUltimoEventoDelGruppo;
    [Test]
    procedure TestUnRitardoDiUnaCifra;
    [Test]
    procedure TestUnRitardoDiDueCifre;
    [Test]
    procedure TestUnRitardoNonPuoEssereZero;
    [Test]
    procedure TestUnRitardoVuoleUnEventoPrima;
    [Test]
    procedure TestDueRitardiConUnEventoScartatoInMezzoSiUniscono;
    [Test]
    procedure TestUnEventoDopoUnRitardoNonLoCambia;
    [Test]
    procedure TestLaPartituraNonSuperaIlLimiteDellIntestazione;
  end;

implementation

uses
  DelphiDoom.M2m.Intf;

{ TTestMusTrack }

procedure TTestMusTrack.Setup;
begin
  FTrack := TMusTrack.Create;
end;

procedure TTestMusTrack.TearDown;
begin
  FTrack.Free;
end;

procedure TTestMusTrack.AssertScore(const AExpected: array of Byte);
var
  LActual: TBytes;
  LIndex: Integer;
begin
  LActual := FTrack.ToBytes;
  Assert.AreEqual<Integer>(Length(AExpected), Length(LActual), 'length');
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual(Integer(AExpected[LIndex]), Integer(LActual[LIndex]), Format('byte %d', [LIndex]));
end;

procedure TTestMusTrack.TestScriveGliEventi;
begin
  FTrack.WriteEvent([$10, $BC, $64], 3);
  FTrack.WriteEvent([$00, $3C], 2);

  AssertScore([$10, $BC, $64, $00, $3C]);
  Assert.AreEqual(5, FTrack.Position);
end;

procedure TTestMusTrack.TestUnRitardoSegnaLUltimoEventoDelGruppo;
begin
  FTrack.WriteEvent([$10, $3C], 2);
  FTrack.WriteDelay(5);

  AssertScore([$90, $3C, $05]);
end;

procedure TTestMusTrack.TestUnRitardoDiUnaCifra;
begin
  FTrack.WriteEvent([$10, $3C], 2);
  FTrack.WriteDelay(127);

  AssertScore([$90, $3C, $7F]);
end;

procedure TTestMusTrack.TestUnRitardoDiDueCifre;
begin
  FTrack.WriteEvent([$10, $3C], 2);
  // 200 is 1 * 128 + 72: the first digit has the continuation bit
  FTrack.WriteDelay(200);

  AssertScore([$90, $3C, $81, $48]);
end;

procedure TTestMusTrack.TestUnRitardoNonPuoEssereZero;
begin
  FTrack.WriteEvent([$10, $3C], 2);

  Assert.WillRaise(
    procedure
    begin
      FTrack.WriteDelay(0);
    end, EM2mException);
end;

procedure TTestMusTrack.TestUnRitardoVuoleUnEventoPrima;
begin
  Assert.WillRaise(
    procedure
    begin
      FTrack.WriteDelay(5);
    end, EM2mException);
end;

procedure TTestMusTrack.TestDueRitardiConUnEventoScartatoInMezzoSiUniscono;
begin
  FTrack.WriteEvent([$10, $3C], 2);
  FTrack.WriteDelay(10);
  // Nothing is written between the delays. The C code replaced the first one with
  // the second one instead of adding them, and so does this
  FTrack.WriteDelay(20);

  AssertScore([$90, $3C, $14]);
end;

procedure TTestMusTrack.TestUnEventoDopoUnRitardoNonLoCambia;
begin
  FTrack.WriteEvent([$10, $3C], 2);
  FTrack.WriteDelay(10);
  FTrack.WriteEvent([$00, $3C], 2);
  FTrack.WriteDelay(3);

  AssertScore([$90, $3C, $0A, $80, $3C, $03]);
end;

procedure TTestMusTrack.TestLaPartituraNonSuperaIlLimiteDellIntestazione;
var
  LIndex: Integer;
begin
  // 65535 bytes fit and the next one does not
  for LIndex := 1 to 65535 do
    FTrack.WriteEvent([$60], 1);

  Assert.AreEqual(65535, FTrack.Position);
  Assert.WillRaise(
    procedure
    begin
      FTrack.WriteEvent([$60], 1);
    end, EM2mException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMusTrack);

end.
