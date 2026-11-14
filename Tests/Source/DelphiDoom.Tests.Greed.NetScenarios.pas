{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: the scenarios of the net game             }
{                                                                              }
{  Shared by the test of TGreedNetSession and by the harness that runs the      }
{  code of net.pas of xGreed (Tools\Verifica\175-net): no DUnitX here           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

const
  NET_SCENARIO_RANDOM_COUNT = 40;
  NET_SCENARIO_RANDOM_OPS = 120;
  /// <summary>The value of a fake lump: what CA_GetNamedNum gives for the n-th character</summary>
  NET_CHARACTER_LUMP_BASE = 5000;
  NET_CHARACTER_LUMP_STEP = 100;
  /// <summary>basepic of a sprite that the fake SpawnSprite makes: this plus the value</summary>
  NET_SPAWN_PICTURE_BASE = 20000;

type
  TNetOpKind = (
    noClock, noPlayer, noIncoming, noMapSprite, noSetBonus, noAddSprite,
    noGetData, noSendPlayer, noNewPlayer, noSendSpawn, noSound, noItemPickup, noDeath, noClosest, noOpenDoor,
    noCheckHere, noBonus, noPause, noUnPause, noMessage, noQuit, noWarpJam, noEvent);

  /// <summary>One step of a scenario: the numbers mean what the kind says (see TNetScenarioRunner.RunOp)</summary>
  TNetOp = record
    Kind: TNetOpKind;
    A: array[0..11] of Integer;
    Text: AnsiString;
    Bytes: TBytes;
  end;

  /// <summary>One turn of the loop of NetWaitStart: the clock, and the packet that arrives in it (if any)</summary>
  TNetWaitTurn = record
    Time: Integer;
    HasPacket: Boolean;
    Packet: TBytes;
  end;

  TNetScenario = record
    Name: string;
    ConsolePlayer: Integer;
    NumPlayers: Integer;
    NetType: Integer;
    NetName: AnsiString;
    Map: Integer;
    Difficulty: Integer;
    /// <summary>A scenario of the start: these turns run before the steps</summary>
    Wait: TArray<TNetWaitTurn>;
    Ops: TArray<TNetOp>;
  end;

  /// <summary>
  ///   The scenarios: the hand made ones (the start in each role and kind of net, frags, bonus item, warp jammer,
  ///   texts, bytes that stay in the buffer) and the random ones from a seed. The packets that arrive are built
  ///   here byte by byte, not with the library. The random ones keep away from what makes the original read or
  ///   write outside its arrays (see TGreedNetSession): players 0..7, characters 0..5, a death only of a player
  ///   that has a sprite, texts with their zero
  /// </summary>
  TNetScenarios = class
  strict private
    class var FSeed: Cardinal;
    class function Next(ARange: Integer): Integer; static;
    class function Fixed(ATileRange: Integer): Integer; static;
    class procedure Add(var AScenario: TNetScenario; const AOp: TNetOp); static;
    class function Op(AKind: TNetOpKind; const AValues: array of Integer): TNetOp; static;
    class function Incoming(const ABytes: TBytes): TNetOp; static;
    class function Turn(ATime: Integer): TNetWaitTurn; overload; static;
    class function Turn(ATime: Integer; const APacket: TBytes): TNetWaitTurn; overload; static;
    class function Empty(const AName: string; AConsolePlayer, ANumPlayers, ANetType: Integer;
      const ANetName: AnsiString): TNetScenario; static;
    class function PlayerOp(AAngst, ASpecialEffect, AStatus: Integer): TNetOp; static;
    class function RandomPlayerPacket(AId, APlayer: Integer): TBytes; static;
    class function BuildStart(AIndex: Integer): TNetScenario; static;
    class function BuildHandMade(AIndex: Integer): TNetScenario; static;
    class function BuildRandom(ASeed: Integer): TNetScenario; static;
  public
    class function Count: Integer; static;
    class function Build(AIndex: Integer): TNetScenario; static;
    /// <summary>A packet: 32 bit little endian numbers, then the bytes of ATail</summary>
    class function Pack(const AValues: array of Integer; const ATail: TBytes = nil): TBytes; static;
    /// <summary>The bytes of a text in a field of ASize bytes; the rest is AFill</summary>
    class function TextField(const AText: AnsiString; ASize: Integer; AFill: Byte = 0): TBytes; static;
    /// <summary>ievent_t: 40 bytes</summary>
    class function InitPacket(APlayer, AFound, AStart: Integer; const AName: AnsiString; AMap,
      ADifficulty: Integer): TBytes; static;
    /// <summary>The n-th number of the fake MS_RndT</summary>
    class function RandomByte(ACall: Integer): Integer; static;
    /// <summary>What the fake CA_GetNamedNum gives for a character</summary>
    class function CharacterLump(ACharType: Integer): Integer; static;
  end;

implementation

const
  START_COUNT = 9;
  HAND_MADE_COUNT = 7;
  EV_INIT = 1;
  EV_PLAYER = 2;
  EV_SPAWN = 3;
  EV_QUIT = 4;
  EV_DOOR = 5;
  EV_FRAG = 6;
  EV_NEW_PLAYER = 7;
  EV_ITEM = 8;
  EV_BONUS = 9;
  EV_PAUSE = 10;
  EV_UNPAUSE = 11;
  EV_TRIGGER = 12;
  EV_SOUND = 13;
  EV_JAMMER = 14;
  EV_EVENT = 15;
  EV_MESSAGE = 16;
  NET_IPX = 1;
  NET_SERIAL = 2;
  NET_MODEM = 3;
  S_BULLET18 = 524;
  S_SOULBULLET = 530;
  S_GENERATOR = 537;
  S_BONUSITEM = 601;
  S_GENSTART = 400;
  S_MONSTER1 = 100;
  FRACTILE = 1 shl 22;
  UNKNOWN_IDS: array[0..3] of Integer = (0, EV_INIT, 17, 18);
  NAMES: array[0..7] of AnsiString = ('Ann', 'Bob', 'Cy', 'Dolores', 'Ed', 'Frederick12', 'G', 'Hal');

{ TNetScenarios }

class function TNetScenarios.Next(ARange: Integer): Integer;
begin
  FSeed := FSeed * 1103515245 + 12345;
  Result := Integer((FSeed shr 16) and $7FFF) mod ARange;
end;

class function TNetScenarios.Fixed(ATileRange: Integer): Integer;
var
  LTile, LPart: Integer;
begin
  // two draws in two statements: the order of evaluation is not the same at 32 and at 64 bit
  LTile := Next(ATileRange);
  LPart := Next(FRACTILE);
  Result := (LTile + 1) * FRACTILE + LPart;
end;

class procedure TNetScenarios.Add(var AScenario: TNetScenario; const AOp: TNetOp);
begin
  SetLength(AScenario.Ops, Length(AScenario.Ops) + 1);
  AScenario.Ops[High(AScenario.Ops)] := AOp;
end;

class function TNetScenarios.Op(AKind: TNetOpKind; const AValues: array of Integer): TNetOp;
var
  LIndex: Integer;
begin
  Result := Default(TNetOp);
  Result.Kind := AKind;
  for LIndex := 0 to High(AValues) do
    Result.A[LIndex] := AValues[LIndex];
end;

class function TNetScenarios.Incoming(const ABytes: TBytes): TNetOp;
begin
  Result := Default(TNetOp);
  Result.Kind := noIncoming;
  Result.Bytes := ABytes;
end;

class function TNetScenarios.Turn(ATime: Integer): TNetWaitTurn;
begin
  Result.Time := ATime;
  Result.HasPacket := False;
  Result.Packet := nil;
end;

class function TNetScenarios.Turn(ATime: Integer; const APacket: TBytes): TNetWaitTurn;
begin
  Result.Time := ATime;
  Result.HasPacket := True;
  Result.Packet := APacket;
end;

class function TNetScenarios.Pack(const AValues: array of Integer; const ATail: TBytes): TBytes;
var
  LIndex: Integer;
  LValue: Cardinal;
begin
  SetLength(Result, Length(AValues) * 4 + Length(ATail));
  for LIndex := 0 to High(AValues) do
  begin
    LValue := Cardinal(AValues[LIndex]);
    Result[LIndex * 4] := Byte(LValue and $FF);
    Result[LIndex * 4 + 1] := Byte((LValue shr 8) and $FF);
    Result[LIndex * 4 + 2] := Byte((LValue shr 16) and $FF);
    Result[LIndex * 4 + 3] := Byte(LValue shr 24);
  end;
  if Length(ATail) > 0 then
    Move(ATail[0], Result[Length(AValues) * 4], Length(ATail));
end;

class function TNetScenarios.TextField(const AText: AnsiString; ASize: Integer; AFill: Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    if LIndex < Length(AText) then
      Result[LIndex] := Byte(AText[LIndex + 1])
    else if LIndex = Length(AText) then
      Result[LIndex] := 0
    else
      Result[LIndex] := AFill;
end;

class function TNetScenarios.InitPacket(APlayer, AFound, AStart: Integer; const AName: AnsiString; AMap,
  ADifficulty: Integer): TBytes;
begin
  Result := Pack([EV_INIT, APlayer, AFound, AStart], TextField(AName, 16));
  Result := Result + Pack([AMap, ADifficulty]);
end;

class function TNetScenarios.RandomByte(ACall: Integer): Integer;
begin
  Result := (ACall * 37 + 11) and 255;
end;

class function TNetScenarios.CharacterLump(ACharType: Integer): Integer;
begin
  Result := NET_CHARACTER_LUMP_BASE + ACharType * NET_CHARACTER_LUMP_STEP;
end;

class function TNetScenarios.Empty(const AName: string; AConsolePlayer, ANumPlayers, ANetType: Integer;
  const ANetName: AnsiString): TNetScenario;
begin
  Result := Default(TNetScenario);
  Result.Name := AName;
  Result.ConsolePlayer := AConsolePlayer;
  Result.NumPlayers := ANumPlayers;
  Result.NetType := ANetType;
  Result.NetName := ANetName;
  Result.Map := 3;
  Result.Difficulty := 2;
end;

class function TNetScenarios.PlayerOp(AAngst, ASpecialEffect, AStatus: Integer): TNetOp;
var
  LX, LY, LZ, LAngle, LChar, LHolo, LScale: Integer;
begin
  LX := Fixed(60);
  LY := Fixed(60);
  LZ := Next(200) shl 16;
  LAngle := Next(1024);
  LChar := Next(6);
  LHolo := 0;
  LScale := 0;
  if Next(8) = 0 then
  begin
    LHolo := 300 + Next(50);
    LScale := Next(3);
  end;
  // x, y, z, angle, angst, height, chartype, status, holopic, holoscale, specialeffect
  Result := Op(noPlayer, [LX, LY, LZ, LAngle, AAngst, 48 shl 16, LChar, AStatus, LHolo, LScale, ASpecialEffect]);
end;

class function TNetScenarios.RandomPlayerPacket(AId, APlayer: Integer): TBytes;
var
  LX, LY, LZ, LAngle, LAngst, LChar, LStatus, LHolo, LScale, LEffect: Integer;
begin
  LX := Fixed(60);
  LY := Fixed(60);
  LZ := Next(200) shl 16;
  LAngle := Next(1024);
  LAngst := Next(3) * 250;
  LChar := Next(6);
  LStatus := Next(4);
  if LStatus = 3 then
    LStatus := 0;
  LHolo := 0;
  LScale := 0;
  if Next(6) = 0 then
  begin
    LHolo := 300 + Next(50);
    LScale := Next(3);
  end;
  LEffect := 0;
  if Next(5) = 0 then
    LEffect := 4;
  Result := Pack([AId, APlayer, LX, LY, LZ, LAngle, LAngst, LChar, LStatus, LHolo, LScale, 48 shl 16, LEffect]);
end;

class function TNetScenarios.BuildStart(AIndex: Integer): TNetScenario;
var
  LTime, LIndex: Integer;

  procedure AddTurn(const ATurn: TNetWaitTurn);
  begin
    SetLength(Result.Wait, Length(Result.Wait) + 1);
    Result.Wait[High(Result.Wait)] := ATurn;
  end;

begin
  case AIndex of
    0:
      begin
        // player 0 of two on IPX: it hears player 1, then player 1 that has found both, and starts
        Result := Empty('start: player 0 of 2, ipx', 0, 2, NET_IPX, 'Zero');
        AddTurn(Turn(10));
        AddTurn(Turn(71));
        AddTurn(Turn(72, InitPacket(1, 1, 0, 'One', 3, 4)));
        AddTurn(Turn(100));
        AddTurn(Turn(212));
        AddTurn(Turn(213, InitPacket(1, 2, 0, 'One', 3, 4)));
        AddTurn(Turn(300));
        AddTurn(Turn(353));
        AddTurn(Turn(354));
      end;
    1:
      begin
        // player 1 of two on IPX: the difficulty comes from player 0; the start is seen in the next turn
        Result := Empty('start: player 1 of 2, ipx', 1, 2, NET_IPX, 'One         ');
        AddTurn(Turn(5));
        AddTurn(Turn(80, InitPacket(0, 1, 0, 'Zero', 3, 4)));
        AddTurn(Turn(81));
        AddTurn(Turn(230, InitPacket(0, 2, 1, 'Zero', 3, 4)));
        AddTurn(Turn(231, InitPacket(0, 2, 2, 'Zero', 3, 4)));
        AddTurn(Turn(232));
        AddTurn(Turn(233));
      end;
    2:
      begin
        // serial line: the start is taken as soon as it arrives, and player 0 starts at tic 19
        Result := Empty('start: player 1 of 2, serial', 1, 2, NET_SERIAL, 'Serial');
        AddTurn(Turn(75));
        AddTurn(Turn(90, InitPacket(0, 2, 1, 'Host', 3, 1)));
        AddTurn(Turn(91, InitPacket(0, 2, 2, 'Host', 3, 1)));
        AddTurn(Turn(92));
      end;
    3:
      begin
        Result := Empty('start: player 0 of 2, modem', 0, 2, NET_MODEM, 'Host');
        AddTurn(Turn(71));
        AddTurn(Turn(72, InitPacket(1, 2, 0, 'Guest', 3, 2)));
        AddTurn(Turn(212));
        AddTurn(Turn(213));
        AddTurn(Turn(214, InitPacket(1, 2, 0, 'Guest', 3, 2)));
        AddTurn(Turn(353));
        AddTurn(Turn(354));
      end;
    4:
      begin
        // another map: an error
        Result := Empty('start: another map', 0, 2, NET_IPX, 'Zero');
        AddTurn(Turn(71));
        AddTurn(Turn(72, InitPacket(1, 1, 0, 'One', 5, 2)));
        AddTurn(Turn(73));
      end;
    5:
      begin
        // nobody answers: the time-out
        Result := Empty('start: time-out', 0, 3, NET_IPX, 'Alone');
        AddTurn(Turn(100));
        AddTurn(Turn(20000));
        AddTurn(Turn(42000));
        AddTurn(Turn(42101));
        AddTurn(Turn(42102));
      end;
    6:
      begin
        // four players; packets that are not of the start are looked at and left
        Result := Empty('start: player 0 of 4, ipx', 0, 4, NET_IPX, 'ABCDEFGHIJKLMNOP');
        LTime := 71;
        for LIndex := 0 to 2 do
        begin
          AddTurn(Turn(LTime + LIndex * 3, InitPacket(LIndex + 1, 1 + LIndex, 0, NAMES[LIndex + 1], 3, 2)));
          AddTurn(Turn(LTime + LIndex * 3 + 1, Pack([EV_SOUND, 1, 100, 200, 7, 0])));
        end;
        AddTurn(Turn(212));
        for LIndex := 0 to 2 do
          AddTurn(Turn(213 + LIndex, InitPacket(LIndex + 1, 4, 0, NAMES[LIndex + 1], 3, 2)));
        AddTurn(Turn(353));
        AddTurn(Turn(354));
        AddTurn(Turn(355));
      end;
    7:
      begin
        // cancelled: the turns end before the start
        Result := Empty('start: cancelled', 2, 3, NET_IPX, 'Third');
        AddTurn(Turn(71));
        AddTurn(Turn(72, InitPacket(0, 1, 0, 'First', 3, 0)));
        AddTurn(Turn(73, InitPacket(1, 2, 0, 'Second', 3, 0)));
        AddTurn(Turn(212));
      end;
  else
    // a packet of the game that has the number of the players where "start" is: the original starts
    Result := Empty('start: a stray packet starts the game', 1, 2, NET_IPX, 'Stray');
    AddTurn(Turn(10));
    AddTurn(Turn(11, Pack([EV_SPAWN, 0, 2, 2, 77, 78, 79, 80, 81, 1, 0])));
    AddTurn(Turn(12));
    AddTurn(Turn(13));
  end;
  // after the start the game goes on a little
  if not (AIndex in [4, 5, 7]) then
  begin
    FSeed := 1000 + Cardinal(AIndex);
    Add(Result, Incoming(RandomPlayerPacket(EV_NEW_PLAYER, (Result.ConsolePlayer + 1) mod Result.NumPlayers)));
    Add(Result, Op(noGetData, []));
    Add(Result, Op(noClock, [40]));
    Add(Result, PlayerOp(500, 0, 2));
    Add(Result, Op(noSendPlayer, []));
  end;
end;

class function TNetScenarios.BuildHandMade(AIndex: Integer): TNetScenario;
var
  LIndex: Integer;
begin
  FSeed := 2000 + Cardinal(AIndex);
  case AIndex of
    0:
      begin
        // the bytes that stay in the buffer: a door after a trigger carries its angle, a new player the
        // holoscale of the player packet before, a text the tail of a longer one
        Result := Empty('stale bytes', 0, 2, NET_IPX, 'Zero');
        Add(Result, Op(noCheckHere, [1 shl 22, 2 shl 22, 777]));
        Add(Result, Op(noOpenDoor, [3 shl 22, 4 shl 22]));
        Add(Result, PlayerOp(500, 0, 1));
        Add(Result, Op(noSendPlayer, []));
        Add(Result, Op(noNewPlayer, []));
        Add(Result, Incoming(RandomPlayerPacket(EV_PLAYER, 1)));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noNewPlayer, []));
        Add(Result, Op(noOpenDoor, [5 shl 22, 6 shl 22]));
        Add(Result, Op(noMessage, []));
        Result.Ops[High(Result.Ops)].Text := 'a long line of text, 29 chars';
        Add(Result, Op(noMessage, []));
        Result.Ops[High(Result.Ops)].Text := 'short';
        Add(Result, Incoming(Pack([EV_MESSAGE, 1], TextField('hello there', 32, Ord('x')))));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noMessage, []));
        Result.Ops[High(Result.Ops)].Text := 'hi';
        Add(Result, Op(noSound, [12, 3, 100, 200]));
        Add(Result, Op(noOpenDoor, [7 shl 22, 8 shl 22]));
      end;
    1:
      begin
        // deaths: by a player, by this player, by a monster; the first character leaves a mine
        Result := Empty('frags', 1, 4, NET_IPX, 'One');
        for LIndex := 0 to 3 do
          if LIndex <> 1 then
            Add(Result, Incoming(Pack([EV_NEW_PLAYER, LIndex, (10 + LIndex) shl 22, 20 shl 22, 0, 64, 500,
              LIndex mod 3, 0, 0, 0, 48 shl 16, 0])));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noClock, [100]));
        Add(Result, Incoming(Pack([EV_FRAG, 0, 1])));
        Add(Result, Op(noGetData, []));
        Add(Result, Incoming(Pack([EV_FRAG, 2, 3])));
        Add(Result, Op(noGetData, []));
        Add(Result, Incoming(Pack([EV_FRAG, 3, 255])));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noDeath, [0]));
        Add(Result, Op(noDeath, [255]));
        Add(Result, Op(noDeath, [201]));
        Add(Result, Incoming(Pack([EV_NEW_PLAYER, 0, 11 shl 22, 21 shl 22, 0, 64, 500, 5, 0, 0, 0, 48 shl 16, 0])));
        Add(Result, Incoming(Pack([EV_FRAG, 0, 1])));
        Add(Result, Incoming(Pack([EV_QUIT, 0])));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noQuit, []));
      end;
    2:
      begin
        // the bonus item: told by player 0, twice; then told by this player
        Result := Empty('bonus item', 1, 2, NET_IPX, 'One');
        Add(Result, Incoming(Pack([EV_BONUS, 0, 9000, 2300, 10, 12, 4])));
        Add(Result, Op(noGetData, []));
        Add(Result, Incoming(Pack([EV_BONUS, 0, 12000, 3500, 30, 31, 0])));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noSetBonus, [5000, 2600, 7, 8, 2]));
        Add(Result, Op(noBonus, []));
        Add(Result, Incoming(Pack([EV_BONUS, 0, 100, 0, 1, 1, 1])));
        Add(Result, Incoming(Pack([EV_BONUS, 0, 200, 2000, 2, 2, 2])));
        Add(Result, Op(noGetData, []));
      end;
    3:
      begin
        // the warp jammer of another player: the generators go, one sprite in two is looked at
        Result := Empty('warp jammer', 0, 2, NET_IPX, 'Zero');
        Add(Result, Op(noClock, [1234]));
        for LIndex := 0 to 9 do
          if LIndex in [0, 1, 4, 7] then
            Add(Result, Op(noAddSprite, [S_GENSTART + LIndex, (5 + LIndex) shl 22, 9 shl 22]))
          else if LIndex = 8 then
            Add(Result, Op(noAddSprite, [S_GENERATOR, (5 + LIndex) shl 22, 9 shl 22]))
          else
            Add(Result, Op(noAddSprite, [S_MONSTER1, (5 + LIndex) shl 22, 9 shl 22]));
        for LIndex := 0 to 9 do
          Add(Result, Op(noMapSprite, [9 * 64 + 5 + LIndex, 40 + LIndex]));
        Add(Result, Incoming(Pack([EV_JAMMER, 1])));
        Add(Result, Op(noGetData, []));
        Add(Result, Incoming(Pack([EV_JAMMER, 1])));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noWarpJam, []));
      end;
    4:
      begin
        // items, doors, triggers, sounds, events, pause; packets of this same player and unknown ones are left
        Result := Empty('world events', 2, 3, NET_IPX, 'Two');
        Add(Result, Op(noMapSprite, [5 * 64 + 4, 77]));
        Add(Result, Op(noItemPickup, [4, 5]));
        Add(Result, Incoming(Pack([EV_ITEM, 0, 6, 7, 7 * 64 + 6, 143, 3])));
        Add(Result, Incoming(Pack([EV_DOOR, 1, 9 shl 22, 8 shl 22, 0])));
        Add(Result, Incoming(Pack([EV_TRIGGER, 1, 3 shl 22, 2 shl 22, 512])));
        Add(Result, Incoming(Pack([EV_SOUND, 0, 111, 222, 33, 4])));
        Add(Result, Incoming(Pack([EV_EVENT, 0, 42])));
        Add(Result, Incoming(Pack([EV_PAUSE, 1])));
        Add(Result, Op(noGetData, []));
        Add(Result, Incoming(Pack([EV_UNPAUSE, 1])));
        Add(Result, Incoming(Pack([EV_PAUSE, 2])));
        Add(Result, Incoming(Pack([0, 1, 5, 6])));
        Add(Result, Incoming(Pack([17, 1, 5, 6])));
        Add(Result, Incoming(InitPacket(1, 3, 3, 'late', 3, 2)));
        Add(Result, Op(noGetData, []));
        Add(Result, Op(noPause, []));
        Add(Result, Op(noUnPause, []));
        Add(Result, Op(noEvent, [9]));
        // a door packet cut after the player: x, y and angle are the ones of the sound that was sent before
        Add(Result, Op(noSound, [50, 1, 10 shl 22, 11 shl 22]));
        Add(Result, Incoming(Pack([EV_DOOR, 0])));
        Add(Result, Op(noGetData, []));
      end;
    5:
      begin
        // spawns: one sprite, the ring of 12 and the ring of 16
        Result := Empty('spawns', 0, 2, NET_IPX, 'Zero');
        Add(Result, Op(noSendSpawn, [505, 100, 200, 300, 400, 1500, -7, 1, 0]));
        Add(Result, Incoming(Pack([EV_SPAWN, 1, 507, 1 shl 22, 2 shl 22, 30, 40, 900, 12, 1, 1])));
        Add(Result, Incoming(Pack([EV_SPAWN, 1, S_BULLET18, 3 shl 22, 4 shl 22, 30, 40, 900, 12, 1, 1])));
        Add(Result, Incoming(Pack([EV_SPAWN, 1, S_SOULBULLET, 5 shl 22, 6 shl 22, 30, 40, 900, 12, 0, 1])));
        Add(Result, Op(noGetData, []));
      end;
  else
    // the walk of another player: the pictures of the steps, hit, firing, hologram, invisible; then the
    // nearest player
    Result := Empty('player pictures', 0, 3, NET_IPX, 'Zero');
    Add(Result, Incoming(Pack([EV_NEW_PLAYER, 1, 10 shl 22, 10 shl 22, 64 shl 16, 0, 500, 2, 0, 0, 0, 48 shl 16, 0])));
    Add(Result, Op(noGetData, []));
    for LIndex := 1 to 12 do
    begin
      Add(Result, Op(noClock, [LIndex * 13]));
      Add(Result, Incoming(Pack([EV_PLAYER, 1, (10 shl 22) + LIndex * 100000, 10 shl 22, 64 shl 16, LIndex * 10, 500,
        2, Ord(LIndex = 5) + 2 * Ord(LIndex = 9), 350 * Ord(LIndex = 11), 2, 48 shl 16, 4 * Ord(LIndex = 7)])));
      Add(Result, Op(noGetData, []));
    end;
    Add(Result, PlayerOp(500, 0, 0));
    Add(Result, Op(noSendPlayer, []));
    Add(Result, Op(noClosest, [10, 10]));
    Add(Result, Op(noClosest, [60, 60]));
    Add(Result, Incoming(Pack([EV_PLAYER, 1, 12 shl 22, 10 shl 22, 64 shl 16, 0, 0, 2, 0, 0, 0, 48 shl 16, 0])));
    Add(Result, Op(noGetData, []));
    Add(Result, Op(noClosest, [12, 10]));
  end;
