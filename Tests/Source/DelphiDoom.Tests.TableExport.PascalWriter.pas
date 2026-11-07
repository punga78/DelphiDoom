{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the Pascal writer            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.PascalWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Profile, DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportPascalWriter = class(TObject)
  private
    FThings: TFakeThings;
    FThingsIntf: IExportThingSource;
    FBuiltIn: TFakeThings;
    FBuiltInIntf: IExportThingSource;
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FNames: IInterface;
    function Writer(AGame: TExportGame; AWithBuiltIn: Boolean = False): IExportPascalWriter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeScrivereLeAssegnazioniDiUnaCosa;
    [Test]
    procedure TestDovrebbeScrivereGliStatiESuoniComeOrdinali;
    [Test]
    procedure TestDovrebbeScrivereIValoriFissiEICostanti;
    [Test]
    procedure TestDovrebbeElencareIFlagConOr;
    [Test]
    procedure TestDovrebbeRaddoppiareGliApiciDelleFrasi;
    [Test]
    procedure TestDovrebbeNominareLoStileDiRenderingOltreLaSuaEnumerazione;
    [Test]
    procedure TestDovrebbeNominareISuoniOltreLaLoroEnumerazione;
    [Test]
    procedure TestDovrebbeScrivereFlags2SoloInHereticEHexen;
    [Test]
    procedure TestDovrebbeScrivereName2SoloInStrife;
    [Test]
    procedure TestDovrebbeScrivereLaSelezioneDiCosePerIntervallo;
    [Test]
    procedure TestDovrebbeScrivereLeCostantiDiUnArrayTipizzato;
    [Test]
    procedure TestDovrebbeUsareLaTabellaIncorporataPerTuttoLIntervallo;
    [Test]
    procedure TestDovrebbeScrivereGliStati;
    [Test]
    procedure TestDovrebbeScrivereLAzioneDiUnoStato;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

const
  EOL = #13#10;

{ TTestTableExportPascalWriter }

procedure TTestTableExportPascalWriter.Setup;
begin
  FThings := TFakeThings.Create;
  FThingsIntf := FThings;
  FBuiltIn := TFakeThings.Create;
  FBuiltInIntf := FBuiltIn;
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FNames := TFakeNames.Create;
  FStates.AddState('NULL', 0, 0, 0);
  FStates.AddState('TROO', 0, 4, 2);
  FStates.AddState('TROO', 1, 4, 1);
end;

procedure TTestTableExportPascalWriter.TearDown;
begin
  FNames := nil;
  FStatesIntf := nil;
  FBuiltInIntf := nil;
  FThingsIntf := nil;
end;

function TTestTableExportPascalWriter.Writer(AGame: TExportGame; AWithBuiltIn: Boolean): IExportPascalWriter;
var
  LBuiltIn: IExportThingSource;
begin
  if AWithBuiltIn then
    LBuiltIn := FBuiltInIntf
  else
    LBuiltIn := nil;
  Result := TTableExportFactory.CreatePascalWriter(AGame, FThingsIntf, LBuiltIn, FStatesIntf,
    FNames as IExportEnumNames, FNames as IExportFlagNames, FNames as IExportLookups);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereLeAssegnazioniDiUnaCosa;
var
  LText: string;
begin
  FThings.Items.Add(TFakeThings.Blank('Imp'));
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('  // MT_PLAYER' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  mobjinfo[Ord(MT_PLAYER)].name := ''Imp'';' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  mobjinfo[Ord(MT_PLAYER)].inheritsfrom := -1;' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  mobjinfo[Ord(MT_PLAYER)].gender := gender_Default;' + EOL, LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereGliStatiESuoniComeOrdinali;
var
  LThing: TExportThing;
  LText: string;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfSpawnState] := 1;
  LThing.Numbers[tfSeeState] := 7;
  LThing.Numbers[tfSeeSound] := 1;
  FThings.Items.Add(LThing);
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('.spawnstate := Ord(S_FIRST);', LText) > 0);
  Assert.IsTrue(Pos('.seestate := 7;', LText) > 0);
  Assert.IsTrue(Pos('.seesound := Ord(sfx_pistol);', LText) > 0);
  Assert.IsTrue(Pos('.painstate := Ord(S_NULL);', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereIValoriFissiEICostanti;
var
  LThing: TExportThing;
  LText: string;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfRadius] := 20 * EXPORT_FRACUNIT;
  LThing.Numbers[tfHeight] := EXPORT_FRACUNIT;
  LThing.Numbers[tfSpeed] := 8;
  LThing.Numbers[tfFloatSpeed] := -EXPORT_FRACUNIT;
  LThing.Numbers[tfFriction] := 1234;
  FThings.Items.Add(LThing);
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('.radius := 20 * FRACUNIT;', LText) > 0);
  Assert.IsTrue(Pos('.height := FRACUNIT;', LText) > 0);
  Assert.IsTrue(Pos('.speed := 8;', LText) > 0);
  Assert.IsTrue(Pos('.floatspeed := -FRACUNIT;', LText) > 0);
  Assert.IsTrue(Pos('.pushfactor := DEFPUSHFACTOR;', LText) > 0);
  Assert.IsTrue(Pos('.friction := 1234;', LText) > 0);
  Assert.IsTrue(Pos('.scale := FRACUNIT;', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeElencareIFlagConOr;
var
  LThing: TExportThing;
  LText: string;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfFlags] := 6;
  FThings.Items.Add(LThing);
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('.flags := MF_SOLID or MF_SHOOTABLE;', LText) > 0);
  Assert.IsTrue(Pos('.flags_ex := 0;', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeRaddoppiareGliApiciDelleFrasi;
var
  LThing: TExportThing;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Texts[ttObituary] := '%o was ''burnt''';
  FThings.Items.Add(LThing);
  Assert.IsTrue(Pos('.obituary := ''%o was ''''burnt'''''';', Writer(TExportGame.Doom).Things) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeNominareLoStileDiRenderingOltreLaSuaEnumerazione;
var
  LThing: TExportThing;
  LText: string;
begin
  // regression: the old code compared the style with the number of the genders
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfRenderStyle] := 4;
  FThings.Items.Add(LThing);
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('.renderstyle := mobjrenderstyle_t(4);', LText) > 0);
  FThings.Items[0] := TFakeThings.Blank('Imp');
  Assert.IsTrue(Pos('.renderstyle := mrs_normal;', Writer(TExportGame.Doom).Things) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeNominareISuoniOltreLaLoroEnumerazione;
var
  LThing: TExportThing;
  LText: string;
begin
  // regression: the old code compared the sound with the number of the songs
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfDeathSound] := 2;
  LThing.Numbers[tfPainSound] := 3;
  FThings.Items.Add(LThing);
  LText := Writer(TExportGame.Doom).Things;
  Assert.IsTrue(Pos('.deathsound := Ord(sfx_shotgn);', LText) > 0);
  Assert.IsTrue(Pos('.painsound := 3;', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereFlags2SoloInHereticEHexen;
begin
  FThings.Items.Add(TFakeThings.Blank('Imp'));
  Assert.AreEqual(0, Pos('.flags2 :=', Writer(TExportGame.Doom).Things));
  Assert.AreEqual(0, Pos('.flags2 :=', Writer(TExportGame.Strife).Things));
  Assert.IsTrue(Pos('.flags2 := 0;', Writer(TExportGame.Heretic).Things) > 0);
  Assert.IsTrue(Pos('.flags2 := 0;', Writer(TExportGame.Hexen).Things) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereName2SoloInStrife;
var
  LThing: TExportThing;
begin
  LThing := TFakeThings.Blank('Imp');
  LThing.Texts[ttName2] := 'Acolyte';
  FThings.Items.Add(LThing);
  Assert.IsTrue(Pos('.name2 := ''Acolyte'';', Writer(TExportGame.Strife).Things) > 0);
  Assert.AreEqual(0, Pos('.name2', Writer(TExportGame.Doom).Things));
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereLaSelezioneDiCosePerIntervallo;
var
  LText: string;
begin
  FThings.Items.Add(TFakeThings.Blank('A'));
  FThings.Items.Add(TFakeThings.Blank('B'));
  FThings.Items.Add(TFakeThings.Blank('C'));
  LText := Writer(TExportGame.Doom).Things(1, 1);
  Assert.AreEqual(0, Pos('.name := ''A''', LText));
  Assert.IsTrue(Pos('.name := ''B''', LText) > 0);
  Assert.AreEqual(0, Pos('.name := ''C''', LText));
  Assert.IsTrue(Pos('// #2', Writer(TExportGame.Doom).Things(2, 2)) > 0);
  Assert.IsTrue(Pos('mobjinfo[2].name', Writer(TExportGame.Doom).Things(2, 2)) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereLeCostantiDiUnArrayTipizzato;
var
  LText: string;
  LField: string;
begin
  FThings.Items.Add(TFakeThings.Blank('Imp'));
  FThings.Items.Add(TFakeThings.Blank('Cacodemon'));
  FThings.Items.Add(TFakeThings.Blank('Custom'));
  LText := Writer(TExportGame.Doom).ThingConstants;
  Assert.IsTrue(Pos('  (' + EOL, LText) > 0);
  Assert.IsTrue(Pos('   ( // MT_PLAYER' + EOL, LText) > 0);
  Assert.IsTrue(Pos('   ( // #2 (2)' + EOL, LText) > 0);
  LField := '    name: ''Imp'';';
  LField := LField + StringOfChar(' ', 79 - Length(LField)) + ' // name' + EOL;
  Assert.IsTrue(Pos(LField, LText) > 0);
  Assert.IsTrue(Pos('   ),' + EOL, LText) > 0);
  Assert.IsTrue(Pos('   )' + EOL, LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeUsareLaTabellaIncorporataPerTuttoLIntervallo;
begin
  FThings.Items.Add(TFakeThings.Blank('Current0'));
  FThings.Items.Add(TFakeThings.Blank('Current1'));
  FBuiltIn.Items.Add(TFakeThings.Blank('Original0'));
  FBuiltIn.Items.Add(TFakeThings.Blank('Original1'));
  // the fake game has two built in things: the range 0..1 is all of them
  Assert.IsTrue(Pos('''Original0''', Writer(TExportGame.Doom, True).ThingConstants(0, 1)) > 0);
  Assert.AreEqual(0, Pos('''Original1''', Writer(TExportGame.Doom, True).ThingConstants(0, 0)));
  Assert.IsTrue(Pos('''Current0''', Writer(TExportGame.Doom, True).ThingConstants(0, 0)) > 0);
  Assert.IsTrue(Pos('''Current0''', Writer(TExportGame.Doom, False).ThingConstants(0, 1)) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereGliStati;
var
  LText: string;
begin
  LText := Writer(TExportGame.Doom).States;
  Assert.IsTrue(Pos('  // S_NULL' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  states[Ord(S_FIRST)].nextstate := S_SECOND;' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  states[Ord(S_SECOND)].nextstate := S_FIRST;' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  states[Ord(S_FIRST)].tics := 4;' + EOL, LText) > 0);
  Assert.IsTrue(Pos('  states[Ord(S_FIRST)].flags_ex := 0;' + EOL, LText) > 0);
  Assert.IsTrue(Pos('.sprite := Ord(SPR_NULL);', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeScrivereLAzioneDiUnoStato;
var
  LState: TExportState;
  LText: string;
begin
  LState := FStates.Items[1];
  LState.ActionName := 'CHASE';
  FStates.Items[1] := LState;
  LState := FStates.Items[2];
  LState.ActionName := 'NULL';
  FStates.Items[2] := LState;
  LText := Writer(TExportGame.Doom).States;
  Assert.IsTrue(Pos('states[Ord(S_FIRST)].action.acp1 := @A_Chase;', LText) > 0);
  Assert.IsTrue(Pos('states[Ord(S_SECOND)].action.acp1 := nil;', LText) > 0);
  Assert.IsTrue(Pos('states[Ord(S_NULL)].action.acp1 := nil;', LText) > 0);
end;

procedure TTestTableExportPascalWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreatePascalWriter(TExportGame.Doom, nil, nil, FStatesIntf,
        FNames as IExportEnumNames, FNames as IExportFlagNames, FNames as IExportLookups);
    end, EArgumentNilException);
end;

end.
