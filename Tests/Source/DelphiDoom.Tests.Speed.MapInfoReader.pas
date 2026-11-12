{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedMapInfoReader                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.MapInfoReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedMapInfoReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereTuttiICampi;
    [Test]
    procedure DovrebbeLasciareVuotiICampiCheMancano;
    [Test]
    procedure DovrebbeDareZeroPerUnNumeroCheNonEUnNumero;
    [Test]
    procedure DovrebbeSaltareLeRigheSenzaUgualeELeChiaviSconosciute;
    [Test]
    procedure DovrebbeRiconoscereLeChiaviSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTenereLaPrimaRigaDiUnaChiaveRipetuta;
    [Test]
    procedure DovrebbeTenereGliSpaziNelNomeDelCircuito;
    [Test]
    procedure DovrebbeDareUnRecordVuotoPerUnTestoVuoto;
    [Test]
    procedure DovrebbeLeggereIlLumpCheIlTraduttoreScrive;
  end;

implementation

uses
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory, DelphiDoom.Speed.Factory,
  DelphiDoom.Speed.MapInfoReader, DelphiDoom.Tests.Speed.Fakes, DelphiDoom.Tests.Speed.JclBuilder;

{ TTestSpeedMapInfoReader }

procedure TTestSpeedMapInfoReader.DovrebbeLeggereTuttiICampi;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse(
    'sprite=MAPSPR1'#13#10'sky=SKY3'#13#10'mountain=MOUNT2'#13#10'ground=FLAT62'#13#10 +
    'name=Monaco'#13#10'length=3328'#13#10'best=5712'#13#10'level=2'#13#10);

  Assert.AreEqual('MAPSPR1', LInfo.MapSprite);
  Assert.AreEqual('SKY3', LInfo.SkyTexture);
  Assert.AreEqual('MOUNT2', LInfo.MountainTexture);
  Assert.AreEqual('FLAT62', LInfo.GroundTexture);
  Assert.AreEqual('Monaco', LInfo.Name);
  Assert.AreEqual(3328, LInfo.Length);
  Assert.AreEqual(5712, LInfo.Best);
  Assert.AreEqual(2, LInfo.Level);
end;

procedure TTestSpeedMapInfoReader.DovrebbeLasciareVuotiICampiCheMancano;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('name=Test'#10);

  Assert.AreEqual('Test', LInfo.Name);
  Assert.AreEqual('', LInfo.SkyTexture);
  Assert.AreEqual('', LInfo.MapSprite);
  Assert.AreEqual(0, LInfo.Length);
  Assert.AreEqual(0, LInfo.Best);
end;

procedure TTestSpeedMapInfoReader.DovrebbeDareZeroPerUnNumeroCheNonEUnNumero;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('length=long'#10'best='#10'level= 7 '#10);

  Assert.AreEqual(0, LInfo.Length);
  Assert.AreEqual(0, LInfo.Best);
  Assert.AreEqual(7, LInfo.Level);
end;

procedure TTestSpeedMapInfoReader.DovrebbeSaltareLeRigheSenzaUgualeELeChiaviSconosciute;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('a comment'#10'weather=rain'#10#10'sky=SKY1'#10);

  Assert.AreEqual('SKY1', LInfo.SkyTexture);
  Assert.AreEqual('', LInfo.Name);
end;

procedure TTestSpeedMapInfoReader.DovrebbeRiconoscereLeChiaviSenzaDistinguereLeMaiuscole;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('SKY=SKY2'#10' Ground =FLAT7'#10);

  Assert.AreEqual('SKY2', LInfo.SkyTexture);
  Assert.AreEqual('FLAT7', LInfo.GroundTexture);
end;

procedure TTestSpeedMapInfoReader.DovrebbeTenereLaPrimaRigaDiUnaChiaveRipetuta;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('level=3'#10'level=9'#10);

  Assert.AreEqual(3, LInfo.Level);
end;

procedure TTestSpeedMapInfoReader.DovrebbeTenereGliSpaziNelNomeDelCircuito;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('name=Gran Premio = uno'#10);

  Assert.AreEqual('Gran Premio = uno', LInfo.Name);
end;

procedure TTestSpeedMapInfoReader.DovrebbeDareUnRecordVuotoPerUnTestoVuoto;
var
  LInfo: TSpeedMapInfo;
begin
  LInfo := TSpeedMapInfoReader.Parse('');

  Assert.AreEqual('', LInfo.Name);
  Assert.AreEqual('', LInfo.GroundTexture);
  Assert.AreEqual(0, LInfo.Level);
end;

procedure TTestSpeedMapInfoReader.DovrebbeLeggereIlLumpCheIlTraduttoreScrive;
var
  LWad: IGameWadComposer;
  LIndex: Integer;
  LInfo: TSpeedMapInfo;
begin
  LWad := TGameDataFactory.CreateWadComposer;
  TSpeedFactory.CreateTranslator(TFakeLog.Create).Translate(
    TSpeedFactory.OpenContainerBytes(TJclBuilder.SyntheticGame), LWad);
  LIndex := LWad.IndexOf('MAPDATA');
  Assert.IsTrue(LIndex >= 0, 'the synthetic game has a level');

  LInfo := TSpeedMapInfoReader.Parse(TEncoding.ANSI.GetString(LWad.LumpData[LIndex]));

  // the translator always writes the picture and the sky of a circuit
  Assert.AreNotEqual('', LInfo.MapSprite);
  Assert.AreNotEqual('', LInfo.SkyTexture);
  Assert.AreNotEqual('', LInfo.MountainTexture);
end;

end.
