{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - campaigns, victory and defeat        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Campaign;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types,
  DelphiDoom.War.Campaign.Intf;

type
  /// <summary>A census written by hand: the units of each of the two players and the buildings of the first</summary>
  TFakeCensus = class(TInterfacedObject, IWarCensus)
  public
    Race: TWarRace;
    Units: array[0..1] of Integer;
    Dudes: array[0..1] of Integer;
    Buildings: array[0..WAR_UNIT_COUNT - 1] of Integer;
    function GetPlayerRace(APlayer: Integer): TWarRace;
    function GetBuildingsOfType(APlayer: Integer; AUnitType: Byte): Integer;
    function GetTotalUnits(APlayer: Integer): Integer;
    function GetTotalDudes(APlayer: Integer): Integer;
  end;

  /// <summary>
  ///   campaigns.golden.txt and objectives.golden.txt are the output of war_lvl_ref.exe: war_campaigns.c of war1
  ///   as it is (the table, wcamp_tryGetMapType, wcamp_getCampaignData and the three functions of victory and
  ///   defeat), compiled with gcc (Tools\Verifica\193); the counts of units come from scenarios with a fixed seed
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarCampaign = class(TObject)
  private
    function Escaped(const AText: AnsiString): string;
    function Census(ARace: TWarRace; AUnits0, AUnits1, ADudes1: Integer): TFakeCensus;
  public
    [Test]
    procedure DovrebbeDareLaMissioneDiOgniRazza;
    [Test]
    procedure DovrebbeRifiutareUnaMissioneOUnaRazzaNonValida;
    [Test]
    procedure DovrebbeDareIDatiDiUnaMappaDellaCampagna;
    [Test]
    procedure DovrebbeDareLaMappaPersonalizzataPerUnTipoSconosciuto;
    [Test]
    procedure DovrebbeDareIlTipoDiMappaDiUnLivello;
    [Test]
    procedure DovrebbeRiconoscereLUltimoLivelloDellaDemo;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaDiLunghezzaSbagliata;
    [Test]
    procedure DovrebbeVincereLaMappaUnoConSeiFattorieEUnaCaserma;
    [Test]
    procedure DovrebbeUsareLeFattorieELeCasermeDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbePerdereLaMappaUnoSenzaPiuUnita;
    [Test]
    procedure DovrebbeDareLaVittoriaPrimaDellaSconfitta;
    [Test]
    procedure DovrebbeVincereLaMappaDueSenzaCombattentiNemici;
    [Test]
    procedure DovrebbeVincereLaMappaPersonalizzataSenzaUnitaNemiche;
    [Test]
    procedure DovrebbeNonAvereCondizioniNelleAltreMappe;
    [Test]
    procedure DovrebbeDareLaStessaTabellaDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareLeStesseCondizioniDelCodiceOriginale;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Campaign.Catalog, DelphiDoom.War.Level.Factory,
  DelphiDoom.Tests.War.RealData;

{ TFakeCensus }

function TFakeCensus.GetPlayerRace(APlayer: Integer): TWarRace;
begin
  if APlayer = 0 then
    Result := Race
  else if Race = wraHumans then
    Result := wraOrcs
  else
    Result := wraHumans;
end;

function TFakeCensus.GetBuildingsOfType(APlayer: Integer; AUnitType: Byte): Integer;
begin
  if APlayer = 0 then
    Result := Buildings[AUnitType]
  else
    Result := 0;
end;

function TFakeCensus.GetTotalUnits(APlayer: Integer): Integer;
begin
  Result := Units[APlayer];
end;

function TFakeCensus.GetTotalDudes(APlayer: Integer): Integer;
begin
  Result := Dudes[APlayer];
end;

{ TTestWarCampaign }

function TTestWarCampaign.Escaped(const AText: AnsiString): string;
var
  LIndex: Integer;
begin
  Result := '"';
  for LIndex := 1 to Length(AText) do
    case AText[LIndex] of
      #10: Result := Result + '\n';
      #9: Result := Result + '\t';
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
    else
      Result := Result + Char(AText[LIndex]);
    end;
  Result := Result + '"';
end;

function TTestWarCampaign.Census(ARace: TWarRace; AUnits0, AUnits1, ADudes1: Integer): TFakeCensus;
begin
  Result := TFakeCensus.Create;
  Result.Race := ARace;
  Result.Units[0] := AUnits0;
  Result.Units[1] := AUnits1;
  Result.Dudes[1] := ADudes1;
end;

procedure TTestWarCampaign.DovrebbeDareLaMissioneDiOgniRazza;
var
  LCampaigns: IWarCampaigns;
  LMapType: Integer;
begin
  LCampaigns := TWarLevelFactory.CreateCampaigns;
  Assert.IsTrue(LCampaigns.TryGetMapType(wraHumans, 1, LMapType));
  Assert.AreEqual(WAR_CAMPAIGN_HUMANS_01, LMapType);
  Assert.IsTrue(LCampaigns.TryGetMapType(wraOrcs, 1, LMapType));
  Assert.AreEqual(WAR_CAMPAIGN_ORCS_01, LMapType);
  Assert.IsTrue(LCampaigns.TryGetMapType(wraOrcs, 12, LMapType));
  Assert.AreEqual(WAR_CAMPAIGN_ORCS_12, LMapType);
  Assert.IsTrue(LCampaigns.TryGetMapType(wraHumans, 2, LMapType));
  Assert.AreEqual(WAR_CAMPAIGN_HUMANS_02, LMapType);
end;

procedure TTestWarCampaign.DovrebbeRifiutareUnaMissioneOUnaRazzaNonValida;
var
  LCampaigns: IWarCampaigns;
  LMapType: Integer;
begin
  LCampaigns := TWarLevelFactory.CreateCampaigns;
  Assert.IsFalse(LCampaigns.TryGetMapType(wraHumans, 0, LMapType));
  Assert.AreEqual(0, LMapType);
  Assert.IsFalse(LCampaigns.TryGetMapType(wraHumans, 13, LMapType));
  Assert.IsFalse(LCampaigns.TryGetMapType(wraNeutral, 1, LMapType));
end;

procedure TTestWarCampaign.DovrebbeDareIDatiDiUnaMappaDellaCampagna;
var
  LData: TWarCampaignMapData;
begin
  LData := TWarLevelFactory.CreateCampaigns.GetData(WAR_CAMPAIGN_HUMANS_02);
  Assert.AreEqual(WAR_CAMPAIGN_HUMANS_02, LData.MapType);
  Assert.IsTrue(LData.Rule = worDefendAndDestroy);
  Assert.AreEqual(AnsiString('Defend town and'#10'destroy orcs'), LData.Objectives);
  Assert.AreEqual(552, LData.BriefingAudioId);
  Assert.AreEqual<Single>(20, LData.BriefingDuration);
  Assert.IsTrue(Pos('Grand Hamlet', string(LData.BriefingText)) > 0);
end;

procedure TTestWarCampaign.DovrebbeDareLaMappaPersonalizzataPerUnTipoSconosciuto;
var
  LData: TWarCampaignMapData;
begin
  // the original used the type (e.g. 7) as an index of its table of 25 entries only for the custom one (141);
  // a type that is not in the table got an out of range read
  LData := TWarLevelFactory.CreateCampaigns.GetData(7);
  Assert.AreEqual(WAR_CAMPAIGN_CUSTOM, LData.MapType);
  Assert.AreEqual(AnsiString('Destroy enemy'), LData.Objectives);
  Assert.AreEqual(AnsiString(''), LData.BriefingText);
end;

procedure TTestWarCampaign.DovrebbeDareIlTipoDiMappaDiUnLivello;
var
  LCampaigns: IWarCampaigns;
begin
  LCampaigns := TWarLevelFactory.CreateCampaigns;
  Assert.AreEqual(117, LCampaigns.MapTypeOfLevel(117));
  Assert.AreEqual(140, LCampaigns.MapTypeOfLevel(140));
  Assert.AreEqual(WAR_CAMPAIGN_CUSTOM, LCampaigns.MapTypeOfLevel(141));
  Assert.AreEqual(WAR_CAMPAIGN_CUSTOM, LCampaigns.MapTypeOfLevel(147));
  Assert.AreEqual(WAR_CAMPAIGN_CUSTOM, LCampaigns.MapTypeOfLevel(116));
end;

procedure TTestWarCampaign.DovrebbeRiconoscereLUltimoLivelloDellaDemo;
var
  LCampaigns: IWarCampaigns;
begin
  LCampaigns := TWarLevelFactory.CreateCampaigns;
  Assert.IsTrue(LCampaigns.IsDemoLastLevel(119));
  Assert.IsTrue(LCampaigns.IsDemoLastLevel(120));
  Assert.IsFalse(LCampaigns.IsDemoLastLevel(117));
  Assert.IsFalse(LCampaigns.IsDemoLastLevel(121));
end;

procedure TTestWarCampaign.DovrebbeRifiutareUnaTabellaDiLunghezzaSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCampaigns.Create(nil);
    end, EWarException);
end;

procedure TTestWarCampaign.DovrebbeVincereLaMappaUnoConSeiFattorieEUnaCaserma;
var
  LCensus: TFakeCensus;
  LHolder: IWarCensus;
begin
  LCensus := Census(wraHumans, 3, 3, 3);
  LHolder := LCensus;
  LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := 6;
  LCensus.Buildings[WAR_UNIT_BARRACKS_HUMANS] := 1;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_01, LHolder) = wlrWin);
  LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := 5;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_01, LHolder) = wlrNone);
  LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := 6;
  LCensus.Buildings[WAR_UNIT_BARRACKS_HUMANS] := 0;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_01, LHolder) = wlrNone);
