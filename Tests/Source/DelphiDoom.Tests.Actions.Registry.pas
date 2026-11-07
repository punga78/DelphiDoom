{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the registry of the actions                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Actions.Registry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Actions.Intf;

type
  [TestFixture]
  [Category('actions')]
  TTestActionsRegistry = class(TObject)
  private
    FRegistry: IActionRegistry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeDareGliIndiciInOrdineDiRegistrazione;
    [Test]
    procedure DovrebbeTrovarePerNomeSenzaDistinguereMaiuscole;
    [Test]
    procedure DovrebbeTrovarePerNomeConOSenzaPrefisso;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnNomeSconosciuto;
    [Test]
    procedure DovrebbeTrovarePerGestore;
    [Test]
    procedure DovrebbeDareIlNomeDatoIlGestore;
    [Test]
    procedure DovrebbeDareStringaVuotaPerUnGestoreSconosciuto;
    [Test]
    procedure DovrebbeAccettareIlGestoreNilComeAzioneNulla;
    [Test]
    procedure DovrebbeDareErroreSeUnNomeHaUnGestoreDiverso;
    [Test]
    procedure DovrebbeDareErroreSeUnNomeSiRipeteConaltroPrefisso;
    [Test]
    procedure DovrebbeTenereLoSlotSeLoStessoNomeHaLoStessoGestore;
    [Test]
    procedure DovrebbeTrovareAncheLeAzioniDopoLaCinquecentesima;
    [Test]
    procedure DovrebbeConservareGliArgomentiDiDefault;
    [Test]
    procedure DovrebbeNonCambiareGliArgomentiDopoLaRegistrazione;
    [Test]
    procedure DovrebbeConservareLaDichiarazione;
    [Test]
    procedure DovrebbeDareIlNomeOriginaleSenzaPrefissoEQuelloInMaiuscolo;
    [Test]
    procedure DovrebbeDareErroreSeLIndiceEFuoriDalloIntervallo;
    [Test]
    procedure DovrebbeDareIlGestoreAlias;
    [Test]
    procedure DovrebbeDareIPrimiNomiDelGestoreRipetuto;
    [Test]
    procedure DovrebbeDareLeListeDeiNomi;
    [Test]
    procedure DovrebbeDareNomiOrdinatiESenzaRipetizioni;
  end;

implementation

uses
  DelphiDoom.Actions.Factory;

var
  GHandlerA: Integer;
  GHandlerB: Integer;
  GHandlerC: Integer;

{ TTestActionsRegistry }

procedure TTestActionsRegistry.Setup;
begin
  FRegistry := TActionsFactory.CreateRegistry;
end;

procedure TTestActionsRegistry.TearDown;
begin
  FRegistry := nil;
end;

procedure TTestActionsRegistry.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FRegistry.Count);
  Assert.AreEqual(-1, FRegistry.IndexOfName('A_Look'));
  Assert.AreEqual(0, Length(FRegistry.Names));
end;

procedure TTestActionsRegistry.DovrebbeDareGliIndiciInOrdineDiRegistrazione;
begin
  Assert.AreEqual(0, FRegistry.Register('NULL', nil, [], ''));
  Assert.AreEqual(1, FRegistry.Register('A_Look', @GHandlerA, [], 'A_Look()'));
  Assert.AreEqual(2, FRegistry.Register('A_Chase', @GHandlerB, [], 'A_Chase()'));
  Assert.AreEqual(3, FRegistry.Count);
end;

procedure TTestActionsRegistry.DovrebbeTrovarePerNomeSenzaDistinguereMaiuscole;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.AreEqual(0, FRegistry.IndexOfName('LOOK'));
  Assert.AreEqual(0, FRegistry.IndexOfName('look'));
  Assert.AreEqual(0, FRegistry.IndexOfName('LoOk'));
end;

