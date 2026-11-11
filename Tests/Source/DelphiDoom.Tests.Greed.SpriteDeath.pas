{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSpriteDeath                                       }
{                                                                              }
{  The oracle is KillSprite of xGreed as it was (the calls to the rest of the   }
{  game go to a log, the random numbers come from the same generator)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SpriteDeath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.SpriteDeath;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSpriteDeath = class(TObject)
  public
    [Test]
    procedure DovrebbeSollevareSenzaPoolNeHost;
    [Test]
    procedure DovrebbeSollevareConUnTipoCheNonMuore;
    [Test]
    procedure DovrebbeLasciareUnCadavereAlMostroUno;
    [Test]
    procedure DovrebbeFarEsplodereIlMostroTreEToglierlo;
    [Test]
    procedure DovrebbeTrasformareUnCloneDelPrimoPersonaggioInUnaMina;
    [Test]
    procedure DovrebbeEseguireLEventoDiMorte;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
  end;

implementation

type
  // One generator for the game and the oracle: both start from the same seed
  TLogHost = class(TInterfacedObject, IGreedDeathHost)
  strict private
    FPool: TGreedLinkedPool<TGreedSprite>;
    FLog: TStringBuilder;
    FSeed: Cardinal;
    FClock: Integer;
    FFirstCharacter: Integer;
  public
    constructor Create(APool: TGreedLinkedPool<TGreedSprite>; ALog: TStringBuilder; ASeed: Cardinal;
      AClock, AFirstCharacter: Integer);
    function RandomNumber: Integer;
    function GetClock: Integer;
    function GetPlayerNumber: Integer;
    function GetFirstCharacterLump: Integer;
    procedure RunEvent(AEvent: Integer);
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    function SpawnSprite(AKind, AX, AY, AZ, AOwner: Integer): Integer;
  end;

constructor TLogHost.Create(APool: TGreedLinkedPool<TGreedSprite>; ALog: TStringBuilder; ASeed: Cardinal;
  AClock, AFirstCharacter: Integer);
begin
  inherited Create;
  FPool := APool;
  FLog := ALog;
  FSeed := ASeed;
  FClock := AClock;
  FFirstCharacter := AFirstCharacter;
end;

function TLogHost.RandomNumber: Integer;
begin
  FSeed := FSeed * 1664525 + 1013904223;
  Result := (FSeed shr 8) and 255;
  FLog.Append('r').Append(Result).Append(';');
end;

function TLogHost.GetClock: Integer;
begin
  Result := FClock;
end;

function TLogHost.GetPlayerNumber: Integer;
begin
  Result := 3;
end;

function TLogHost.GetFirstCharacterLump: Integer;
begin
  Result := FFirstCharacter;
end;

procedure TLogHost.RunEvent(AEvent: Integer);
begin
  FLog.Append('E').Append(AEvent).Append(';');
end;

procedure TLogHost.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FLog.Append('S').Append(ASound).Append(',').Append(AVariation).Append(',').Append(AX).Append(',').Append(AY)
    .Append(';');
end;

function TLogHost.SpawnSprite(AKind, AX, AY, AZ, AOwner: Integer): Integer;
begin
  Result := FPool.Add;
  FPool.Item(Result)^.Kind := AKind;
  FPool.Item(Result)^.X := AX;
  FPool.Item(Result)^.Y := AY;
  FPool.Item(Result)^.Z := AZ;
  FPool.Item(Result)^.SpawnId := AOwner;
  FLog.Append('P').Append(AKind).Append(',').Append(AX).Append(',').Append(AY).Append(',').Append(AZ).Append(',')
    .Append(AOwner).Append(';');
end;

// the original KillSprite, with the calls of the game on the host and the removal on the pool
procedure OldKillSprite(const AHost: IGreedDeathHost; APool: TGreedLinkedPool<TGreedSprite>; AIndex: Integer);
const
  FRACUNIT = 65536;
var
  sp: TGreedLinkedPool<TGreedSprite>.PItem;
  s: Integer;
  i: Integer;
  x, y, z: Integer;
begin
  sp := APool.Item(AIndex);
  if sp.DeathEvent <> 0 then
    AHost.RunEvent(sp.DeathEvent);
  case sp.Kind of
    605:
      begin
        if sp.StartPic = AHost.GetFirstCharacterLump then
        begin
          s := AHost.SpawnSprite(137, sp.X, sp.Y, 0, AHost.GetPlayerNumber);
          APool.Item(s).BasePic := sp.StartPic + 40;
          APool.Item(s).Scale := 1;
          sp.Animation := 0 + (0 shl 1) + (1 shl 5) + (0 shl 9) + 32768;
        end
        else
          sp.Animation := 0 + (0 shl 1) + (8 shl 5) + ((4 + AHost.RandomNumber and 3) shl 9);
        sp.BasePic := sp.StartPic + 40;
        sp.Rotate := grOne;
        sp.Heat := 0;
        sp.Active := False;
        sp.MoveSpeed := 0;
        sp.HitPoints := 0;
      end;
    75, 77, 98, 86, 88, 90, 92, 96, 34, 36, 38:
      begin
        sp.BasePic := sp.StartPic + 48;
        sp.Animation := 0 + (0 shl 1) + (8 shl 5) + ((2 + AHost.RandomNumber and 3) shl 9);
        case sp.Kind of
          75: AHost.PlaySound(54, 7, sp.X, sp.Y);
          77: AHost.PlaySound(57, 7, sp.X, sp.Y);
          98: AHost.PlaySound(66, 7, sp.X, sp.Y);
          86: AHost.PlaySound(72, 7, sp.X, sp.Y);
          88: AHost.PlaySound(2, 7, sp.X, sp.Y);
          90: AHost.PlaySound(5, 7, sp.X, sp.Y);
          92: AHost.PlaySound(8, 7, sp.X, sp.Y);
          96: AHost.PlaySound(75, 7, sp.X, sp.Y);
          34: AHost.PlaySound(78, 7, sp.X, sp.Y);
          36: AHost.PlaySound(81, 7, sp.X, sp.Y);
          38: AHost.PlaySound(84, 7, sp.X, sp.Y);
        end;
        sp.Rotate := grOne;
        sp.Heat := 0;
        sp.Active := False;
        sp.MoveSpeed := 0;
        sp.HitPoints := 0;
      end;
    79:
      begin
        AHost.SpawnSprite(525, sp.X, sp.Y, sp.Z, 0);
        AHost.PlaySound(60, 7, sp.X, sp.Y);
        APool.Remove(AIndex);
      end;
    81:
      begin
        AHost.SpawnSprite(525, sp.X, sp.Y, sp.Z, 0);
        AHost.PlaySound(63, 7, sp.X, sp.Y);
        APool.Remove(AIndex);
      end;
    84, 94:
      begin
        for i := 0 to 29 do
          AHost.SpawnSprite(607, sp.X, sp.Y, sp.Z + 64 * FRACUNIT, 0);
        for i := 0 to 9 do
        begin
          x := sp.X + ((-64 + (AHost.RandomNumber and 127)) * FRACUNIT);
          y := sp.Y + ((-64 + (AHost.RandomNumber and 127)) * FRACUNIT);
          z := sp.Z + ((AHost.RandomNumber and 127) * FRACUNIT);
          AHost.SpawnSprite(525 + (AHost.RandomNumber and 1), x, y, z, 0);
        end;
        AHost.PlaySound(22 + (AHost.GetClock and 1), 15, x, y);
        AHost.PlaySound(11, 7, sp.X, sp.Y);
        AHost.PlaySound(11, 7, sp.X, sp.Y);
        APool.Remove(AIndex);
      end;
  else
    raise EGreedException.Create('illegal');
  end;
end;

{ TTestGreedSpriteDeath }

procedure TTestGreedSpriteDeath.DovrebbeSollevareSenzaPoolNeHost;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LHost: IGreedDeathHost;
  LRaised: Boolean;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  try
    LHost := TLogHost.Create(LPool, LLog, 1, 0, 0);
    LRaised := False;
    try
      TGreedSpriteDeath.Create(nil, LHost).Free;
    except
      on EArgumentNilException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'pool');
    LRaised := False;
    try
      TGreedSpriteDeath.Create(LPool, nil).Free;
    except
      on EArgumentNilException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'host');
  finally
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeSollevareConUnTipoCheNonMuore;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LDeath: TGreedSpriteDeath;
  LRaised: Boolean;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  LDeath := TGreedSpriteDeath.Create(LPool, TLogHost.Create(LPool, LLog, 1, 0, 0));
  try
    LPool.Item(LPool.Add)^.Kind := 1;
    LRaised := False;
    try
      LDeath.Kill(0);
    except
      on EGreedException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LDeath.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeLasciareUnCadavereAlMostroUno;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LDeath: TGreedSpriteDeath;
  LSprite: TGreedLinkedPool<TGreedSprite>.PItem;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  LDeath := TGreedSpriteDeath.Create(LPool, TLogHost.Create(LPool, LLog, 1, 0, 0));
  try
    LSprite := LPool.Item(LPool.Add);
    LSprite^.Kind := GREED_S_MONSTER1;
    LSprite^.StartPic := 100;
    LSprite^.HitPoints := 20;
    LSprite^.Active := True;
    LDeath.Kill(0);
    Assert.AreEqual(148, LSprite^.BasePic);
    Assert.AreEqual(0, LSprite^.HitPoints);
    Assert.IsFalse(LSprite^.Active);
    Assert.AreEqual(1, LPool.Count, 'the corpse stays');
    Assert.IsTrue(LLog.ToString.Contains('S54,7,'), 'the death sound of the monster 1');
  finally
    LDeath.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeFarEsplodereIlMostroTreEToglierlo;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LDeath: TGreedSpriteDeath;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  LDeath := TGreedSpriteDeath.Create(LPool, TLogHost.Create(LPool, LLog, 1, 0, 0));
  try
    LPool.Item(LPool.Add)^.Kind := GREED_S_MONSTER3;
    LDeath.Kill(0);
    // the explosion took the place of the monster in the list: it was allocated before the removal
    Assert.AreEqual(1, LPool.Count);
    Assert.AreEqual(GREED_S_EXPLODE, LPool.Item(LPool.First)^.Kind);
    Assert.IsTrue(LLog.ToString.Contains('S60,7,'));
  finally
    LDeath.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeTrasformareUnCloneDelPrimoPersonaggioInUnaMina;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LDeath: TGreedSpriteDeath;
  LMine: Integer;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  LDeath := TGreedSpriteDeath.Create(LPool, TLogHost.Create(LPool, LLog, 1, 0, 200));
  try
    LPool.Item(LPool.Add)^.Kind := GREED_S_CLONE;
    LPool.Item(0)^.StartPic := 200;
    LDeath.Kill(0);
    LMine := 1;
    Assert.AreEqual(GREED_S_TIME_MINE, LPool.Item(LMine)^.Kind);
    Assert.AreEqual(240, LPool.Item(LMine)^.BasePic);
    Assert.AreEqual(1, LPool.Item(LMine)^.Scale);
    Assert.AreEqual(3, LPool.Item(LMine)^.SpawnId, 'the owner is the player');
    Assert.AreEqual(1 shl 5 + GREED_ANIM_SELF_DESTRUCT, LPool.Item(0)^.Animation);
  finally
    LDeath.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeEseguireLEventoDiMorte;
var
  LPool: TGreedLinkedPool<TGreedSprite>;
  LLog: TStringBuilder;
  LDeath: TGreedSpriteDeath;
begin
  LPool := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  LLog := TStringBuilder.Create;
  LDeath := TGreedSpriteDeath.Create(LPool, TLogHost.Create(LPool, LLog, 1, 0, 0));
  try
    LPool.Item(LPool.Add)^.Kind := GREED_S_MONSTER2;
    LPool.Item(0)^.DeathEvent := 9;
    LDeath.Kill(0);
    Assert.IsTrue(LLog.ToString.StartsWith('E9;'));
  finally
    LDeath.Free;
    LPool.Free;
    LLog.Free;
  end;
end;

procedure TTestGreedSpriteDeath.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
const
  KINDS: array[0..14] of Integer = (605, 75, 77, 79, 81, 98, 84, 86, 88, 90, 92, 94, 96, 34, 36);
var
  LSeed: Cardinal;
  LScenario, LKind, LIndex: Integer;
  LPoolNew, LPoolOld: TGreedLinkedPool<TGreedSprite>;
  LLogNew, LLogOld: TStringBuilder;
  LHostNew, LHostOld: IGreedDeathHost;
  LDeath: TGreedSpriteDeath;
  LNewItem, LOldItem: TGreedLinkedPool<TGreedSprite>.PItem;
  LKilled: Integer;
  function Describe(APool: TGreedLinkedPool<TGreedSprite>): string;
  var
    LCursor: Integer;
    LItem: TGreedLinkedPool<TGreedSprite>.PItem;
  begin
    Result := '';
    LCursor := APool.First;
    while LCursor <> GREED_POOL_NIL do
    begin
      LItem := APool.Item(LCursor);
      Result := Result + Format('%d:%d,%d,%d,%d,%d,%d,%d,%d,%d;', [LCursor, LItem^.Kind, LItem^.BasePic,
        LItem^.Animation, Ord(LItem^.Rotate), Ord(LItem^.Active), LItem^.HitPoints, LItem^.MoveSpeed, LItem^.Scale,
        LItem^.SpawnId]);
      LCursor := APool.Next(LCursor);
    end;
  end;
