{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedLinkedPool and TGreedElevatorRules                }
{                                                                              }
{  The oracles are RF_ClearWorld, RF_GetElevator, RF_RemoveElevator and         }
{  CheckElevators of xGreed as they were (lists of pointers in global arrays)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Actors;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedLinkedPool = class(TObject)
  private
    FPool: TGreedLinkedPool<TGreedSprite>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeDareGliIndiciInOrdineEMantenereLOrdineDiCreazione;
    [Test]
    procedure DovrebbeAzzerareUnOggettoNuovo;
    [Test]
    procedure DovrebbeRiusarePerPrimoIlUltimoRimosso;
    [Test]
    procedure DovrebbeSollevareQuandoNonCiSonoOggettiLiberi;
    [Test]
    procedure DovrebbeSollevareConUnIndiceSbagliato;
    [Test]
    procedure DovrebbeRipartireDaZeroConClear;
    [Test]
    procedure DovrebbeDareGliStessiIndiciDelCodiceOriginale;
    [Test]
    procedure DovrebbeUsareLaCapacitaDellOriginale;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedElevatorRules = class(TObject)
  public
    [Test]
    procedure DovrebbeSollevareSenzaWorldNeHost;
    [Test]
    procedure DovrebbeSalireFinoAlSoffittoEDarsiIlGiro;
    [Test]
    procedure DovrebbeToglierSiAllaFineSeNonRipete;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

uses
  System.Classes, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Factory, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World, DelphiDoom.Greed.Elevator.Intf,
  DelphiDoom.Greed.ElevatorRules, DelphiDoom.Greed.Terrain, DelphiDoom.Tests.Greed.Builders;

function NextRandom(var ASeed: Cardinal): Cardinal;
begin
  ASeed := ASeed * 1664525 + 1013904223;
  Result := ASeed shr 8;
end;

{ the original lists of pointers }

type
  POldItem = ^TOldItem;
  TOldItem = record
    prev: POldItem;
    next: POldItem;
    payload: Integer;
  end;

  POldElev = ^TOldElev;
  TOldElev = record
    prev: POldElev;
    next: POldElev;
    elevUp: Boolean;
    elevDown: Boolean;
    position: Integer;
    position64: Integer;
    elevTimer: Integer;
    floor: Integer;
    ceiling: Integer;
    mapspot: Integer;
    speed: Integer;
    eval: Integer;
    endeval: Integer;
    nosave: Integer;
    typ: TGreedElevatorType;
  end;

var
  OItems: array[0..GREED_MAX_SPRITES - 1] of TOldItem;
  OFirstItem, OLastItem: TOldItem;
  OFreeItem: POldItem;
  OElevs: array[0..GREED_MAX_ELEVATORS - 1] of TOldElev;
  OFirstElev, OLastElev: TOldElev;
  OFreeElev: POldElev;

function OldItemIndex(const AItem: POldItem): Integer;
begin
  Result := (NativeInt(AItem) - NativeInt(@OItems[0])) div SizeOf(TOldItem);
end;

function OldElevIndex(const AElevator: POldElev): Integer;
begin
  Result := (NativeInt(AElevator) - NativeInt(@OElevs[0])) div SizeOf(TOldElev);
end;

procedure OldClear;
var
  i: Integer;
begin
  OFirstItem.prev := nil;
  OFirstItem.next := @OLastItem;
  OLastItem.prev := @OFirstItem;
  OLastItem.next := nil;
  OFreeItem := @OItems[0];
  FillChar(OItems, SizeOf(OItems), 0);
  for i := 0 to GREED_MAX_SPRITES - 2 do
    OItems[i].next := @OItems[i + 1];
  OFirstElev.prev := nil;
  OFirstElev.next := @OLastElev;
  OLastElev.prev := @OFirstElev;
  OLastElev.next := nil;
  OFreeElev := @OElevs[0];
  FillChar(OElevs, SizeOf(OElevs), 0);
  for i := 0 to GREED_MAX_ELEVATORS - 2 do
    OElevs[i].next := @OElevs[i + 1];
end;

function OldGetItem: POldItem;
begin
  Result := OFreeItem;
  OFreeItem := OFreeItem.next;
  FillChar(Result^, SizeOf(TOldItem), 0);
  Result.next := @OLastItem;
  Result.prev := OLastItem.prev;
  OLastItem.prev := Result;
  Result.prev.next := Result;
end;

procedure OldRemoveItem(const spr: POldItem);
begin
  spr.next.prev := spr.prev;
  spr.prev.next := spr.next;
  spr.next := OFreeItem;
  OFreeItem := spr;
end;

function OldGetElevator: POldElev;
begin
  Result := OFreeElev;
  OFreeElev := OFreeElev.next;
  FillChar(Result^, SizeOf(TOldElev), 0);
  Result.next := @OLastElev;
  Result.prev := OLastElev.prev;
  OLastElev.prev := Result;
  Result.prev.next := Result;
end;

procedure OldRemoveElevator(const e: POldElev);
begin
  e.next.prev := e.prev;
  e.prev.next := e.next;
  e.next := OFreeElev;
  OFreeElev := e;
end;

{ a host that writes down what is asked }

type
  TLogHost = class(TInterfacedObject, IGreedElevatorHost)
  strict private
    FLog: TStringBuilder;
    FTime: Integer;
  public
    constructor Create(ALog: TStringBuilder);
    function GetTimeCount: Integer;
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    procedure RunEvent(AEvent: Integer);
    property Time: Integer read FTime write FTime;
  end;

constructor TLogHost.Create(ALog: TStringBuilder);
begin
  inherited Create;
  FLog := ALog;
end;

function TLogHost.GetTimeCount: Integer;
begin
  Result := FTime;
end;

procedure TLogHost.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FLog.Append('S').Append(ASound).Append(',').Append(AVariation).Append(',').Append(AX).Append(',').Append(AY)
    .Append(';');
end;

procedure TLogHost.RunEvent(AEvent: Integer);
begin
  FLog.Append('E').Append(AEvent).Append(';');
end;

{ the original CheckElevators, on a world that is only the planes we read }

procedure OldCheckElevators(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; var AFall: Integer;
  const ALog: TStringBuilder; ATime: Integer);
var
  elev_p: POldElev;
  time: Integer;
  floorz, newfloorz: Integer;
  pwasonground: Boolean;

  function RFGetFloorZ(x, y: Integer): Integer;
  begin
    Result := TGreedTerrain.FloorZ(AWorld, x, y);
  end;

  procedure Sound(ASpot: Integer);
  begin
    ALog.Append('S48,15,').Append((ASpot and 63) * GREED_FRACTILEUNIT).Append(',')
      .Append((ASpot div 64) * GREED_FRACTILEUNIT).Append(';');
  end;

  function CAddI(var a: Integer; const b: Integer): Integer;
  begin
    a := a + b;
    Result := a;
  end;

  function CSubI(var a: Integer; const b: Integer): Integer;
  begin
    a := a - b;
    Result := a;
  end;

const
  FRACUNIT = 65536;
  MOVEDELAY = 7;
  TICRATE = 70;
  FALLUNIT = FRACUNIT;
begin
  floorz := RFGetFloorZ(APlayer.X, APlayer.Y) + APlayer.Height;
  pwasonground := floorz >= APlayer.Z;
  time := ATime;
  elev_p := OFirstElev.next;
  while elev_p <> @OLastElev do
  begin
    while time >= elev_p.elevTimer do
    begin
      if elev_p.elevUp and (CAddI(elev_p.position64, FRACUNIT * elev_p.speed div MOVEDELAY) >= elev_p.ceiling * FRACUNIT) then
      begin
        Sound(elev_p.mapspot);
        elev_p.position := elev_p.ceiling;
        elev_p.position64 := elev_p.position * FRACUNIT;
        if elev_p.typ = getNormal then
          elev_p.elevDown := true
        else if (elev_p.typ <> getSwap) and (elev_p.typ <> getSecret) then
        begin
          if elev_p.endeval <> 0 then
            ALog.Append('E').Append(elev_p.endeval).Append(';');
          AWorld.SetValue(gpFloorHeight, elev_p.mapspot, Byte(elev_p.position));
          if AWorld.GetValue(gpMapSprites, elev_p.mapspot) = 127 then
            AWorld.SetValue(gpMapSprites, elev_p.mapspot, 0);
          elev_p := elev_p.prev;
          OldRemoveElevator(elev_p.next);
          break;
        end;
        elev_p.elevUp := false;
        elev_p.elevTimer := elev_p.elevTimer + 4 * TICRATE;
      end
      else if elev_p.elevDown and (CSubI(elev_p.position64, FRACUNIT * elev_p.speed div MOVEDELAY) <= elev_p.floor * FRACUNIT) then
      begin
        Sound(elev_p.mapspot);
        elev_p.position := elev_p.floor;
        elev_p.position64 := elev_p.position * FRACUNIT;
        if (elev_p.typ = getNormal) or (elev_p.typ = getSecret) then
          elev_p.elevUp := true
        else if elev_p.typ <> getSwap then
        begin
          if elev_p.endeval <> 0 then
            ALog.Append('E').Append(elev_p.endeval).Append(';');
          AWorld.SetValue(gpFloorHeight, elev_p.mapspot, Byte(elev_p.position));
          if AWorld.GetValue(gpMapSprites, elev_p.mapspot) = 127 then
            AWorld.SetValue(gpMapSprites, elev_p.mapspot, 0);
          elev_p := elev_p.prev;
          OldRemoveElevator(elev_p.next);
          break;
        end;
        elev_p.elevDown := false;
        elev_p.elevTimer := elev_p.elevTimer + 4 * TICRATE;
      end
      else
        elev_p.position := elev_p.position64 div FRACUNIT;
      if (elev_p.typ = getSecret) and elev_p.elevUp then
      begin
        if (APlayer.MapSpot = elev_p.mapspot) or (AWorld.GetValue(gpMapSprites, elev_p.mapspot) <> 0) then
        begin
          elev_p.position := elev_p.floor;
          elev_p.position64 := elev_p.position * FRACUNIT;
        end;
      end;
      if AWorld.GetValue(gpMapSprites, elev_p.mapspot) = 127 then
        AWorld.SetValue(gpMapSprites, elev_p.mapspot, 0);
      AWorld.SetValue(gpFloorHeight, elev_p.mapspot, Byte(elev_p.position));
      elev_p.elevTimer := elev_p.elevTimer + 1;
    end;
    elev_p := elev_p.next;
  end;
  if pwasonground then
  begin
    newfloorz := RFGetFloorZ(APlayer.X, APlayer.Y) + APlayer.Height;
    if (newfloorz <> floorz) then
    begin
      if APlayer.Z > newfloorz then
      begin
        if AFall >= 0 then
        begin
          APlayer.Z := newfloorz;
          AFall := 0;
        end
        else
          AFall := AFall - FALLUNIT;
      end
      else if APlayer.Z < newfloorz then
      begin
        APlayer.Z := newfloorz;
        AFall := 0;
      end;
    end;
  end;
end;

{ TTestGreedLinkedPool }

procedure TTestGreedLinkedPool.Setup;
begin
  FPool := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
end;

procedure TTestGreedLinkedPool.TearDown;
begin
  FreeAndNil(FPool);
end;

procedure TTestGreedLinkedPool.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FPool.Count);
  Assert.AreEqual(GREED_POOL_NIL, FPool.First);