end;

procedure TTestWarCampaign.DovrebbeUsareLeFattorieELeCasermeDellaRazzaDelGiocatore;
var
  LCensus: TFakeCensus;
  LHolder: IWarCensus;
begin
  LCensus := Census(wraOrcs, 3, 3, 3);
  LHolder := LCensus;
  LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := 6;
  LCensus.Buildings[WAR_UNIT_BARRACKS_HUMANS] := 1;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_ORCS_01, LHolder) = wlrNone);
  LCensus.Buildings[WAR_UNIT_FARM_ORCS] := 7;
  LCensus.Buildings[WAR_UNIT_BARRACKS_ORCS] := 2;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_ORCS_01, LHolder) = wlrWin);
end;

procedure TTestWarCampaign.DovrebbePerdereLaMappaUnoSenzaPiuUnita;
var
  LHolder: IWarCensus;
begin
  LHolder := Census(wraHumans, 0, 3, 3);
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_01, LHolder) = wlrLose);
end;

procedure TTestWarCampaign.DovrebbeDareLaVittoriaPrimaDellaSconfitta;
var
  LCensus: TFakeCensus;
  LHolder: IWarCensus;
begin
  // the player has no unit left but the buildings are there: the original checks the win first
  LCensus := Census(wraHumans, 0, 3, 0);
  LHolder := LCensus;
  LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := 6;
  LCensus.Buildings[WAR_UNIT_BARRACKS_HUMANS] := 1;
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_01, LHolder) = wlrWin);
  Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(WAR_CAMPAIGN_HUMANS_02, LHolder) = wlrWin);