procedure TTestActionsRegistry.DovrebbeTrovarePerNomeConOSenzaPrefisso;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.AreEqual(0, FRegistry.IndexOfName('A_Look'));
  Assert.AreEqual(0, FRegistry.IndexOfName('a_look'));
  Assert.AreEqual(0, FRegistry.IndexOfName('Look'));
end;

procedure TTestActionsRegistry.DovrebbeDareMenoUnoPerUnNomeSconosciuto;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.AreEqual(-1, FRegistry.IndexOfName('A_Chase'));
  Assert.AreEqual(-1, FRegistry.IndexOfName(''));
end;

procedure TTestActionsRegistry.DovrebbeTrovarePerGestore;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  FRegistry.Register('A_Chase', @GHandlerB, [], '');
  Assert.AreEqual(1, FRegistry.IndexOfHandler(@GHandlerB));
  Assert.AreEqual(-1, FRegistry.IndexOfHandler(@GHandlerC));
end;

procedure TTestActionsRegistry.DovrebbeDareIlNomeDatoIlGestore;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.AreEqual('LOOK', FRegistry.NameOfHandler(@GHandlerA));
end;

procedure TTestActionsRegistry.DovrebbeDareStringaVuotaPerUnGestoreSconosciuto;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.AreEqual('', FRegistry.NameOfHandler(@GHandlerC));
end;

procedure TTestActionsRegistry.DovrebbeAccettareIlGestoreNilComeAzioneNulla;
begin
  FRegistry.Register('NULL', nil, [], '');
  Assert.AreEqual(0, FRegistry.IndexOfHandler(nil));
  Assert.AreEqual('NULL', FRegistry.NameOfHandler(nil));
end;

procedure TTestActionsRegistry.DovrebbeDareErroreSeUnNomeHaUnGestoreDiverso;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Register('A_Look', @GHandlerB, [], '');
    end,
    EActionRegistryException);
  Assert.AreEqual(1, FRegistry.Count);
end;

procedure TTestActionsRegistry.DovrebbeDareErroreSeUnNomeSiRipeteConaltroPrefisso;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Register('LOOK', @GHandlerB, [], '');
    end,
    EActionRegistryException);
end;

procedure TTestActionsRegistry.DovrebbeTenereLoSlotSeLoStessoNomeHaLoStessoGestore;
begin
  FRegistry.Register('A_NoBlocking', @GHandlerA, [], '');
  FRegistry.Register('A_Chase', @GHandlerB, [], '');
  Assert.AreEqual(2, FRegistry.Register('A_NoBlocking', @GHandlerA, [], ''));
  Assert.AreEqual(3, FRegistry.Count);
  // the search keeps the first one
  Assert.AreEqual(0, FRegistry.IndexOfName('NOBLOCKING'));
  Assert.AreEqual(0, FRegistry.IndexOfHandler(@GHandlerA));
  Assert.AreEqual('NOBLOCKING', FRegistry.Entry(2).Name);
end;

procedure TTestActionsRegistry.DovrebbeTrovareAncheLeAzioniDopoLaCinquecentesima;
var
  LIndex: Integer;
begin
  // the old table stopped at 500 (600 in Hexen)
  for LIndex := 0 to 1999 do
    FRegistry.Register('A_Action' + IntToStr(LIndex), Pointer(NativeInt(LIndex + 1)), [], '');
  Assert.AreEqual(2000, FRegistry.Count);
  Assert.AreEqual(1999, FRegistry.IndexOfName('Action1999'));
  Assert.AreEqual(1500, FRegistry.IndexOfHandler(Pointer(NativeInt(1501))));
end;

procedure TTestActionsRegistry.DovrebbeConservareGliArgomentiDiDefault;
var
  LEntry: TActionEntry;
begin
  FRegistry.Register('A_Weapon', @GHandlerA, [3, -1, 65536], 'A_Weapon(a, b, c: integer);');
  LEntry := FRegistry.Entry(0);
  Assert.AreEqual(3, Length(LEntry.DefaultArguments));
  Assert.AreEqual(3, LEntry.DefaultArguments[0]);
  Assert.AreEqual(-1, LEntry.DefaultArguments[1]);
  Assert.AreEqual(65536, LEntry.DefaultArguments[2]);