end;

procedure TTestGreedLinkedPool.DovrebbeDareGliIndiciInOrdineEMantenereLOrdineDiCreazione;
var
  LIndex: Integer;
begin
  Assert.AreEqual(0, FPool.Add);
  Assert.AreEqual(1, FPool.Add);
  Assert.AreEqual(2, FPool.Add);
  Assert.AreEqual(3, FPool.Count);
  LIndex := FPool.First;
  Assert.AreEqual(0, LIndex);
  LIndex := FPool.Next(LIndex);
  Assert.AreEqual(1, LIndex);
  Assert.AreEqual(0, FPool.Previous(LIndex));
  LIndex := FPool.Next(FPool.Next(0));
  Assert.AreEqual(2, LIndex);
  Assert.AreEqual(GREED_POOL_NIL, FPool.Next(LIndex));
  Assert.AreEqual(GREED_POOL_NIL, FPool.Previous(0));
end;

procedure TTestGreedLinkedPool.DovrebbeAzzerareUnOggettoNuovo;
var
  LIndex: Integer;
begin
  LIndex := FPool.Add;
  FPool.Item(LIndex)^.HitPoints := 99;
  FPool.Remove(LIndex);
  LIndex := FPool.Add;
  Assert.AreEqual(0, FPool.Item(LIndex)^.HitPoints);
