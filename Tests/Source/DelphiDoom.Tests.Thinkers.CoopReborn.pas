{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the reborn of a player of Hexen (G_DoReborn)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.CoopReborn;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Thinkers.CoopReborn.Intf, DelphiDoom.Thinkers.CoopReborn;

type
  /// <summary>A level made of flags; every action is written in a log, so the old code and the new class can be compared call by call</summary>
  TCoopRebornWorld = class
  public
    SlotAvailable: Boolean;
    SpotFree: array[0..7] of Boolean;
    WeaponOwned: array[0..7] of Boolean;
    Keys: Integer;
    Pieces: Integer;
    Log: string;
    procedure Add(const AText: string);
    function Check(const APlayer, AIndex: Integer): Boolean;
  end;

  TCoopRebornFakeHost = class(TInterfacedObject, ICoopRebornHost)
  strict private
    FWorld: TCoopRebornWorld;
  public
    constructor Create(const AWorld: TCoopRebornWorld);
    function RebornSlotAvailable: Boolean;
    procedure RequestGameAction(const ALoadHubPosition: Boolean);
    procedure DetachCorpse(const APlayer: Integer);
    procedure SpawnDeathMatch(const APlayer: Integer);
    function CheckSpot(const APlayer, AIndex: Integer): Boolean;
    procedure Spawn(const AIndex: Integer);
    procedure SetSpotType(const AIndex, AType: Integer);
    function Keys(const APlayer: Integer): Integer;
    procedure SetKeys(const APlayer, AKeys: Integer);
    function Pieces(const APlayer: Integer): Integer;
    procedure SetPieces(const APlayer, APieces: Integer);
    function WeaponCount: Integer;
    function WeaponOwned(const APlayer, AWeapon: Integer): Boolean;
    procedure GiveWeapon(const APlayer, AWeapon: Integer);
    procedure SetMana(const APlayer, AAmount: Integer);
    procedure SetPendingWeapon(const APlayer, AWeapon: Integer);
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersCoopReborn = class
  strict private
    procedure OldReborn(const AWorld: TCoopRebornWorld; const APlayer: Integer;
      const ANetGame: Boolean; const ADeathMatch: Integer);
    procedure Prepare(const AWorld: TCoopRebornWorld; const AMaskSpots, AMaskWeapons: Integer;
      const ASlot: Boolean);
  public
    [Test]
    procedure DovrebbeChiedereLaPosizioneDelHubSenzaRete;
    [Test]
    procedure DovrebbeCominciareUnaPartitaNuovaSenzaPosizioneDelHub;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
    [Test]
    procedure DovrebbeRifiutareUnHostNil;
  end;

implementation

{ TCoopRebornWorld }

procedure TCoopRebornWorld.Add(const AText: string);
begin
  Log := Log + AText + ';';
end;

function TCoopRebornWorld.Check(const APlayer, AIndex: Integer): Boolean;
begin
  Result := SpotFree[AIndex];
  Add('chk' + IntToStr(APlayer) + 'i' + IntToStr(AIndex));
end;

{ TCoopRebornFakeHost }

constructor TCoopRebornFakeHost.Create(const AWorld: TCoopRebornWorld);
begin
  inherited Create;
  FWorld := AWorld;
end;

function TCoopRebornFakeHost.RebornSlotAvailable: Boolean;
begin
  Result := FWorld.SlotAvailable;
end;

procedure TCoopRebornFakeHost.RequestGameAction(const ALoadHubPosition: Boolean);
begin
  if ALoadHubPosition then
    FWorld.Add('singlereborn')
  else
    FWorld.Add('newgame');
end;

procedure TCoopRebornFakeHost.DetachCorpse(const APlayer: Integer);
begin
  FWorld.Add('detach' + IntToStr(APlayer));
end;

procedure TCoopRebornFakeHost.SpawnDeathMatch(const APlayer: Integer);
begin
  FWorld.Add('deathmatch' + IntToStr(APlayer));
end;

function TCoopRebornFakeHost.CheckSpot(const APlayer, AIndex: Integer): Boolean;
begin
  Result := FWorld.Check(APlayer, AIndex);
end;

procedure TCoopRebornFakeHost.Spawn(const AIndex: Integer);
begin
  FWorld.Add('spawn' + IntToStr(AIndex));
end;

procedure TCoopRebornFakeHost.SetSpotType(const AIndex, AType: Integer);
begin
  FWorld.Add('type' + IntToStr(AIndex) + '=' + IntToStr(AType));
end;

function TCoopRebornFakeHost.Keys(const APlayer: Integer): Integer;
begin
  Result := FWorld.Keys;
end;

procedure TCoopRebornFakeHost.SetKeys(const APlayer, AKeys: Integer);
begin
  FWorld.Add('keys' + IntToStr(AKeys));
end;

function TCoopRebornFakeHost.Pieces(const APlayer: Integer): Integer;
begin
  Result := FWorld.Pieces;
end;

procedure TCoopRebornFakeHost.SetPieces(const APlayer, APieces: Integer);
begin
  FWorld.Add('pieces' + IntToStr(APieces));
end;

function TCoopRebornFakeHost.WeaponCount: Integer;
begin
  Result := 4;
end;

function TCoopRebornFakeHost.WeaponOwned(const APlayer, AWeapon: Integer): Boolean;
begin
  Result := FWorld.WeaponOwned[AWeapon];
end;

procedure TCoopRebornFakeHost.GiveWeapon(const APlayer, AWeapon: Integer);
begin
  FWorld.Add('give' + IntToStr(AWeapon));
end;

procedure TCoopRebornFakeHost.SetMana(const APlayer, AAmount: Integer);
begin
  FWorld.Add('mana' + IntToStr(AAmount));
end;

procedure TCoopRebornFakeHost.SetPendingWeapon(const APlayer, AWeapon: Integer);
begin
  FWorld.Add('pending' + IntToStr(AWeapon));
end;

{ TTestThinkersCoopReborn }

procedure TTestThinkersCoopReborn.OldReborn(const AWorld: TCoopRebornWorld;
  const APlayer: Integer; const ANetGame: Boolean; const ADeathMatch: Integer);
var
  i: Integer;
  oldWeaponowned: array[0..3] of Boolean;
  oldKeys: Integer;
  oldPieces: Integer;
  foundSpot: Boolean;
  bestWeapon: Integer;
begin
  // G_DoReborn of Hexen (g_game), copied; the globals are the world
  if not ANetGame then
  begin
    if AWorld.SlotAvailable then
      AWorld.Add('singlereborn')
    else
      AWorld.Add('newgame');
  end
  else
  begin
    AWorld.Add('detach' + IntToStr(APlayer));

    if ADeathMatch <> 0 then
    begin
      AWorld.Add('deathmatch' + IntToStr(APlayer));
      Exit;
    end;

    oldKeys := AWorld.Keys;
    oldPieces := AWorld.Pieces;
    for i := 0 to 3 do
      oldWeaponowned[i] := AWorld.WeaponOwned[i];

    foundSpot := False;
    if AWorld.Check(APlayer, APlayer) then
    begin
      AWorld.Add('spawn' + IntToStr(APlayer));
      foundSpot := True;
    end
    else
    begin
      for i := 0 to 7 do
      begin
        if AWorld.Check(APlayer, i) then
        begin
          AWorld.Add('type' + IntToStr(i) + '=' + IntToStr(APlayer + 1));
          AWorld.Add('spawn' + IntToStr(i));
          AWorld.Add('type' + IntToStr(i) + '=' + IntToStr(i + 1));
          foundSpot := True;
          Break;
        end;
      end;
    end;

    if not foundSpot then
      AWorld.Add('spawn' + IntToStr(APlayer));

    AWorld.Add('keys' + IntToStr(oldKeys));
    AWorld.Add('pieces' + IntToStr(oldPieces));
    bestWeapon := 0;
    for i := 0 to 3 do
    begin
      if oldWeaponowned[i] then
      begin
        bestWeapon := i;
        AWorld.Add('give' + IntToStr(i));
      end;
    end;
    AWorld.Add('mana25');
    if bestWeapon <> 0 then
      AWorld.Add('pending' + IntToStr(bestWeapon));
  end;
end;

procedure TTestThinkersCoopReborn.Prepare(const AWorld: TCoopRebornWorld; const AMaskSpots,
  AMaskWeapons: Integer; const ASlot: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    AWorld.SpotFree[LIndex] := (AMaskSpots shr LIndex) and 1 <> 0;
    AWorld.WeaponOwned[LIndex] := (AMaskWeapons shr LIndex) and 1 <> 0;
  end;
  AWorld.SlotAvailable := ASlot;
  AWorld.Keys := AMaskSpots * 7 + 3;
  AWorld.Pieces := AMaskWeapons + 1;
  AWorld.Log := '';
end;

procedure TTestThinkersCoopReborn.DovrebbeChiedereLaPosizioneDelHubSenzaRete;
var
  LWorld: TCoopRebornWorld;
  LReborn: TCoopReborn;
begin
  LWorld := TCoopRebornWorld.Create;
  try
    Prepare(LWorld, 0, 0, True);
    LReborn := TCoopReborn.Create(TCoopRebornFakeHost.Create(LWorld));
    try
      LReborn.Respawn(1, False, 0, 8);
    finally
      LReborn.Free;
    end;
    Assert.AreEqual('singlereborn;', LWorld.Log);
  finally
    LWorld.Free;
  end;
end;

procedure TTestThinkersCoopReborn.DovrebbeCominciareUnaPartitaNuovaSenzaPosizioneDelHub;
var
  LWorld: TCoopRebornWorld;
  LReborn: TCoopReborn;
begin
  LWorld := TCoopRebornWorld.Create;
  try
    Prepare(LWorld, 0, 0, False);
    LReborn := TCoopReborn.Create(TCoopRebornFakeHost.Create(LWorld));
    try
      LReborn.Respawn(1, False, 0, 8);
    finally
      LReborn.Free;
    end;
    Assert.AreEqual('newgame;', LWorld.Log);
  finally
    LWorld.Free;
  end;
end;

procedure TTestThinkersCoopReborn.DovrebbeEssereUgualeAlVecchioCodiceInOgniCombinazione;
var
  LOld, LNew: TCoopRebornWorld;
  LReborn: TCoopReborn;
  LSpots, LWeapons, LPlayer, LDeath: Integer;
  LNet: Boolean;
  LCount: Integer;
begin
  LCount := 0;
  LOld := TCoopRebornWorld.Create;
  LNew := TCoopRebornWorld.Create;
  try
    LReborn := TCoopReborn.Create(TCoopRebornFakeHost.Create(LNew));
    try
      for LSpots := 0 to 255 do
        for LWeapons := 0 to 15 do
          for LPlayer := 0 to 7 do
            for LDeath := 0 to 1 do
              for LNet := False to True do
              begin
                Prepare(LOld, LSpots, LWeapons, (LSpots and 1) = 0);
                Prepare(LNew, LSpots, LWeapons, (LSpots and 1) = 0);
                OldReborn(LOld, LPlayer, LNet, LDeath);
                LReborn.Respawn(LPlayer, LNet, LDeath, 8);
                Assert.AreEqual(LOld.Log, LNew.Log,
                  Format('spots %d weapons %d player %d death %d net %s',
                  [LSpots, LWeapons, LPlayer, LDeath, BoolToStr(LNet, True)]));
                Inc(LCount);
              end;
    finally
      LReborn.Free;
    end;
  finally
    LOld.Free;
    LNew.Free;
  end;
  Assert.IsTrue(LCount > 10000);
end;

procedure TTestThinkersCoopReborn.DovrebbeRifiutareUnHostNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TCoopReborn.Create(nil).Free;
    end,
    EArgumentNilException);
end;

end.