end;

procedure TTestActionsRegistry.DovrebbeNonCambiareGliArgomentiDopoLaRegistrazione;
var
  LEntry: TActionEntry;
begin
  FRegistry.Register('A_Weapon', @GHandlerA, [7], '');
  LEntry := FRegistry.Entry(0);
  LEntry.DefaultArguments[0] := 99;
  Assert.AreEqual(7, FRegistry.Entry(0).DefaultArguments[0]);
end;

procedure TTestActionsRegistry.DovrebbeConservareLaDichiarazione;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], 'A_Look();');
  Assert.AreEqual('A_Look();', FRegistry.Entry(0).Declaration);
  Assert.AreEqual(Pointer(@GHandlerA), FRegistry.Entry(0).Handler);
end;

procedure TTestActionsRegistry.DovrebbeDareIlNomeOriginaleSenzaPrefissoEQuelloInMaiuscolo;
begin
  FRegistry.Register('A_BrainAwake', @GHandlerA, [], '');
  Assert.AreEqual('BrainAwake', FRegistry.Entry(0).OriginalName);
  Assert.AreEqual('BRAINAWAKE', FRegistry.Entry(0).Name);
end;

procedure TTestActionsRegistry.DovrebbeDareErroreSeLIndiceEFuoriDalloIntervallo;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Entry(1);
    end,
    EActionRegistryException);
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Entry(-1);
    end,
    EActionRegistryException);
end;

procedure TTestActionsRegistry.DovrebbeDareIlGestoreAlias;
begin
  // A_Quake and A_LocalEarthQuake are two names of the same code
  FRegistry.Register('A_LocalEarthQuake', @GHandlerA, [], '');
  FRegistry.Register('A_Quake', @GHandlerA, [], '');
  Assert.AreEqual(Pointer(@GHandlerA), FRegistry.Entry(FRegistry.IndexOfName('Quake')).Handler);
  Assert.AreEqual(Pointer(@GHandlerA), FRegistry.Entry(FRegistry.IndexOfName('LocalEarthQuake')).Handler);
end;

procedure TTestActionsRegistry.DovrebbeDareIPrimiNomiDelGestoreRipetuto;
begin
  FRegistry.Register('A_LocalEarthQuake', @GHandlerA, [], '');
  FRegistry.Register('A_Quake', @GHandlerA, [], '');
  Assert.AreEqual('LOCALEARTHQUAKE', FRegistry.NameOfHandler(@GHandlerA));
  Assert.AreEqual(0, FRegistry.IndexOfHandler(@GHandlerA));
end;

procedure TTestActionsRegistry.DovrebbeDareLeListeDeiNomi;
var
  LNames: TArray<string>;
begin
  FRegistry.Register('NULL', nil, [], '');
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  FRegistry.Register('A_Chase', @GHandlerB, [], '');
  LNames := FRegistry.Names;
  Assert.AreEqual(3, Length(LNames));
  Assert.AreEqual('NULL', LNames[0]);
  Assert.AreEqual('LOOK', LNames[1]);
  Assert.AreEqual('CHASE', LNames[2]);
end;

procedure TTestActionsRegistry.DovrebbeDareNomiOrdinatiESenzaRipetizioni;
var
  LNames: TArray<string>;
begin
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  FRegistry.Register('A_Chase', @GHandlerB, [], '');
  FRegistry.Register('A_Look', @GHandlerA, [], '');
  FRegistry.Register('A_Fall', @GHandlerC, [], '');
  LNames := FRegistry.SortedNames;
  Assert.AreEqual(3, Length(LNames));
  Assert.AreEqual('CHASE', LNames[0]);
  Assert.AreEqual('FALL', LNames[1]);
  Assert.AreEqual('LOOK', LNames[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActionsRegistry);

end.