end;

procedure TTestGreedLinkedPool.DovrebbeRiusarePerPrimoIlUltimoRimosso;
begin
  FPool.Add;
  FPool.Add;
  FPool.Add;
  FPool.Remove(1);
  FPool.Remove(0);
  Assert.AreEqual(0, FPool.Add);
  Assert.AreEqual(1, FPool.Add);
  Assert.AreEqual(3, FPool.Add);
end;

procedure TTestGreedLinkedPool.DovrebbeSollevareQuandoNonCiSonoOggettiLiberi;
var
  LIndex: Integer;
begin
  for LIndex := 1 to GREED_MAX_SPRITES do
    FPool.Add;
  Assert.WillRaise(
    procedure
    begin
      FPool.Add;
    end, EGreedException);
end;

procedure TTestGreedLinkedPool.DovrebbeSollevareConUnIndiceSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      FPool.Item(-1);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FPool.Remove(GREED_MAX_SPRITES);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLinkedPool<TGreedSprite>.Create(0, 'x');
    end, EGreedException);
end;

procedure TTestGreedLinkedPool.DovrebbeRipartireDaZeroConClear;
begin
  FPool.Add;
  FPool.Add;
  FPool.Clear;
  Assert.AreEqual(0, FPool.Count);
  Assert.AreEqual(GREED_POOL_NIL, FPool.First);
  Assert.AreEqual(0, FPool.Add);
