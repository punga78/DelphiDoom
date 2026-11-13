{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - Target and the objects   }
{  of the globe, Node and EquipmentLayoutItem (behaviour the corpus cannot say) }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Targets;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.AlienBase,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.EquipmentLayoutItem,
  DelphiDoom.Tests.XcomSave.ObjectScenario;

type
  [TestFixture]
  [Category('xcom-save')]
  TTestXcomSaveTargets = class(TObject)
  private
    function Load(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeTenereLaLongitudineTraZeroEDuePi;
    [Test]
    procedure DovrebbePassareDallAltraParteDelGlobooOltreIlPolo;
    [Test]
    procedure DovrebbeRifiutareUnAngoloNonFinito;
    [Test]
    procedure DovrebbeDareDistanzaZeroDalloStessoPunto;
    [Test]
    procedure DovrebbeDareLaDistanzaTraDueTarget;
    [Test]
    procedure DovrebbeUsareIlTipoComeNomeDelMarcatore;
    [Test]
    procedure DovrebbeRifiutareUnaBaseAlienaSenzaDeployment;
    [Test]
    procedure DovrebbeRifiutareUnSitoSenzaRegole;
    [Test]
    procedure DovrebbeDareIMarcatoriDelSito;
    [Test]
    procedure DovrebbeCaricareELeggereIDatiDelNodo;
    [Test]
    procedure DovrebbeFarNascereUnElementoDellEquipaggiamentoDaiValori;
  end;

implementation

{ TTestXcomSaveTargets }

function TTestXcomSaveTargets.Load(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestXcomSaveTargets.DovrebbeTenereLaLongitudineTraZeroEDuePi;
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.SetLongitude(-1.0);
    Assert.IsTrue(LWaypoint.Longitude > 5.28);
    LWaypoint.SetLongitude(7.0);
    Assert.IsTrue(Abs(LWaypoint.Longitude - 0.71681469282041) < 1E-12);
  finally
    LWaypoint.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbePassareDallAltraParteDelGlobooOltreIlPolo;
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.SetLongitude(1.0);
    LWaypoint.SetLatitude(2.0);
    Assert.IsTrue(Abs(LWaypoint.Latitude - (Pi - 2.0)) < 1E-12);
    Assert.IsTrue(Abs(LWaypoint.Longitude - (1.0 - Pi + 2 * Pi)) < 1E-12);
    LWaypoint.SetLatitude(-2.0);
    Assert.IsTrue(Abs(LWaypoint.Latitude - (-Pi + 2.0)) < 1E-12);
  finally
    LWaypoint.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeRifiutareUnAngoloNonFinito;
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LWaypoint.SetLongitude(Infinity);
      end, EXcomSaveException);
    Assert.WillRaise(
      procedure
      begin
        LWaypoint.SetLatitude(NaN);
      end, EXcomSaveException);
  finally
    LWaypoint.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeDareDistanzaZeroDalloStessoPunto;
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.SetLongitude(1.0);
    LWaypoint.SetLatitude(0.5);
    Assert.AreEqual(0.0, LWaypoint.Distance(1.0, 0.5), 0.0);
  finally
    LWaypoint.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeDareLaDistanzaTraDueTarget;
var
  LFirst, LSecond: TXcomWaypoint;
begin
  LFirst := TXcomWaypoint.Create;
  LSecond := TXcomWaypoint.Create;
  try
    LSecond.SetLongitude(Pi / 2);
    // a quarter of the equator
    Assert.AreEqual(Pi / 2, LFirst.Distance(LSecond), 1E-12);
    // a point that rounds just outside the range of acos is not a number (nan in C)
    LSecond.SetLongitude(Pi);
    Assert.AreEqual(Pi, LFirst.Distance(LSecond), 1E-9);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeUsareIlTipoComeNomeDelMarcatore;
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.Id := 7;
    Assert.AreEqual('STR_WAY_POINT_', LWaypoint.MarkerName);
    Assert.AreEqual(7, LWaypoint.MarkerId);
    Assert.AreEqual(6, LWaypoint.Marker);
  finally
    LWaypoint.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeRifiutareUnaBaseAlienaSenzaDeployment;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomAlienBase.Create(nil).Free;
    end, EXcomSaveException);
end;

procedure TTestXcomSaveTargets.DovrebbeRifiutareUnSitoSenzaRegole;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomMissionSite.Create(nil, TXcomFakeDeployment.Create('A', 'B', 1)).Free;
    end, EXcomSaveException);
  Assert.WillRaise(
    procedure
    begin
      TXcomMissionSite.Create(TXcomFakeMission.Create('M'), nil).Free;
    end, EXcomSaveException);
end;

procedure TTestXcomSaveTargets.DovrebbeDareIMarcatoriDelSito;
var
  LSite: TXcomMissionSite;
begin
  LSite := TXcomMissionSite.Create(TXcomFakeMission.Create('M'), TXcomFakeDeployment.Create('D', 'STR_SITE', -1));
  try
    Assert.AreEqual(-1, LSite.Marker);
    LSite.Detected := True;
    // no icon: the default marker
    Assert.AreEqual(5, LSite.Marker);
    Assert.AreEqual('STR_SITE', LSite.MarkerName);
    Assert.AreEqual(-1, LSite.Texture);
  finally
    LSite.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeCaricareELeggereIDatiDelNodo;
var
  LNode: TXcomNode;
  LPosition: TXcomPosition;
begin
  LPosition.X := 1;
  LPosition.Y := 2;
  LPosition.Z := 3;
  LNode := TXcomNode.Create(4, LPosition, 1000, 1, 2, 3, 5, 6);
  try
    Assert.IsTrue(LNode.IsTarget);
    Assert.AreEqual(1000, LNode.Segment);
    Assert.AreEqual(2, LNode.Position.Y);
    LNode.NodeType := 9;
    LNode.Load(Load('position: [7, 8]' + #10 + 'links: [1, 2]'));
    // a position that is not three numbers keeps the old one
    Assert.AreEqual(2, LNode.Position.Y);
    Assert.AreEqual<Integer>(2, Length(LNode.Links));
  finally
    LNode.Free;
  end;
end;

procedure TTestXcomSaveTargets.DovrebbeFarNascereUnElementoDellEquipaggiamentoDaiValori;
var
  LItem: TXcomEquipmentLayoutItem;
  LNode: IYamlNode;
begin
  LItem := TXcomEquipmentLayoutItem.Create('STR_RIFLE', 'STR_RIGHT_HAND', 0, 0, 'NONE', -1);
  try
    LNode := LItem.Save;
    Assert.AreEqual(2, LNode.Size);
  finally
    LItem.Free;
  end;
end;

end.