end;

procedure TTestWarCampaign.DovrebbeVincereLaMappaDueSenzaCombattentiNemici;
var
  LHolder: IWarCensus;
  LObjectives: IWarObjectives;
begin
  LObjectives := TWarLevelFactory.CreateObjectives;
  LHolder := Census(wraHumans, 5, 4, 0);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_HUMANS_02, LHolder) = wlrWin);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_ORCS_02, LHolder) = wlrWin);
  LHolder := Census(wraHumans, 5, 4, 1);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_HUMANS_02, LHolder) = wlrNone);
  LHolder := Census(wraHumans, 0, 4, 1);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_HUMANS_02, LHolder) = wlrLose);
end;

procedure TTestWarCampaign.DovrebbeVincereLaMappaPersonalizzataSenzaUnitaNemiche;
var
  LHolder: IWarCensus;
  LObjectives: IWarObjectives;
begin
  LObjectives := TWarLevelFactory.CreateObjectives;
  LHolder := Census(wraOrcs, 5, 0, 0);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_CUSTOM, LHolder) = wlrWin);
  // the buildings count in the custom map: the enemy has fighters 0 but units left
  LHolder := Census(wraOrcs, 5, 2, 0);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_CUSTOM, LHolder) = wlrNone);
  LHolder := Census(wraOrcs, 0, 2, 0);
  Assert.IsTrue(LObjectives.Check(WAR_CAMPAIGN_CUSTOM, LHolder) = wlrLose);
end;

procedure TTestWarCampaign.DovrebbeNonAvereCondizioniNelleAltreMappe;
var
  LHolder: IWarCensus;
  LMapType: Integer;
begin
  LHolder := Census(wraHumans, 0, 0, 0);
  for LMapType := WAR_CAMPAIGN_HUMANS_02 + 2 to WAR_CAMPAIGN_ORCS_12 do
    Assert.IsTrue(TWarLevelFactory.CreateObjectives.Check(LMapType, LHolder) = wlrNone, 'mappa ' + IntToStr(LMapType));