end;

procedure TTestGreedLinkedPool.DovrebbeUsareLaCapacitaDellOriginale;
begin
  Assert.AreEqual(4096, FPool.Capacity);
  Assert.AreEqual(4096, GREED_MAX_SPRITES);
  Assert.AreEqual(128, GREED_MAX_ELEVATORS);
end;

procedure TTestGreedLinkedPool.DovrebbeDareGliStessiIndiciDelCodiceOriginale;
var
  LSeed: Cardinal;
  LStep, LNew, LIndex: Integer;
  LOld: POldItem;
  LUsed: TArray<Integer>;
  LExpected, LActual: string;
begin
  LSeed := 777;
  OldClear;
  for LStep := 1 to 30000 do
  begin
    if (NextRandom(LSeed) mod 3 <> 0) or (FPool.Count = 0) then
    begin
      if FPool.Count = GREED_MAX_SPRITES then
        Continue;
      LNew := FPool.Add;
      LOld := OldGetItem;
      Assert.AreEqual(OldItemIndex(LOld), LNew, 'index of a new object');
    end
    else
    begin
      // remove the object that is at a random place of the list
      LUsed := nil;
      LIndex := FPool.First;
      while LIndex <> GREED_POOL_NIL do
      begin
        SetLength(LUsed, Length(LUsed) + 1);
        LUsed[High(LUsed)] := LIndex;
        LIndex := FPool.Next(LIndex);
      end;
      LNew := LUsed[NextRandom(LSeed) mod Cardinal(Length(LUsed))];
      FPool.Remove(LNew);
      OldRemoveItem(@OItems[LNew]);
    end;
    if LStep mod 500 = 0 then
    begin
      LExpected := '';
      LOld := OFirstItem.next;
      while LOld <> @OLastItem do
      begin
        LExpected := LExpected + IntToStr(OldItemIndex(LOld)) + ',';
        LOld := LOld.next;
      end;
      LActual := '';
      LIndex := FPool.First;
      while LIndex <> GREED_POOL_NIL do
      begin
        LActual := LActual + IntToStr(LIndex) + ',';
        LIndex := FPool.Next(LIndex);
      end;
      Assert.AreEqual(LExpected, LActual, 'order of the list');
    end;
  end;
