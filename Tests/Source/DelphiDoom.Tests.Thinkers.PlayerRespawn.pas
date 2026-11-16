{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the respawn of a player (G_DoReborn)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlayerRespawn;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Thinkers.PlayerRespawn.Intf, DelphiDoom.Thinkers.PlayerRespawn;

type
  /// <summary>
  ///   A level made of flags: which spots are free and which numbers the generator gives; every
  ///   action is written in a log, so the old code and the new class can be compared call by call
  /// </summary>
  TRespawnWorld = class
  public
    PlayerFree: array[0..7] of Boolean;
    DeathMatchFree: array[0..7] of Boolean;
    DeathMatchCount: Integer;
    Seed: Cardinal;
    Log: string;
    procedure Add(const AText: string);
    function Rand: Integer;
    function Check(const APlayer: Integer; const AKind: TPlayerSpotKind;
      const AIndex: Integer): Boolean;
  end;

  /// <summary>The new class talks to the world through this host; the profile tells which extra array a start uses</summary>
  TRespawnHost = class(TInterfacedObject, IPlayerRespawnHost)
  strict private
    FWorld: TRespawnWorld;
    FStrife: Boolean;
  public
    constructor Create(const AWorld: TRespawnWorld; const AStrife: Boolean);
    procedure ReloadLevel;
    procedure DetachCorpse(const APlayer: Integer);
    function CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
      const AIndex: Integer): Boolean;
    procedure Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
    procedure SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
    function DeathMatchSpotCount: Integer;
    function NextRandom: Integer;
    procedure TooFewDeathMatchSpots(const ACount: Integer);
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlayerRespawn = class
  strict private
    procedure OldDeathMatch(const AWorld: TRespawnWorld; const APlayer: Integer;
      const AStrife: Boolean);
    procedure OldReborn(const AWorld: TRespawnWorld; const APlayer: Integer;
      const ANetGame: Boolean; const ADeathMatch: Integer; const AStrife: Boolean);
    procedure Prepare(const AWorld: TRespawnWorld; const AMaskPlayers, AMaskDeath,
      ACount: Integer; const ASeed: Cardinal);
  public
    [Test]
    procedure DovrebbeCaricareDiNuovoIlLivelloSenzaRete;
    [Test]
    procedure DovrebbeNonFareNullaSeIPostiDeathmatchSonoPochi;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
    [Test]
    procedure DovrebbeRifiutareUnHostNil;
  end;

implementation

{ TRespawnWorld }

procedure TRespawnWorld.Add(const AText: string);
begin
  Log := Log + AText + ';';
end;

function TRespawnWorld.Rand: Integer;
begin
  Seed := Seed * 1664525 + 1013904223;
  Result := (Seed shr 16) and 255;
  Add('rnd' + IntToStr(Result));
end;

function TRespawnWorld.Check(const APlayer: Integer; const AKind: TPlayerSpotKind;
  const AIndex: Integer): Boolean;
begin
  if AKind = pskPlayerStart then
    Result := PlayerFree[AIndex]
  else
    Result := DeathMatchFree[AIndex];
  Add('chk' + IntToStr(APlayer) + 'k' + IntToStr(Ord(AKind)) + 'i' + IntToStr(AIndex));
end;

{ TRespawnHost }

constructor TRespawnHost.Create(const AWorld: TRespawnWorld; const AStrife: Boolean);
begin
  inherited Create;
  FWorld := AWorld;
  FStrife := AStrife;
end;

procedure TRespawnHost.ReloadLevel;
begin
  FWorld.Add('reload');
end;

procedure TRespawnHost.DetachCorpse(const APlayer: Integer);
begin
  FWorld.Add('detach' + IntToStr(APlayer));
end;

function TRespawnHost.CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
  const AIndex: Integer): Boolean;
begin
  Result := FWorld.Check(APlayer, AKind, AIndex);
end;

procedure TRespawnHost.Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
var
  LExtra: string;
begin
  // Doom and Heretic pass the extra data of the deathmatch starts also with the player starts
  if (AKind = pskPlayerStart) and FStrife then
    LExtra := 'uplayer'
  else
    LExtra := 'udeath';
  FWorld.Add('spawn' + IntToStr(Ord(AKind)) + 'i' + IntToStr(AIndex) + LExtra + IntToStr(AIndex));
end;

procedure TRespawnHost.SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
begin
  FWorld.Add('type' + IntToStr(Ord(AKind)) + 'i' + IntToStr(AIndex) + '=' + IntToStr(AType));
end;

function TRespawnHost.DeathMatchSpotCount: Integer;
begin
  Result := FWorld.DeathMatchCount;
end;

function TRespawnHost.NextRandom: Integer;
begin
  Result := FWorld.Rand;
end;

procedure TRespawnHost.TooFewDeathMatchSpots(const ACount: Integer);
begin
  FWorld.Add('few' + IntToStr(ACount));
end;

{ TTestThinkersPlayerRespawn }

procedure TTestThinkersPlayerRespawn.OldDeathMatch(const AWorld: TRespawnWorld;
  const APlayer: Integer; const AStrife: Boolean);
var
  i, j: Integer;
  selections: Integer;
  extra: string;
begin
  // G_DeathMatchSpawnPlayer of g_game, copied (the globals are the world)
  selections := AWorld.DeathMatchCount;
  if selections < 4 then
  begin
    AWorld.Add('few' + IntToStr(selections));
    Exit;
  end;

  for j := 0 to 19 do
  begin
    i := AWorld.Rand mod selections;
    if AWorld.Check(APlayer, pskDeathMatchStart, i) then
    begin
      AWorld.Add('type1i' + IntToStr(i) + '=' + IntToStr(APlayer + 1));
      AWorld.Add('spawn1i' + IntToStr(i) + 'udeath' + IntToStr(i));
      Exit;
    end;
  end;

  if AStrife then
    extra := 'uplayer'
  else
    extra := 'udeath';
  AWorld.Add('spawn0i' + IntToStr(APlayer) + extra + IntToStr(APlayer));
