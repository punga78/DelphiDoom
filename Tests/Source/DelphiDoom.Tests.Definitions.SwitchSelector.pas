{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the choice of the switches   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.SwitchSelector;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf, DelphiDoom.Tests.Definitions.Fakes;

type
  [TestFixture]
  [Category('definitions')]
  TTestSwitchSelector = class(TObject)
  private
    FCatalog: IDefTextureLookup;
    FLog: TFakeLog;
    FLogIntf: ILog;
    function Pair(const AName1, AName2: string; AEpisode: Integer): TDefSwitchPair;
    function Select(const ATable: TArray<TDefSwitchPair>; AMaxEpisode: Integer): TArray<TDefResolvedSwitch>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnaTabellaVuotaNonDaCoppie;
    [Test]
    procedure TestLeCoppieHannoIlNumeroDelleTexture;
    [Test]
    procedure TestSiPrendonoGliEpisodiFinoAlMassimo;
    [Test]
    procedure TestIlTerminatoreConEpisodioMenoUnoFermaLaTabella;
    [Test]
    procedure TestUnaCoppiaConUnNomeVuotoFermaLaTabella;
    [Test]
    procedure TestUnaTextureAssenteEUnAvvisoELaCoppiaSiSalta;
    [Test]
    procedure TestSeManganoTutteEDueLeTextureGliAvvisiSonoDue;
    [Test]
    procedure TestUnaCoppiaDiUnEpisodioSuperioreNonDaAvvisi;
    [Test]
    procedure TestLaCoppiaOriginaleRestaNelRisultato;
    [Test]
    procedure TestSenzaLogLeCoppieSiSaltanoInSilenzio;
  end;

implementation

uses
  DelphiDoom.Definitions.Factory;

{ TTestSwitchSelector }

procedure TTestSwitchSelector.Setup;
begin
  FCatalog := TFakeCatalog.Create([], ['SW1A', 'SW2A', 'SW1B', 'SW2B', 'SW1C', 'SW2C']);
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
end;

procedure TTestSwitchSelector.TearDown;
begin
  FLogIntf := nil;
  FCatalog := nil;
end;

function TTestSwitchSelector.Pair(const AName1, AName2: string; AEpisode: Integer): TDefSwitchPair;
begin
  Result.Name1 := AName1;
  Result.Name2 := AName2;
  Result.Episode := AEpisode;
  Result.Sound := 0;
  Result.SoundName := '';
end;

function TTestSwitchSelector.Select(const ATable: TArray<TDefSwitchPair>;
  AMaxEpisode: Integer): TArray<TDefResolvedSwitch>;
begin
  Result := TDefinitionsFactory.CreateSwitchSelector(FCatalog, FLogIntf).Select(ATable, AMaxEpisode);
end;

procedure TTestSwitchSelector.TestUnaTabellaVuotaNonDaCoppie;
begin
  Assert.AreEqual<Integer>(0, Length(Select(nil, 3)));
end;

procedure TTestSwitchSelector.TestLeCoppieHannoIlNumeroDelleTexture;
var
  LResolved: TArray<TDefResolvedSwitch>;
begin
  LResolved := Select([Pair('SW1B', 'SW2B', 1), Pair('sw1a', 'SW2A', 1)], 3);
  Assert.AreEqual<Integer>(2, Length(LResolved));
  Assert.AreEqual(2, LResolved[0].Texture1);
  Assert.AreEqual(3, LResolved[0].Texture2);
  Assert.AreEqual(0, LResolved[1].Texture1);
  Assert.AreEqual(1, LResolved[1].Texture2);
end;

procedure TTestSwitchSelector.TestSiPrendonoGliEpisodiFinoAlMassimo;
var
  LTable: TArray<TDefSwitchPair>;
begin
  LTable := [Pair('SW1A', 'SW2A', 1), Pair('SW1B', 'SW2B', 2), Pair('SW1C', 'SW2C', 3)];
  Assert.AreEqual<Integer>(1, Length(Select(LTable, 1)));
  Assert.AreEqual<Integer>(2, Length(Select(LTable, 2)));
  Assert.AreEqual<Integer>(3, Length(Select(LTable, 3)));
  Assert.AreEqual<Integer>(0, Length(Select(LTable, 0)));
end;

procedure TTestSwitchSelector.TestIlTerminatoreConEpisodioMenoUnoFermaLaTabella;
begin
  Assert.AreEqual<Integer>(1, Length(Select([Pair('SW1A', 'SW2A', 1), Pair('', '', -1), Pair('SW1B', 'SW2B', 1)], 3)));
  Assert.AreEqual<Integer>(1, Length(Select([Pair('SW1A', 'SW2A', 1), Pair('SW1B', 'SW2B', -1), Pair('SW1C', 'SW2C', 1)], 3)));
end;

procedure TTestSwitchSelector.TestUnaCoppiaConUnNomeVuotoFermaLaTabella;
begin
  Assert.AreEqual<Integer>(1, Length(Select([Pair('SW1A', 'SW2A', 1), Pair('', 'SW2B', 1), Pair('SW1C', 'SW2C', 1)], 3)));
  Assert.AreEqual<Integer>(1, Length(Select([Pair('SW1A', 'SW2A', 1), Pair('SW1B', '', 1), Pair('SW1C', 'SW2C', 1)], 3)));
end;

procedure TTestSwitchSelector.TestUnaTextureAssenteEUnAvvisoELaCoppiaSiSalta;
begin
  Assert.AreEqual<Integer>(1, Length(Select([Pair('NOSUCH', 'SW2A', 1), Pair('SW1B', 'SW2B', 1)], 3)));
  Assert.AreEqual('P_InitSwitchList(): Unknown texture "NOSUCH"'#13#10, FLog.Joined);
end;

procedure TTestSwitchSelector.TestSeManganoTutteEDueLeTextureGliAvvisiSonoDue;
begin
  Assert.AreEqual<Integer>(0, Length(Select([Pair('NO1', 'NO2', 1)], 3)));
  Assert.AreEqual(2, FLog.Count);
end;

procedure TTestSwitchSelector.TestUnaCoppiaDiUnEpisodioSuperioreNonDaAvvisi;
begin
  Assert.AreEqual<Integer>(0, Length(Select([Pair('NO1', 'NO2', 3)], 1)));
  Assert.AreEqual(0, FLog.Count);
end;

procedure TTestSwitchSelector.TestLaCoppiaOriginaleRestaNelRisultato;
var
  LPair: TDefSwitchPair;
begin
  LPair := Pair('SW1A', 'SW2A', 2);
  LPair.Sound := 7;
  LPair.SoundName := 'sfx_x';
  Assert.AreEqual(7, Select([LPair], 3)[0].Pair.Sound);
  Assert.AreEqual('sfx_x', Select([LPair], 3)[0].Pair.SoundName);
end;

procedure TTestSwitchSelector.TestSenzaLogLeCoppieSiSaltanoInSilenzio;
begin
  Assert.AreEqual<Integer>(0, Length(TDefinitionsFactory.CreateSwitchSelector(FCatalog, nil).Select(
    [Pair('NO1', 'SW2A', 1)], 3)));
end;

end.