end;

{ TTestGreedElevatorRules }

function MakeMap(var ASeed: Cardinal): IGreedMap;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := TGreedLumps.MapBytes(nil);
  for LIndex := 0 to High(LBytes) do
    LBytes[LIndex] := Byte(NextRandom(ASeed));
  for LIndex := 0 to 4095 do
  begin
    LBytes[Ord(gpFloorHeight) * 4096 + LIndex] := LBytes[Ord(gpFloorHeight) * 4096 + LIndex] mod 60;
    LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] := 64 + LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] mod 60;
    // many elevator markers
    if NextRandom(ASeed) mod 3 = 0 then
      LBytes[Ord(gpMapSprites) * 4096 + LIndex] := 127;
  end;
  Result := TGreedFactory.CreateMapReader.Read(LBytes);
end;

function MakeWorld(var ASeed: Cardinal): IGreedWorld;
begin
  Result := TGreedWorld.Create;
  Result.Load(MakeMap(ASeed));
end;

function RefusesNil(const AWorld: IGreedWorld; APool: TGreedLinkedPool<TGreedElevator>;
  const AHost: IGreedElevatorHost): Boolean;
begin
  Result := False;
  try
    TGreedElevatorRules.Create(AWorld, APool, AHost).Free;
  except
    on EArgumentNilException do
      Result := True;
  end;
end;

procedure TTestGreedElevatorRules.DovrebbeSollevareSenzaWorldNeHost;
var
  LLog: TStringBuilder;
  LPool: TGreedLinkedPool<TGreedElevator>;
begin
  LLog := TStringBuilder.Create;
  LPool := TGreedLinkedPool<TGreedElevator>.Create(4, 'elevators');
  try
    Assert.IsTrue(RefusesNil(nil, LPool, TLogHost.Create(LLog)), 'world');
    Assert.IsTrue(RefusesNil(TGreedWorld.Create, nil, TLogHost.Create(LLog)), 'pool');
    Assert.IsTrue(RefusesNil(TGreedWorld.Create, LPool, nil), 'host');
  finally
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedElevatorRules.DovrebbeSalireFinoAlSoffittoEDarsiIlGiro;
var
  LSeed: Cardinal;
  LWorld: IGreedWorld;
  LPool: TGreedLinkedPool<TGreedElevator>;
  LRules: TGreedElevatorRules;
  LLog: TStringBuilder;
  LHost: TLogHost;
  LPlayer: TGreedPlayerRecord;
  LFall, LTick, LIndex: Integer;
begin
  LSeed := 5;
  LWorld := MakeWorld(LSeed);
  LLog := TStringBuilder.Create;
  LPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  LHost := TLogHost.Create(LLog);
  LRules := TGreedElevatorRules.Create(LWorld, LPool, LHost);
  try
    FillChar(LPlayer, SizeOf(LPlayer), 0);
    LPlayer.X := 100 * GREED_FRACUNIT;
    LPlayer.Y := 100 * GREED_FRACUNIT;
    LPlayer.MapSpot := 4095;
    LIndex := LPool.Add;
    LPool.Item(LIndex)^.Up := True;
    LPool.Item(LIndex)^.Kind := getNormal;
    LPool.Item(LIndex)^.Floor := 10;
    LPool.Item(LIndex)^.Ceiling := 30;
    LPool.Item(LIndex)^.MapSpot := 3000;
    LPool.Item(LIndex)^.Speed := 70;
    LPool.Item(LIndex)^.Position := 10;
    LPool.Item(LIndex)^.Position64 := 10 * GREED_FRACUNIT;
    LFall := 0;
    for LTick := 0 to 400 do
    begin
      LHost.Time := LTick;
      LRules.Check(LPlayer, LFall);
    end;
    // it went up to 30, then down and up again: it is still in the list, and the floor is a value of its path
    Assert.AreEqual(1, LPool.Count);
    Assert.IsTrue(LLog.ToString.Contains('S48,15,'), 'the sound of the start');
    Assert.IsTrue((LWorld.GetValue(gpFloorHeight, 3000) >= 10) and (LWorld.GetValue(gpFloorHeight, 3000) <= 30));
  finally
    LRules.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedElevatorRules.DovrebbeToglierSiAllaFineSeNonRipete;