end;

class function TNetScenarios.BuildRandom(ASeed: Integer): TNetScenario;
var
  LHasSprite: array[0..7] of Boolean;
  LStep, LKind, LPlayer, LCount, LClock, LValue, LA, LB, LC, LD, LE, LF, LG: Integer;
  LText: AnsiString;
begin
  FSeed := 77000 + Cardinal(ASeed) * 7919;
  LCount := 2 + Next(7);
  LPlayer := Next(LCount);
  LA := 1 + Next(3);
  LB := Next(8);
  Result := Empty(Format('random %d', [ASeed]), LPlayer, LCount, LA, NAMES[LB]);
  FillChar(LHasSprite, SizeOf(LHasSprite), 0);
  LClock := 0;
  for LStep := 0 to NET_SCENARIO_RANDOM_OPS - 1 do
  begin
    LClock := LClock + Next(9);
    Add(Result, Op(noClock, [LClock]));
    LKind := Next(40);
    case LKind of
      0..3:
        begin
          LA := Next(3) * 250;
          LB := 4 * Ord(Next(6) = 0);
          LC := Next(3);
          Add(Result, PlayerOp(LA, LB, LC));
          Add(Result, Op(noSendPlayer, []));
        end;
      4:
        begin
          Add(Result, PlayerOp(500, 0, 0));
          Add(Result, Op(noNewPlayer, []));
        end;
      5, 6:
        begin
          LValue := 500 + Next(40);
          LA := Fixed(60);
          LB := Fixed(60);
          LC := Next(100) shl 16;
          LD := Next(64) shl 16;
          LE := Next(1024);
          LF := Next(128) - 64;
          LG := Next(2);
          Add(Result, Op(noSendSpawn, [LValue, LA, LB, LC, LD, LE, LF, LG, Result.ConsolePlayer]));
        end;
      7:
        begin
          LA := Next(60);
          LB := Next(8);
          LC := Fixed(60);
          LD := Fixed(60);
          Add(Result, Op(noSound, [LA, LB, LC, LD]));
        end;
      8:
        begin
          // the tiles 61..63 are kept free for the bonus item (the original loops for ever on a tile in use)
          LA := Next(60);
          LB := Next(60);
          LC := 1 + Next(250);
          Add(Result, Op(noMapSprite, [LB * 64 + LA, LC]));
          Add(Result, Op(noItemPickup, [LA, LB]));
        end;
      9:
        begin
          LValue := Next(10);
          if LValue = 8 then
            LValue := 255
          else if LValue = 9 then
            LValue := 200 + Next(8);
          Add(Result, Op(noDeath, [LValue]));
        end;
      10:
        begin
          // somebody alive and visible is needed: this player says where it is first
          Add(Result, PlayerOp(250, 0, 0));
          Add(Result, Op(noSendPlayer, []));
          LA := Next(64);
          LB := Next(64);
          Add(Result, Op(noClosest, [LA, LB]));
        end;
      11:
        begin
          LA := Fixed(60);
          LB := Fixed(60);
          Add(Result, Op(noOpenDoor, [LA, LB]));
        end;
      12:
        begin
          LA := Fixed(60);
          LB := Fixed(60);
          LC := Next(1024);
          Add(Result, Op(noCheckHere, [LA, LB, LC]));
        end;
      13:
        begin
          LA := Next(20000);
          LB := 2000 + Next(8) * 300;
          LC := Next(64);
          LD := Next(64);
          LE := Next(8);
          Add(Result, Op(noSetBonus, [LA, LB, LC, LD, LE]));
          Add(Result, Op(noBonus, []));
        end;
      14:
        if Next(2) = 0 then
          Add(Result, Op(noPause, []))
        else
          Add(Result, Op(noUnPause, []));
      15:
        begin
          LText := AnsiString(Copy('the quick brown fox jumps over', 1, Next(30)));
          Add(Result, Op(noMessage, []));
          Result.Ops[High(Result.Ops)].Text := LText;
        end;
      16:
        if Next(4) = 0 then
          Add(Result, Op(noWarpJam, []))
        else
        begin
          LA := Next(256);
          Add(Result, Op(noEvent, [LA]));
        end;
      17:
        begin
          LA := S_GENSTART + Next(30);
          LB := Fixed(60);
          LC := Fixed(60);
          Add(Result, Op(noAddSprite, [LA, LB, LC]));
        end;
    else
      // a packet arrives
      LPlayer := Next(Result.NumPlayers);
      case Next(16) of
        0..3:
          Add(Result, Incoming(RandomPlayerPacket(EV_PLAYER, LPlayer)));
        4, 5:
          begin
            Add(Result, Incoming(RandomPlayerPacket(EV_NEW_PLAYER, LPlayer)));
            if LPlayer <> Result.ConsolePlayer then
              LHasSprite[LPlayer] := True;
          end;
        6:
          begin
            LValue := 500 + Next(40);
            LA := Fixed(60);
            LB := Fixed(60);
            LC := Next(100) shl 16;
            LD := Next(64) shl 16;
            LE := Next(1024);
            LF := Next(128) - 64;
            LG := Next(2);
            Add(Result, Incoming(Pack([EV_SPAWN, LPlayer, LValue, LA, LB, LC, LD, LE, LF, LG, LPlayer])));
          end;
        7:
          if LHasSprite[LPlayer] then
          begin
            LValue := Next(Result.NumPlayers + 2);
            if LValue = Result.NumPlayers then
              LValue := 255
            else if LValue > Result.NumPlayers then
              LValue := 200 + LPlayer;
            Add(Result, Incoming(Pack([EV_FRAG, LPlayer, LValue])));
            LHasSprite[LPlayer] := False;
          end
          else
            Add(Result, Incoming(Pack([EV_QUIT, LPlayer])));
        8:
          begin
            LA := Fixed(60);
            LB := Fixed(60);
            LC := Next(2);
            LD := Next(1024);
            if LC = 0 then
              Add(Result, Incoming(Pack([EV_DOOR, LPlayer, LA, LB, LD])))
            else
              Add(Result, Incoming(Pack([EV_TRIGGER, LPlayer, LA, LB, LD])));
          end;
        9:
          begin
            LA := Next(60);
            LB := Next(60);
            LC := 1 + Next(250);
            LD := Next(6);
            Add(Result, Incoming(Pack([EV_ITEM, LPlayer, LA, LB, LB * 64 + LA, LC, LD])));
          end;
        10:
          begin
            LA := Next(20000);
            LB := Next(4) * 1000;
            LC := 61 + Next(3);
            LD := 61 + Next(3);
            LE := Next(8);
            Add(Result, Incoming(Pack([EV_BONUS, LPlayer, LA, LB, LC, LD, LE])));
          end;
        11:
          begin
            LA := Fixed(60);
            LB := Fixed(60);
            LC := Next(60);
            LD := Next(8);
            Add(Result, Incoming(Pack([EV_SOUND, LPlayer, LA, LB, LC, LD])));
          end;
        12:
          begin
            LA := EV_PAUSE + Next(2);
            Add(Result, Incoming(Pack([LA, LPlayer])));
          end;
        13:
          if Next(3) = 0 then
            Add(Result, Incoming(Pack([EV_JAMMER, LPlayer])))
          else
          begin
            LA := Next(256);
            Add(Result, Incoming(Pack([EV_EVENT, LPlayer, LA])));
          end;
        14:
          begin
            LText := AnsiString(Copy('pack my box with five dozen jugs', 1, Next(30)));
            Add(Result, Incoming(Pack([EV_MESSAGE, LPlayer], TextField(LText, 32, Ord('#')))));
          end;
      else
        // an id that the game does not know, or a late packet of the start
        LA := UNKNOWN_IDS[Next(4)];
        LB := Next(1000);
        LC := Next(1000);
        Add(Result, Incoming(Pack([LA, LPlayer, LB, LC])));
      end;
      if Next(3) <> 0 then
        Add(Result, Op(noGetData, []));
    end;
  end;
  Add(Result, Op(noGetData, []));
end;

class function TNetScenarios.Count: Integer;
begin
  Result := START_COUNT + HAND_MADE_COUNT + NET_SCENARIO_RANDOM_COUNT;
end;

class function TNetScenarios.Build(AIndex: Integer): TNetScenario;
begin
  if AIndex < START_COUNT then
    Result := BuildStart(AIndex)
  else if AIndex < START_COUNT + HAND_MADE_COUNT then
    Result := BuildHandMade(AIndex - START_COUNT)
  else
    Result := BuildRandom(AIndex - START_COUNT - HAND_MADE_COUNT);
end;

end.
