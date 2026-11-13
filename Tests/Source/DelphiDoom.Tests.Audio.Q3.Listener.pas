{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of S_SpatializeOrigin of the Quake III sound              }
{                                                                              }
{  Values worked out by hand from the formulas of snd_dma.c; the parity with   }
{  the C is in DelphiDoom.Tests.Audio.Q3.Parity.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Listener;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.Q3.Listener;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Listener = class
  strict private
    FListener: TQ3Listener;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlVolumePienoAlLatoDoveStaIlSuono;
    [Test]
    procedure DovrebbeDareIlVolumePienoAlRevescioDelLatoDestro;
    [Test]
    procedure DovrebbeDividereInPartiUgualiUnSuonoDavanti;
    [Test]
    procedure DovrebbeAttenuareSoloOltreLaDistanzaDiVolumePieno;
    [Test]
    procedure DovrebbeSommareLaDistanzaDalListenerSpostato;
    [Test]
    procedure DovrebbeNonSpazializzareConUnSoloCanale;
    [Test]
    procedure DovrebbeDareSilenzioOltreLaDistanzaMassima;
    [Test]
    procedure DovrebbeTollerareUnSuonoNellaPosizioneDelListener;
    [Test]
    procedure DovrebbeUsareIlVolumeDiBase;
    [Test]
    procedure DovrebbeRuotareConGliAssiDelListener;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiEntitaFuoriIntervallo;
    [Test]
    procedure DovrebbeLimitareASilenzioUnLatoConUnAsseNonUnitario;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Tests.Audio.Q3.Rig;

{ TTestQ3Listener }

procedure TTestQ3Listener.Setup;
begin
  FListener := TQ3Listener.Create;
  FListener.Place(0, Vec3(0, 0, 0), IdentityAxis);
end;

procedure TTestQ3Listener.TearDown;
begin
  FListener.Free;
end;

procedure TTestQ3Listener.DovrebbeDareIlVolumePienoAlLatoDoveStaIlSuono;
var
  LLeft, LRight: Integer;
begin
  // 100 units to the left: dist = (100 - 80) * 0.0008 = 0.016, volume 127 * 0.984
  FListener.SpatializeOrigin(Vec3(0, 100, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(124, LLeft);
  Assert.AreEqual(0, LRight);
end;

procedure TTestQ3Listener.DovrebbeDareIlVolumePienoAlRevescioDelLatoDestro;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(0, -100, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(0, LLeft);
  Assert.AreEqual(124, LRight);
end;

procedure TTestQ3Listener.DovrebbeDividereInPartiUgualiUnSuonoDavanti;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(100, 0, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(62, LLeft);
  Assert.AreEqual(62, LRight);
end;

procedure TTestQ3Listener.DovrebbeAttenuareSoloOltreLaDistanzaDiVolumePieno;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(0, 80, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(127, LLeft);
  FListener.SpatializeOrigin(Vec3(0, 30, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(127, LLeft);
  // 1000 units: (1000 - 80) * 0.0008 = 0.736
  FListener.SpatializeOrigin(Vec3(0, 1000, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(33, LLeft);
end;

procedure TTestQ3Listener.DovrebbeSommareLaDistanzaDalListenerSpostato;
var
  LLeft, LRight: Integer;
begin
  FListener.Place(3, Vec3(0, 500, 0), IdentityAxis);
  Assert.AreEqual(3, FListener.Number);
  FListener.SpatializeOrigin(Vec3(0, 600, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(124, LLeft);
  Assert.AreEqual(0, LRight);
end;

procedure TTestQ3Listener.DovrebbeNonSpazializzareConUnSoloCanale;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(0, 100, 0), 127, 1, LLeft, LRight);
  Assert.AreEqual(124, LLeft);
  Assert.AreEqual(124, LRight);
end;

procedure TTestQ3Listener.DovrebbeDareSilenzioOltreLaDistanzaMassima;
var
  LLeft, LRight: Integer;
begin
  // (3000 - 80) * 0.0008 > 1: the scale is negative and the volumes are clamped to 0
  FListener.SpatializeOrigin(Vec3(0, 3000, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(0, LLeft);
  Assert.AreEqual(0, LRight);
end;

procedure TTestQ3Listener.DovrebbeTollerareUnSuonoNellaPosizioneDelListener;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(0, 0, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(63, LLeft);
  Assert.AreEqual(63, LRight);
end;

procedure TTestQ3Listener.DovrebbeUsareIlVolumeDiBase;
var
  LLeft, LRight: Integer;
begin
  FListener.SpatializeOrigin(Vec3(0, 50, 0), 90, 2, LLeft, LRight);
  Assert.AreEqual(90, LLeft);
  Assert.AreEqual(0, LRight);
  FListener.SpatializeOrigin(Vec3(0, 50, 0), 0, 2, LLeft, LRight);
  Assert.AreEqual(0, LLeft);
end;

procedure TTestQ3Listener.DovrebbeRuotareConGliAssiDelListener;
var
  LAxis: TQ3Axis;
  LLeft, LRight: Integer;
begin
  // the listener looks along +y: its left is -x
  LAxis[0] := Vec3(0, 1, 0);
  LAxis[1] := Vec3(-1, 0, 0);
  LAxis[2] := Vec3(0, 0, 1);
  FListener.Place(0, Vec3(0, 0, 0), LAxis);
  FListener.SpatializeOrigin(Vec3(-50, 0, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(127, LLeft);
  Assert.AreEqual(0, LRight);
  FListener.SpatializeOrigin(Vec3(50, 0, 0), 127, 2, LLeft, LRight);
  Assert.AreEqual(0, LLeft);
  Assert.AreEqual(127, LRight);
end;

procedure TTestQ3Listener.DovrebbeLimitareASilenzioUnLatoConUnAsseNonUnitario;
var
  LAxis: TQ3Axis;
  LLeft, LRight: Integer;
begin
  // an axis of length 2: dot = -2, rscale = 0.5 * (1 - 2) is negative and is clamped to 0,
  // lscale = 0.5 * (1 + 2) = 1.5 (and the other way round with the sound on the right)
  LAxis := IdentityAxis;
  LAxis[1] := Vec3(0, 2, 0);
  FListener.Place(0, Vec3(0, 0, 0), LAxis);
  FListener.SpatializeOrigin(Vec3(0, 50, 0), 100, 2, LLeft, LRight);
  Assert.AreEqual(150, LLeft);
  Assert.AreEqual(0, LRight);
  FListener.SpatializeOrigin(Vec3(0, -50, 0), 100, 2, LLeft, LRight);
  Assert.AreEqual(0, LLeft);
  Assert.AreEqual(150, LRight);
end;

procedure TTestQ3Listener.DovrebbeRifiutareUnNumeroDiEntitaFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      FListener.Place(1024, Vec3(0, 0, 0), IdentityAxis);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      FListener.Place(-1, Vec3(0, 0, 0), IdentityAxis);
    end, EQ3SoundException);
end;

end.