end;

procedure TTestThinkersPlayerRespawn.OldReborn(const AWorld: TRespawnWorld;
  const APlayer: Integer; const ANetGame: Boolean; const ADeathMatch: Integer;
  const AStrife: Boolean);
var
  i: Integer;
  extra: string;
begin
  // G_DoReborn of g_game, copied
  if AStrife then
    extra := 'uplayer'
  else
    extra := 'udeath';

  if not ANetGame then
    AWorld.Add('reload')
  else
  begin
    AWorld.Add('detach' + IntToStr(APlayer));

    if ADeathMatch <> 0 then
    begin
      OldDeathMatch(AWorld, APlayer, AStrife);
      Exit;
    end;

    if AWorld.Check(APlayer, pskPlayerStart, APlayer) then
    begin
      AWorld.Add('spawn0i' + IntToStr(APlayer) + extra + IntToStr(APlayer));
      Exit;
    end;

    for i := 0 to 3 do
    begin
      if AWorld.Check(APlayer, pskPlayerStart, i) then
      begin
        AWorld.Add('type0i' + IntToStr(i) + '=' + IntToStr(APlayer + 1));
        AWorld.Add('spawn0i' + IntToStr(i) + extra + IntToStr(i));
        AWorld.Add('type0i' + IntToStr(i) + '=' + IntToStr(i + 1));
        Exit;
      end;
    end;
    AWorld.Add('spawn0i' + IntToStr(APlayer) + extra + IntToStr(APlayer));
  end;
end;

procedure TTestThinkersPlayerRespawn.Prepare(const AWorld: TRespawnWorld; const AMaskPlayers,
  AMaskDeath, ACount: Integer; const ASeed: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    AWorld.PlayerFree[LIndex] := (AMaskPlayers shr LIndex) and 1 <> 0;
    AWorld.DeathMatchFree[LIndex] := (AMaskDeath shr LIndex) and 1 <> 0;
  end;
  AWorld.DeathMatchCount := ACount;
  AWorld.Seed := ASeed;
  AWorld.Log := '';
end;

procedure TTestThinkersPlayerRespawn.DovrebbeCaricareDiNuovoIlLivelloSenzaRete;
var
  LWorld: TRespawnWorld;
  LRespawn: TPlayerRespawn;
begin
  LWorld := TRespawnWorld.Create;
  try
    LRespawn := TPlayerRespawn.Create(TRespawnHost.Create(LWorld, False));
    try
      LRespawn.Respawn(1, False, 0, 4);
    finally
      LRespawn.Free;
    end;
    Assert.AreEqual('reload;', LWorld.Log);
  finally
    LWorld.Free;
  end;
end;

procedure TTestThinkersPlayerRespawn.DovrebbeNonFareNullaSeIPostiDeathmatchSonoPochi;
var
  LWorld: TRespawnWorld;
  LRespawn: TPlayerRespawn;
begin
  LWorld := TRespawnWorld.Create;
  try
    LWorld.DeathMatchCount := 3;
    LRespawn := TPlayerRespawn.Create(TRespawnHost.Create(LWorld, False));
    try
      LRespawn.SpawnDeathMatch(0);
    finally
      LRespawn.Free;
    end;
    Assert.AreEqual('few3;', LWorld.Log);
  finally
    LWorld.Free;
  end;
end;

procedure TTestThinkersPlayerRespawn.DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
var
  LOld, LNew: TRespawnWorld;
  LRespawn: TPlayerRespawn;
  LStrife: Boolean;
  LPlayer, LCount, LMaskPlayers, LMaskDeath, LSeed, LDeathMatch: Integer;
  LNetGame: Boolean;
  LCompared: Integer;
begin
  LOld := TRespawnWorld.Create;
  LNew := TRespawnWorld.Create;
  LCompared := 0;
  try
    for LStrife := False to True do
      for LNetGame := False to True do
        for LDeathMatch := 0 to 1 do
          for LPlayer := 0 to 3 do
            for LCount := 0 to 8 do
              for LMaskPlayers := 0 to 15 do
                for LMaskDeath := 0 to (1 shl LCount) - 1 do
                  for LSeed := 1 to 2 do
                  begin
                    Prepare(LOld, LMaskPlayers, LMaskDeath, LCount, LSeed * 7919);
                    Prepare(LNew, LMaskPlayers, LMaskDeath, LCount, LSeed * 7919);
                    OldReborn(LOld, LPlayer, LNetGame, LDeathMatch, LStrife);
                    LRespawn := TPlayerRespawn.Create(TRespawnHost.Create(LNew, LStrife));
                    try
                      LRespawn.Respawn(LPlayer, LNetGame, LDeathMatch, 4);
                    finally
                      LRespawn.Free;
                    end;
                    if LOld.Log <> LNew.Log then
                      Assert.AreEqual(LOld.Log, LNew.Log, Format('strife %d net %d dm %d player %d count %d mp %d md %d',
                        [Ord(LStrife), Ord(LNetGame), LDeathMatch, LPlayer, LCount, LMaskPlayers, LMaskDeath]));
                    Inc(LCompared);
                  end;
    Assert.IsTrue(LCompared > 10000);
  finally
    LOld.Free;
    LNew.Free;
  end;
end;

procedure TTestThinkersPlayerRespawn.DovrebbeRifiutareUnHostNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TPlayerRespawn.Create(nil).Free;
    end, EArgumentNilException);
end;

end.