var
  LSeed: Cardinal;
  LWorld: IGreedWorld;
  LPool: TGreedLinkedPool<TGreedElevator>;
  LRules: TGreedElevatorRules;
  LLog: TStringBuilder;
  LHost: TLogHost;
  LPlayer: TGreedPlayerRecord;
  LFall, LTick, LIndex: Integer;
begin
  LSeed := 9;
  LWorld := MakeWorld(LSeed);
  LLog := TStringBuilder.Create;
  LPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  LHost := TLogHost.Create(LLog);
  LRules := TGreedElevatorRules.Create(LWorld, LPool, LHost);
  try
    FillChar(LPlayer, SizeOf(LPlayer), 0);
    LPlayer.MapSpot := 4095;
    LIndex := LPool.Add;
    LPool.Item(LIndex)^.Up := True;
    LPool.Item(LIndex)^.Kind := getSwitchDown;
    LPool.Item(LIndex)^.Floor := 10;
    LPool.Item(LIndex)^.Ceiling := 30;
    LPool.Item(LIndex)^.MapSpot := 3000;
    LPool.Item(LIndex)^.Speed := 70;
    LPool.Item(LIndex)^.EndEval := 17;
    LPool.Item(LIndex)^.Position := 10;
    LPool.Item(LIndex)^.Position64 := 10 * GREED_FRACUNIT;
    LFall := 0;
    for LTick := 0 to 400 do
    begin
      LHost.Time := LTick;
      LRules.Check(LPlayer, LFall);
    end;
    Assert.AreEqual(0, LPool.Count);
    Assert.IsTrue(LLog.ToString.Contains('E17;'), 'the end event');
    Assert.AreEqual(30, Integer(LWorld.GetValue(gpFloorHeight, 3000)));
  finally
    LRules.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedElevatorRules.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
var
  LSeed: Cardinal;
  LScenario, LTick, LCount, LIndex, LFallNew, LFallOld: Integer;
  LWorldNew, LWorldOld: IGreedWorld;
  LMap: IGreedMap;
  LPool: TGreedLinkedPool<TGreedElevator>;
  LRules: TGreedElevatorRules;
  LLogNew, LLogOld: TStringBuilder;
  LHost: TLogHost;
  LPlayerNew, LPlayerOld: TGreedPlayerRecord;
  LItem: TGreedLinkedPool<TGreedElevator>.PItem;
  LOld: POldElev;
  LExpected, LActual: string;
  LSpot, LKind: Integer;