begin
  LSeed := 8675309;
  for LScenario := 1 to 300 do
  begin
    LKind := KINDS[LScenario mod Length(KINDS)];
    LPoolNew := TGreedLinkedPool<TGreedSprite>.Create(200, 'new');
    LPoolOld := TGreedLinkedPool<TGreedSprite>.Create(200, 'old');
    LLogNew := TStringBuilder.Create;
    LLogOld := TStringBuilder.Create;
    try
      LHostNew := TLogHost.Create(LPoolNew, LLogNew, LSeed, LScenario, 200);
      LHostOld := TLogHost.Create(LPoolOld, LLogOld, LSeed, LScenario, 200);
      LDeath := TGreedSpriteDeath.Create(LPoolNew, LHostNew);
      try
        // some other sprites first, so that the index of the dying one is not 0
        for LIndex := 0 to LScenario mod 4 do
        begin
          LPoolNew.Add;
          LPoolOld.Add;
        end;
        LNewItem := LPoolNew.Item(LPoolNew.Add);
        LOldItem := LPoolOld.Item(LPoolOld.Add);
        LKilled := LPoolNew.Count - 1;
        LNewItem^.Kind := LKind;
        // the clones of the first character (the lump 200) and of the others
        if LScenario mod 2 = 0 then
          LNewItem^.StartPic := 200
        else
          LNewItem^.StartPic := 100 + LScenario;
        LNewItem^.X := Integer(LSeed mod 100000) * 100;
        LNewItem^.Y := Integer(LSeed mod 77777) * 100;
        LNewItem^.Z := LScenario * 65536;
        LNewItem^.DeathEvent := LScenario mod 3;
        LNewItem^.HitPoints := 50;
        LNewItem^.Active := True;
        LNewItem^.MoveSpeed := 1000;
        LNewItem^.Heat := 9;
        LOldItem^ := LNewItem^;
        LSeed := LSeed * 1664525 + 1013904223;
        LDeath.Kill(LKilled);
        OldKillSprite(LHostOld, LPoolOld, LKilled);
        Assert.AreEqual(LLogOld.ToString, LLogNew.ToString, Format('calls, scenario %d', [LScenario]));
        Assert.AreEqual(Describe(LPoolOld), Describe(LPoolNew), Format('pool, scenario %d', [LScenario]));
      finally
        LDeath.Free;
      end;
    finally
      LPoolNew.Free;
      LPoolOld.Free;
      LLogNew.Free;
      LLogOld.Free;
    end;
  end;
end;

end.
