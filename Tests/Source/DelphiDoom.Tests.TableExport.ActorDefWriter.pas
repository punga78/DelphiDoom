{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the ACTOR writer             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.ActorDefWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportActorDefWriter = class(TObject)
  private
    FThings: TFakeThings;
    FThingsIntf: IExportThingSource;
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FNames: IInterface;
    FWriter: IExportActorDefWriter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeOmettereLeProprietaCheSonoIlDefault;
    [Test]
    procedure TestDovrebbeScrivereProprietaFlagEStati;
    [Test]
    procedure TestDovrebbeScrivereInheritsSoloSeCeIlPadre;
    [Test]
    procedure TestDovrebbeScrivereLoStileDiRenderingEL_Alpha;
    [Test]
    procedure TestDovrebbeScrivereIValoriFissiConQuattroDecimali;
    [Test]
    procedure TestDovrebbeScrivereLeFrasiTraVirgolette;
    [Test]
    procedure TestDovrebbeNonScrivereLIntestazioneOltreLEnumerazione;
    [Test]
    procedure TestDovrebbeScrivereTuttiGliAttori;
    [Test]
    procedure TestDovrebbeScrivereLoStatoCrushNonQuelloCrash;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

const
  EOL = #13#10;

{ TTestTableExportActorDefWriter }

procedure TTestTableExportActorDefWriter.Setup;
begin
  FThings := TFakeThings.Create;
  FThingsIntf := FThings;
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FStates.AddState('NULL', 0, 0, 0);
  FStates.AddState('TROO', 0, 10, 0);
  FNames := TFakeNames.Create;
  FWriter := TTableExportFactory.CreateActorDefWriter(FThingsIntf, FStatesIntf,
    FNames as IExportEnumNames, FNames as IExportFlagNames, FNames as IExportLookups);
end;

procedure TTestTableExportActorDefWriter.TearDown;
begin
  FWriter := nil;
  FNames := nil;
  FStatesIntf := nil;
  FThingsIntf := nil;
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeOmettereLeProprietaCheSonoIlDefault;
begin
  FThings.Items.Add(TFakeThings.Blank('Blank'));
  Assert.AreEqual('// MT_PLAYER' + EOL + 'ACTOR "Thing0"' + EOL + '{' + EOL + '  Width 0' + EOL + '  Height 0' + EOL +
    '  States' + EOL + '  {' + EOL + '  }' + EOL + '}' + EOL + EOL, FWriter.Write(0));
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereProprietaFlagEStati;
var
  LThing: TExportThing;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfDoomedNum] := 3001;
  LThing.Numbers[tfSpawnHealth] := 60;
  LThing.Numbers[tfRadius] := 20 * EXPORT_FRACUNIT;
  LThing.Numbers[tfHeight] := 56 * EXPORT_FRACUNIT;
  LThing.Numbers[tfSpeed] := 8;
  LThing.Numbers[tfPainChance] := 200;
  LThing.Numbers[tfSeeSound] := 1;
  LThing.Numbers[tfFlags] := 6;
  LThing.Numbers[tfSpawnState] := 1;
  FThings.Items.Add(LThing);
  Assert.AreEqual('// MT_PLAYER' + EOL + 'ACTOR "Thing0" 3001' + EOL + '{' + EOL +
    '  Health 60' + EOL + '  Width 20' + EOL + '  Height 56' + EOL + '  Speed 8' + EOL +
    '  Painchance 200' + EOL + '  Seesound DS1' + EOL + '  +MF_SOLID' + EOL + '  +MF_SHOOTABLE' + EOL +
    '  States' + EOL + '  {' + EOL + '    Spawn:' + EOL + '    {' + EOL + '      TROO A 10' + EOL +
    '      Stop' + EOL + '    }' + EOL + '  }' + EOL + '}' + EOL + EOL, FWriter.Write(0));
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereInheritsSoloSeCeIlPadre;
var
  LThing: TExportThing;
begin
  LThing := TFakeThings.Blank('Child');
  LThing.Numbers[tfInheritsFrom] := 1;
  FThings.Items.Add(TFakeThings.Blank('Parent'));
  FThings.Items.Add(LThing);
  Assert.IsTrue(Pos('Inherits "Thing1"', FWriter.Write(1)) > 0);
  Assert.AreEqual(0, Pos('Inherits', FWriter.Write(0)));
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereLoStileDiRenderingEL_Alpha;
var
  LThing: TExportThing;
begin
  LThing := TFakeThings.Blank('Ghost');
  LThing.Numbers[tfRenderStyle] := 1;
  LThing.Numbers[tfAlpha] := EXPORT_FRACUNIT div 2;
  FThings.Items.Add(LThing);
  Assert.IsTrue(Pos('  Renderstyle mrs_translucent' + EOL + '  Alpha 0.5000' + EOL, FWriter.Write(0)) > 0);
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereIValoriFissiConQuattroDecimali;
var
  LThing: TExportThing;
  LText: string;
begin
  LThing := TFakeThings.Blank('Fixed');
  LThing.Numbers[tfVSpeed] := EXPORT_FRACUNIT * 2;
  LThing.Numbers[tfScale] := EXPORT_FRACUNIT div 2;
  LThing.Numbers[tfGravity] := EXPORT_FRACUNIT * 3;
  FThings.Items.Add(LThing);
  LText := FWriter.Write(0);
  Assert.IsTrue(Pos('  Vspeed 2.0000' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  Scale 0.5000' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  Gravity 3.0000' + EOL, LText) > 0);
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereLeFrasiTraVirgolette;
var
  LThing: TExportThing;
  LText: string;
begin
  LThing := TFakeThings.Blank('Talker');
  LThing.Texts[ttObituary] := '%o was shot';
  LThing.Texts[ttTranslation] := 'CRRED';
  FThings.Items.Add(LThing);
  LText := FWriter.Write(0);
  Assert.IsTrue(Pos('  Obituary "%o was shot"' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  Translation "CRRED"' + EOL, LText) > 0);
  Assert.AreEqual(0, Pos('HitObituary', LText));
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeNonScrivereLIntestazioneOltreLEnumerazione;
begin
  FThings.Items.Add(TFakeThings.Blank('A'));
  FThings.Items.Add(TFakeThings.Blank('B'));
  FThings.Items.Add(TFakeThings.Blank('Custom'));
  Assert.AreEqual('ACTOR "Thing2"', Copy(FWriter.Write(2), 1, 14));
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereTuttiGliAttori;
begin
  FThings.Items.Add(TFakeThings.Blank('A'));
  FThings.Items.Add(TFakeThings.Blank('B'));
  Assert.AreEqual(FWriter.Write(0) + FWriter.Write(1), FWriter.WriteAll);
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeScrivereLoStatoCrushNonQuelloCrash;
var
  LThing: TExportThing;
  LText: string;
begin
  // regression: the old code wrote the states of Crash twice and never the ones of Crush
  FStates.AddState('POSS', 1, 5, 0);
  LThing := TFakeThings.Blank('Crusher');
  LThing.Numbers[tfCrashState] := 1;
  LThing.Numbers[tfCrushState] := 2;
  FThings.Items.Add(LThing);
  LText := FWriter.Write(0);
  Assert.IsTrue(Pos('Crash:' + EOL, LText) > 0);
  Assert.IsTrue(Pos('Crush:' + EOL + '    {' + EOL + '      POSS B 5', LText) > 0);
end;

procedure TTestTableExportActorDefWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreateActorDefWriter(nil, FStatesIntf, FNames as IExportEnumNames,
        FNames as IExportFlagNames, FNames as IExportLookups);
    end, EArgumentNilException);
end;

end.