end;

procedure TTestWarCampaign.DovrebbeDareLaStessaTabellaDelCodiceOriginale;
var
  LGolden: TStringList;
  LCampaigns: IWarCampaigns;
  LLine: string;
  LExpected: TStringList;
  LMapType: Integer;
  LData: TWarCampaignMapData;
  LRace: Integer;
  LMission: Integer;
  LOk: Boolean;
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Invariant;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('campaigns.golden.txt'));
    LCampaigns := TWarLevelFactory.CreateCampaigns;
    LExpected.Add(Format('N unit goldmine=%d farmH=%d farmO=%d barrH=%d barrO=%d count=%d',
      [WAR_UNIT_GOLDMINE, WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_HUMANS,
       WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_COUNT]));
    for LMapType := WAR_CAMPAIGN_HUMANS_01 to WAR_CAMPAIGN_CUSTOM do
    begin
      LData := LCampaigns.GetData(LMapType);
      LExpected.Add(Format('K %d %s %d %s %s %d', [LData.MapType, Escaped(LData.Objectives), LData.BriefingAudioId,
        Escaped(LData.BriefingText), FloatToStr(LData.BriefingDuration, LFormat), Ord(LData.Rule <> worNone)]));
    end;
    for LRace := 0 to 3 do
      for LMission := 0 to 13 do
      begin
        LOk := LCampaigns.TryGetMapType(TWarRace(LRace), LMission, LMapType);
        LExpected.Add(Format('M %d %d %d %d', [LRace, LMission, Ord(LOk), LMapType]));
      end;
    // the last line of the golden ('M null') is the NULL pointer of the original: there is none here
    LExpected.Add(LGolden[LGolden.Count - 1]);
    Assert.AreEqual(LGolden.Count, LExpected.Count);
    for LLine in LGolden do
      Assert.IsTrue(LExpected.IndexOf(LLine) >= 0, LLine);
    Assert.AreEqual(LGolden.Text, LExpected.Text);
  finally
    LExpected.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarCampaign.DovrebbeDareLeStesseCondizioniDelCodiceOriginale;
const
  MAP_TYPES: array[0..4] of Integer = (117, 118, 119, 120, 141);
var
  LGolden: TStringList;
  LObjectives: IWarObjectives;
  LState: Cardinal;
  LKind: Integer;
  LScenario: Integer;
  LLine: string;
  LCensus: TFakeCensus;
  LHolder: IWarCensus;
  LPlayer: Integer;

  function Next: Cardinal;
  begin
    LState := LState * 1103515245 + 12345;
    Result := (LState shr 16) and $7FFF;
  end;

  function Range(AMax: Integer): Integer;
  begin
    Result := Integer(Next mod Cardinal(AMax));
  end;

begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('objectives.golden.txt'));
    Assert.AreEqual(5, LGolden.Count);
    LObjectives := TWarLevelFactory.CreateObjectives;
    for LKind := 0 to High(MAP_TYPES) do
    begin
      LState := 1000 + Cardinal(LKind);
      LLine := Format('O %d ', [MAP_TYPES[LKind]]);
      for LScenario := 0 to 399 do
      begin
        LCensus := TFakeCensus.Create;
        LHolder := LCensus;
        LCensus.Race := TWarRace(1 + Range(2));
        for LPlayer := 0 to 1 do
        begin
          if Range(4) = 0 then
            LCensus.Units[LPlayer] := 0
          else
            LCensus.Units[LPlayer] := Range(10);
          if Range(3) = 0 then
            LCensus.Dudes[LPlayer] := 0
          else
            LCensus.Dudes[LPlayer] := Range(6);
        end;
        LCensus.Buildings[WAR_UNIT_FARM_HUMANS] := Range(9);
        LCensus.Buildings[WAR_UNIT_FARM_ORCS] := Range(9);
        LCensus.Buildings[WAR_UNIT_BARRACKS_HUMANS] := Range(3);
        LCensus.Buildings[WAR_UNIT_BARRACKS_ORCS] := Range(3);
        LLine := LLine + Char(Ord('0') + Ord(LObjectives.Check(MAP_TYPES[LKind], LHolder)));
      end;
      Assert.AreEqual(LGolden[LKind], LLine, 'mappa ' + IntToStr(MAP_TYPES[LKind]));
    end;
  finally
    LGolden.Free;
  end;
end;

end.
