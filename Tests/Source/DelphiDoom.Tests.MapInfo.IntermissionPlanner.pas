{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the plan of the intermission (G_DoCompleted)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.IntermissionPlanner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapInfo.LevelExit,
  DelphiDoom.MapInfo.LevelProgression, DelphiDoom.MapInfo.MapName,
  DelphiDoom.MapInfo.IntermissionPlanner;

type
  /// <summary>The part of wminfo that G_DoCompleted decides (a fake of the record of the game)</summary>
  TFakeWminfo = record
    DidSecret: Boolean;
    Epsd, NextEp, Last, Next, Partime: Integer;
  end;

  /// <summary>One scenario: what the engine knows when a level ends</summary>
  TScenario = record
    Game: TLevelExitGame;
    Commercial: Boolean;
    Custom: TLevelExitCustom;
    Bfg2: Boolean;
    SecretExit: Boolean;
    Episode, Map: Integer;
    ConsoleDidSecret: Boolean;
    OtherDidSecret: Boolean;
    PreviousNext: Integer;
    HasMapInfo: Boolean;
    EndPic: Boolean;
    NoIntermission: Boolean;
    NextSecret, NextMap: string;
    Partime: Integer;
  end;

  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoIntermissionPlanner = class
  strict private
    const
      FakePlayers = 4;
      FakeConsole = 1;
      Untouched = -777;
    type
      TFakePlayers = array[0..FakePlayers - 1] of Boolean;
    function FakeTablePartime(const AScenario: TScenario): Integer;
    procedure OldDoCompleted(const AScenario: TScenario; var APlayers: TFakePlayers;
      var AWminfo: TFakeWminfo; out AVictory: Boolean);
    procedure NewDoCompleted(const AScenario: TScenario; var APlayers: TFakePlayers;
      var AWminfo: TFakeWminfo; out AVictory: Boolean);
    function Rules(const AGame: TLevelExitGame): TMapNameRules;
    procedure CompareScenario(const AScenario: TScenario);
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSenzaVoceUmapinfo;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceConUnaVoceUmapinfo;
    [Test]
    procedure DovrebbeTerminareLaPartitaConUnaVoceSenzaIntermissione;
    [Test]
    procedure DovrebbeAzzerareIlSegretoQuandoCambiaEpisodio;
    [Test]
    procedure DovrebbeConservareIlProssimoNumeroSeLeRegoleNonDiconoNulla;
  end;

implementation

{ TTestMapInfoIntermissionPlanner }

function TTestMapInfoIntermissionPlanner.Rules(const AGame: TLevelExitGame): TMapNameRules;
begin
  if AGame = legDoom then
    Result := TMapName.DoomRules
  else
    Result := TMapName.HereticRules;
end;

function TTestMapInfoIntermissionPlanner.FakeTablePartime(const AScenario: TScenario): Integer;
begin
  // stands for TICRATE * pars[...] / cpars[...], that stay with the game
  Result := 35 * (AScenario.Episode * 100 + AScenario.Map);
  if AScenario.Commercial then
    Result := Result + 1;
end;

procedure TTestMapInfoIntermissionPlanner.OldDoCompleted(const AScenario: TScenario;
  var APlayers: TFakePlayers; var AWminfo: TFakeWminfo; out AVictory: Boolean);
var
  i: Integer;
  next: string;
  epi, mapnum: Integer;
  exitverdict: TLevelExitVerdict;
label
  frommapinfo;
begin
  // G_DoCompleted of Doom and Heretic, copied: gameaction := ga_victory is AVictory, the record
  // is the fake, wminfo.nextep and wminfo.next are written by G_ValidateMapName as it did
  AVictory := False;

  exitverdict := TLevelExit.Check(AScenario.Game, AScenario.Commercial, AScenario.Custom,
    AScenario.Map);
  if exitverdict.SecretForAll then
    for i := 0 to FakePlayers - 1 do
      APlayers[i] := True;
  if exitverdict.Victory then
  begin
    AVictory := True;
    exit;
  end;

  AWminfo.DidSecret := APlayers[FakeConsole];
  AWminfo.Epsd := AScenario.Episode - 1;
  AWminfo.NextEp := AScenario.Episode - 1;
  AWminfo.Last := AScenario.Map - 1;

  if AScenario.HasMapInfo then
  begin
    if AScenario.EndPic and AScenario.NoIntermission then
    begin
      AVictory := True;
      exit;
    end;
    next := TLevelExit.PickNextMapName(AScenario.SecretExit, AScenario.NextSecret,
      AScenario.NextMap);
    if next <> '' then
      if TMapName.TryParse(next, Rules(AScenario.Game), epi, mapnum) then
      begin
        AWminfo.NextEp := epi;
        AWminfo.Next := mapnum;
        Dec(AWminfo.NextEp);
        Dec(AWminfo.Next);
        // episode change
        if AWminfo.NextEp <> AWminfo.Epsd then
          for i := 0 to FakePlayers - 1 do
            APlayers[i] := False;
        AWminfo.DidSecret := APlayers[FakeConsole];
        AWminfo.Partime := AScenario.Partime;
        goto frommapinfo; // skip past the default setup.
      end;
  end;

  if AScenario.Game = legDoom then
    TLevelProgression.DoomNextMap(AScenario.Commercial, AScenario.SecretExit, AScenario.Bfg2,
      AScenario.Episode, AScenario.Map, AWminfo.Next)
  else
    TLevelProgression.HereticNextMap(AScenario.SecretExit, AScenario.Episode, AScenario.Map,
      AWminfo.Next);

  AWminfo.Partime := FakeTablePartime(AScenario);

frommapinfo:
end;

procedure TTestMapInfoIntermissionPlanner.NewDoCompleted(const AScenario: TScenario;
  var APlayers: TFakePlayers; var AWminfo: TFakeWminfo; out AVictory: Boolean);
var
  i: Integer;
  LRequest: TIntermissionRequest;
  LPlan: TIntermissionPlan;
begin
  // the facade of g_game: the request from the globals, the plan applied to the records
  AVictory := False;

  LRequest.Game := AScenario.Game;
  LRequest.IsCommercial := AScenario.Commercial;
  LRequest.Custom := AScenario.Custom;
  LRequest.IsBfgSecondEdition := AScenario.Bfg2;
  LRequest.SecretExit := AScenario.SecretExit;
  LRequest.Episode := AScenario.Episode;
  LRequest.Map := AScenario.Map;
  LRequest.ConsoleDidSecret := APlayers[FakeConsole];
  LRequest.PreviousNext := AWminfo.Next;
  LRequest.HasMapInfo := AScenario.HasMapInfo;
  LRequest.HasEndPicture := AScenario.EndPic;
  LRequest.NoIntermission := AScenario.NoIntermission;
  LRequest.NextSecret := AScenario.NextSecret;
  LRequest.NextMap := AScenario.NextMap;
  LRequest.MapInfoPartime := AScenario.Partime;
  LRequest.Rules := Rules(AScenario.Game);
  LPlan := TIntermissionPlanner.Plan(LRequest);

  if LPlan.SecretForAll then
    for i := 0 to FakePlayers - 1 do
      APlayers[i] := True;
  if LPlan.EndsGame then
  begin
    AVictory := True;
    exit;
  end;

  AWminfo.DidSecret := LPlan.DidSecret;
  AWminfo.Epsd := LPlan.Epsd;
  AWminfo.NextEp := LPlan.NextEp;
  AWminfo.Last := LPlan.Last;
  AWminfo.Next := LPlan.Next;
  if LPlan.EndsWithoutIntermission then
  begin
    AVictory := True;
    exit;
  end;
  if LPlan.ResetPlayersDidSecret then
    for i := 0 to FakePlayers - 1 do
      APlayers[i] := False;
  if LPlan.PartimeFromMapInfo then
    AWminfo.Partime := LPlan.Partime
  else
    AWminfo.Partime := FakeTablePartime(AScenario);
end;

procedure TTestMapInfoIntermissionPlanner.CompareScenario(const AScenario: TScenario);
var
  LOldPlayers, LNewPlayers: TFakePlayers;
  LOldWminfo, LNewWminfo: TFakeWminfo;
  LOldVictory, LNewVictory: Boolean;
  LIndex: Integer;
  LWhere: string;
begin
  for LIndex := 0 to FakePlayers - 1 do
  begin
    LOldPlayers[LIndex] := (LIndex = FakeConsole) and AScenario.ConsoleDidSecret;
    if LIndex <> FakeConsole then
      LOldPlayers[LIndex] := AScenario.OtherDidSecret;
  end;
  LNewPlayers := LOldPlayers;
  LOldWminfo.DidSecret := False;
  LOldWminfo.Epsd := Untouched;
  LOldWminfo.NextEp := Untouched;
  LOldWminfo.Last := Untouched;
  LOldWminfo.Next := AScenario.PreviousNext;
  LOldWminfo.Partime := Untouched;
  LNewWminfo := LOldWminfo;

  OldDoCompleted(AScenario, LOldPlayers, LOldWminfo, LOldVictory);
  NewDoCompleted(AScenario, LNewPlayers, LNewWminfo, LNewVictory);

  LWhere := Format('game %d commercial %d custom %d secret %d ep %d map %d mapinfo %d next "%s" secretname "%s"',
    [Ord(AScenario.Game), Ord(AScenario.Commercial), Ord(AScenario.Custom),
     Ord(AScenario.SecretExit), AScenario.Episode, AScenario.Map, Ord(AScenario.HasMapInfo),
     AScenario.NextMap, AScenario.NextSecret]);
  Assert.AreEqual(LOldVictory, LNewVictory, 'victory ' + LWhere);
  Assert.AreEqual(LOldWminfo.DidSecret, LNewWminfo.DidSecret, 'didsecret ' + LWhere);
  Assert.AreEqual(LOldWminfo.Epsd, LNewWminfo.Epsd, 'epsd ' + LWhere);
  Assert.AreEqual(LOldWminfo.NextEp, LNewWminfo.NextEp, 'nextep ' + LWhere);
  Assert.AreEqual(LOldWminfo.Last, LNewWminfo.Last, 'last ' + LWhere);
  Assert.AreEqual(LOldWminfo.Next, LNewWminfo.Next, 'next ' + LWhere);
  Assert.AreEqual(LOldWminfo.Partime, LNewWminfo.Partime, 'partime ' + LWhere);
  for LIndex := 0 to FakePlayers - 1 do
    Assert.AreEqual(LOldPlayers[LIndex], LNewPlayers[LIndex],
      Format('player %d didsecret %s', [LIndex, LWhere]));
end;

procedure TTestMapInfoIntermissionPlanner.DovrebbeEssereUgualeAlVecchioCodiceSenzaVoceUmapinfo;
var
  LScenario: TScenario;
  LGame: TLevelExitGame;
  LCommercial, LBfg2, LSecret, LConsole, LOther: Boolean;
  LCustom: TLevelExitCustom;
  LEpisode, LMap, LPrevious: Integer;
begin
  FillChar(LScenario, SizeOf(LScenario), 0);
  for LGame := Low(TLevelExitGame) to High(TLevelExitGame) do
    for LCommercial := False to True do
      for LCustom := Low(TLevelExitCustom) to High(TLevelExitCustom) do
        for LBfg2 := False to True do
          for LSecret := False to True do
            for LConsole := False to True do
              for LOther := False to True do
                for LEpisode := 0 to 5 do
                  for LMap := 0 to 40 do
                    for LPrevious := 0 to 1 do
                    begin
                      LScenario.Game := LGame;
                      LScenario.Commercial := LCommercial;
                      LScenario.Custom := LCustom;
                      LScenario.Bfg2 := LBfg2;
                      LScenario.SecretExit := LSecret;
                      LScenario.ConsoleDidSecret := LConsole;
                      LScenario.OtherDidSecret := LOther;
                      LScenario.Episode := LEpisode;
                      LScenario.Map := LMap;
                      LScenario.PreviousNext := LPrevious * 5;
                      CompareScenario(LScenario);
                    end;
end;

procedure TTestMapInfoIntermissionPlanner.DovrebbeEssereUgualeAlVecchioCodiceConUnaVoceUmapinfo;
const
  Names: array[0..8] of string = ('', 'MAP07', 'E2M3', 'E1M1', 'XXXX', 'MAP31', 'E1M9', 'E3M0', 'map02');
var
  LScenario: TScenario;
  LGame: TLevelExitGame;
  LSecret, LConsole, LOther, LEndPic, LNoIntermission: Boolean;
  LEpisode, LMap, LNextName, LSecretName: Integer;
begin
  FillChar(LScenario, SizeOf(LScenario), 0);
  LScenario.HasMapInfo := True;
  LScenario.Partime := 77 * 35;
  LScenario.PreviousNext := 3;
  for LGame := Low(TLevelExitGame) to High(TLevelExitGame) do
    for LSecret := False to True do
      for LConsole := False to True do
        for LOther := False to True do
          for LEndPic := False to True do
            for LNoIntermission := False to True do
              for LEpisode := 1 to 3 do
                for LMap := 1 to 12 do
                  for LNextName := 0 to High(Names) do
                    for LSecretName := 0 to High(Names) do
                    begin
                      LScenario.Game := LGame;
                      LScenario.Commercial := LGame = legDoom;
                      LScenario.SecretExit := LSecret;
                      LScenario.ConsoleDidSecret := LConsole;
                      LScenario.OtherDidSecret := LOther;
                      LScenario.EndPic := LEndPic;
                      LScenario.NoIntermission := LNoIntermission;
                      LScenario.Episode := LEpisode;
                      LScenario.Map := LMap;
                      LScenario.NextMap := Names[LNextName];
                      LScenario.NextSecret := Names[LSecretName];
                      CompareScenario(LScenario);
                    end;
end;

procedure TTestMapInfoIntermissionPlanner.DovrebbeTerminareLaPartitaConUnaVoceSenzaIntermissione;
var
  LRequest: TIntermissionRequest;
  LPlan: TIntermissionPlan;
begin
  FillChar(LRequest, SizeOf(LRequest), 0);
  LRequest.Game := legDoom;
  LRequest.IsCommercial := True;
  LRequest.Episode := 1;
  LRequest.Map := 6;
  LRequest.PreviousNext := 9;
  LRequest.HasMapInfo := True;
  LRequest.HasEndPicture := True;
  LRequest.NoIntermission := True;
  LRequest.NextMap := 'MAP07';
  LRequest.Rules := TMapName.DoomRules;

  LPlan := TIntermissionPlanner.Plan(LRequest);

  Assert.IsFalse(LPlan.EndsGame);
  Assert.IsTrue(LPlan.EndsWithoutIntermission);
  Assert.AreEqual(0, LPlan.Epsd);
  Assert.AreEqual(5, LPlan.Last);
  Assert.AreEqual(9, LPlan.Next, 'the next map is not decided');
end;

procedure TTestMapInfoIntermissionPlanner.DovrebbeAzzerareIlSegretoQuandoCambiaEpisodio;
var
  LRequest: TIntermissionRequest;
  LPlan: TIntermissionPlan;
begin
  FillChar(LRequest, SizeOf(LRequest), 0);
  LRequest.Game := legHeretic;
  LRequest.Episode := 1;
  LRequest.Map := 4;
  LRequest.ConsoleDidSecret := True;
  LRequest.HasMapInfo := True;
  LRequest.NextMap := 'E2M1';
  LRequest.MapInfoPartime := 1050;
  LRequest.Rules := TMapName.HereticRules;

  LPlan := TIntermissionPlanner.Plan(LRequest);

  Assert.IsTrue(LPlan.ResetPlayersDidSecret);
  Assert.IsFalse(LPlan.DidSecret);
  Assert.AreEqual(1, LPlan.NextEp);
  Assert.AreEqual(0, LPlan.Next);
  Assert.IsTrue(LPlan.PartimeFromMapInfo);
  Assert.AreEqual(1050, LPlan.Partime);

  LRequest.NextMap := 'E1M5';
  LPlan := TIntermissionPlanner.Plan(LRequest);
  Assert.IsFalse(LPlan.ResetPlayersDidSecret);
  Assert.IsTrue(LPlan.DidSecret);
end;

procedure TTestMapInfoIntermissionPlanner.DovrebbeConservareIlProssimoNumeroSeLeRegoleNonDiconoNulla;
var
  LRequest: TIntermissionRequest;
  LPlan: TIntermissionPlan;
begin
  FillChar(LRequest, SizeOf(LRequest), 0);
  LRequest.Game := legDoom;
  LRequest.IsCommercial := True;
  LRequest.SecretExit := True;
  LRequest.Episode := 1;
  LRequest.Map := 20;
  LRequest.PreviousNext := 11;
  LRequest.Rules := TMapName.DoomRules;

  // an exit that is secret from a map that has no secret exit: the old code did not write next
  LPlan := TIntermissionPlanner.Plan(LRequest);

  Assert.AreEqual(11, LPlan.Next);
  Assert.IsFalse(LPlan.PartimeFromMapInfo);
end;

end.