begin
  LSeed := 31337;
  for LScenario := 1 to 150 do
  begin
    // two worlds from the same random bytes
    LMap := MakeMap(LSeed);
    LWorldNew := TGreedWorld.Create;
    LWorldNew.Load(LMap);
    LWorldOld := TGreedWorld.Create;
    LWorldOld.Load(LMap);
    LLogNew := TStringBuilder.Create;
    LLogOld := TStringBuilder.Create;
    LPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
    LHost := TLogHost.Create(LLogNew);
    LRules := TGreedElevatorRules.Create(LWorldNew, LPool, LHost);
    try
      OldClear;
      FillChar(LPlayerNew, SizeOf(LPlayerNew), 0);
      LPlayerNew.X := Integer(NextRandom(LSeed) mod 64) * GREED_FRACUNIT * 64 + 100;
      LPlayerNew.Y := Integer(NextRandom(LSeed) mod 64) * GREED_FRACUNIT * 64 + 100;
      LPlayerNew.Height := 40 * GREED_FRACUNIT;
      LPlayerNew.Z := Integer(NextRandom(LSeed) mod 80) * GREED_FRACUNIT;
      LPlayerNew.MapSpot := Integer(NextRandom(LSeed) mod 4096);
      LPlayerOld := LPlayerNew;
      LFallNew := Integer(NextRandom(LSeed) mod 5) * -GREED_FRACUNIT;
      LFallOld := LFallNew;
      LCount := 1 + Integer(NextRandom(LSeed) mod 6);
      for LIndex := 1 to LCount do
      begin
        LSpot := Integer(NextRandom(LSeed) mod 4096);
        if NextRandom(LSeed) mod 3 = 0 then
          LSpot := (LPlayerNew.X div (64 * GREED_FRACUNIT)) + 64 * (LPlayerNew.Y div (64 * GREED_FRACUNIT));
        LKind := Integer(NextRandom(LSeed) mod 10);
        LItem := LPool.Item(LPool.Add);
        LOld := OldGetElevator;
        LItem^.Up := NextRandom(LSeed) mod 2 = 0;
        LItem^.Down := (not LItem^.Up) or (NextRandom(LSeed) mod 8 = 0);
        LItem^.Position := 10 + Integer(NextRandom(LSeed) mod 30);
        LItem^.Position64 := LItem^.Position * GREED_FRACUNIT + Integer(NextRandom(LSeed) mod 60000);
        LItem^.Timer := Integer(NextRandom(LSeed) mod 40);
        LItem^.Floor := 10;
        LItem^.Ceiling := 40 + Integer(NextRandom(LSeed) mod 20);
        LItem^.MapSpot := LSpot;
        LItem^.Speed := 20 + Integer(NextRandom(LSeed) mod 400);
        LItem^.EndEval := Integer(NextRandom(LSeed) mod 3);
        LItem^.Kind := TGreedElevatorType(LKind);
        LOld.elevUp := LItem^.Up;
        LOld.elevDown := LItem^.Down;
        LOld.position := LItem^.Position;
        LOld.position64 := LItem^.Position64;
        LOld.elevTimer := LItem^.Timer;
        LOld.floor := LItem^.Floor;
        LOld.ceiling := LItem^.Ceiling;
        LOld.mapspot := LItem^.MapSpot;
        LOld.speed := LItem^.Speed;
        LOld.endeval := LItem^.EndEval;
        LOld.typ := LItem^.Kind;
      end;
      for LTick := 0 to 500 do
      begin
        LHost.Time := LTick;
        LRules.Check(LPlayerNew, LFallNew);
        OldCheckElevators(LWorldOld, LPlayerOld, LFallOld, LLogOld, LTick);
        Assert.AreEqual(LLogOld.ToString, LLogNew.ToString, Format('calls, scenario %d tick %d', [LScenario, LTick]));
        Assert.AreEqual(LPlayerOld.Z, LPlayerNew.Z, 'player z');
        Assert.AreEqual(LFallOld, LFallNew, 'fall rate');
        if LTick mod 25 = 0 then
        begin
          LExpected := '';
          LOld := OFirstElev.next;
          while LOld <> @OLastElev do
          begin
            LExpected := LExpected + Format('%d:%d%d,%d,%d,%d,%d;', [OldElevIndex(LOld), Ord(LOld.elevUp),
              Ord(LOld.elevDown), LOld.position, LOld.position64, LOld.elevTimer, Ord(LOld.typ)]);
            LOld := LOld.next;
          end;
          LActual := '';
          LIndex := LPool.First;
          while LIndex <> GREED_POOL_NIL do
          begin
            LItem := LPool.Item(LIndex);
            LActual := LActual + Format('%d:%d%d,%d,%d,%d,%d;', [LIndex, Ord(LItem^.Up), Ord(LItem^.Down),
              LItem^.Position, LItem^.Position64, LItem^.Timer, Ord(LItem^.Kind)]);
            LIndex := LPool.Next(LIndex);
          end;
          Assert.AreEqual(LExpected, LActual, 'elevators');
          for LSpot := 0 to 4095 do
          begin
            Assert.AreEqual(Integer(LWorldOld.GetValue(gpFloorHeight, LSpot)),
              Integer(LWorldNew.GetValue(gpFloorHeight, LSpot)), 'floor height');
            Assert.AreEqual(Integer(LWorldOld.GetValue(gpMapSprites, LSpot)),
              Integer(LWorldNew.GetValue(gpMapSprites, LSpot)), 'map sprites');
          end;
        end;
      end;
    finally
      LRules.Free;
      LPool.Free;
      LLogNew.Free;
      LLogOld.Free;
    end;
  end;
end;

end.
