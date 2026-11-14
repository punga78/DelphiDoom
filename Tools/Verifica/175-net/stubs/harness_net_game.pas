unit harness_net_game;
// Tools\Verifica\175-net: il resto del gioco come lo vede net.pas. Le variabili sono quelle di raven.pas,
// utils.pas, display.pas, r_public.pas e modplay.pas che net.pas legge e scrive; le routine scrivono quello che
// net.pas chiede (TNetScenarioRunner.Note*) e SpawnSprite fa uno sprite, come il finto del test della libreria.
// "greedcom" finto: HarnessNetInt fa quello che faceva l'interrupt del driver (CMD_SEND, CMD_GET).
{$Q-}
{$R-}

interface

uses
  SysUtils, Generics.Collections, protos_h, r_public_h, DelphiDoom.Tests.Greed.NetRunner;

type
  TUpdateWaitProc = procedure;

var
  // raven.pas, utils.pas, display.pas
  timecount: integer;
  specialeffect: integer;
  goalitem: integer;
  oldgoalitem: integer;
  gameloading: boolean;
  targx, targy, targz: fixed_t;
  player: player_t;
  BonusItem: bonus_t;
  newascii: boolean;
  lastascii: AnsiChar;
  // r_public.pas
  mapsprites: array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorpic: array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapeffects: array[0..MAPROWS * MAPCOLS - 1] of byte;
  firstscaleobj, lastscaleobj: scaleobj_t;
  // modplay.pas
  SC: SoundCard;
  // l'harness
  HarnessRunner: TNetScenarioRunner;
  HarnessUpdateWait: TUpdateWaitProc;
  HarnessIncoming: TQueue<TBytes>;
  HarnessSent: TList<TBytes>;
  HarnessRandomCalls: integer;
  HarnessGoalRefreshed: integer;

procedure HarnessReset;

procedure HarnessNetInt(const com: Pgreedcom_t);

function RF_GetSprite: Pscaleobj_t;

procedure RF_RemoveSprite(const spr: Pscaleobj_t);

function CA_GetNamedNum(const name: string): integer;

procedure DemandLoadMonster(const lump, num: integer);

function SpawnSprite(const value: integer; const x, y, z, zadj: fixed_t; const angle, angle2: integer;
  const active: boolean; const spawnid: integer): Pscaleobj_t;

procedure TryDoor(const x, y: fixed_t);

procedure CheckItems(const cx, cy: integer; const useit: boolean; const chartype: integer);

procedure SoundEffect(const n, variation: integer; const x, y: fixed_t);

procedure CheckHere(const useit: boolean; const x, y: fixed_t; const angle: integer);

procedure addscore(const n: integer);

procedure writemsg(const s: string);

procedure Event(const n: integer; const netsend: boolean);

function MS_RndT: integer;

procedure MS_Error(const fmt: string; const args: array of const);

procedure StartWait;

procedure UpdateWait;

procedure EndWait;

procedure INT_TimerHook(const p: pointer);

implementation

uses
  constant, DelphiDoom.Tests.Greed.NetScenarios;

const
  CMD_SEND = 1;
  MAX_DATA = 128;

procedure HarnessReset;
var
  s, n: Pscaleobj_t;
begin
  if HarnessIncoming = nil then
  begin
    HarnessIncoming := TQueue<TBytes>.Create;
    HarnessSent := TList<TBytes>.Create;
  end
  else
  begin
    s := firstscaleobj.next;
    while (s <> nil) and (s <> @lastscaleobj) do
    begin
      n := s.next;
      FreeMem(s);
      s := n;
    end;
  end;
  HarnessIncoming.Clear;
  HarnessSent.Clear;
  HarnessRandomCalls := 0;
  HarnessGoalRefreshed := 0;
  timecount := 0;
  specialeffect := 0;
  goalitem := 0;
  oldgoalitem := 0;
  gameloading := false;
  targx := 0;
  targy := 0;
  targz := 0;
  FillChar(player, SizeOf(player), 0);
  FillChar(BonusItem, SizeOf(BonusItem), 0);
  newascii := false;
  lastascii := #0;
  FillChar(mapsprites, SizeOf(mapsprites), 0);
  // ogni casella ha un pavimento e nessun effetto: la casella di un bonus e' libera se non ha uno sprite
  FillChar(floorpic, SizeOf(floorpic), 1);
  FillChar(mapeffects, SizeOf(mapeffects), 0);
  FillChar(firstscaleobj, SizeOf(firstscaleobj), 0);
  FillChar(lastscaleobj, SizeOf(lastscaleobj), 0);
  firstscaleobj.next := @lastscaleobj;
  lastscaleobj.prev := @firstscaleobj;
  // in r_public.pas e' nil: qui la sentinella punta a se stessa, cosi' il ciclo di JAMMEREVENTID (che avanza due
  // volte) si ferma in fondo alla lista invece di leggere un puntatore nullo
  lastscaleobj.next := @lastscaleobj;
end;

procedure HarnessNetInt(const com: Pgreedcom_t);
var
  b: TBytes;
  len: integer;
begin
  if com.command = CMD_SEND then
  begin
    if com.remotenode <> MAXPLAYERS then
      raise Exception.Create('harness: a packet that is not for everybody');
    SetLength(b, com.datalength);
    Move(com.data, b[0], com.datalength);
    HarnessSent.Add(b);
  end
  else
  begin
    if HarnessIncoming.Count = 0 then
      com.remotenode := -1
    else
    begin
      b := HarnessIncoming.Dequeue;
      len := Length(b);
      if len > MAX_DATA then
        len := MAX_DATA;
      if len > 0 then
        Move(b[0], com.data, len);
      com.remotenode := 1;
    end;
  end;
end;

function RF_GetSprite: Pscaleobj_t;
begin
  // come r_public.pas: in fondo alla lista, tutto a zero
  GetMem(result, SizeOf(scaleobj_t));
  FillChar(result^, SizeOf(scaleobj_t), 0);
  result.next := @lastscaleobj;
  result.prev := lastscaleobj.prev;
  lastscaleobj.prev := result;
  result.prev.next := result;
end;

procedure RF_RemoveSprite(const spr: Pscaleobj_t);
begin
  spr.next.prev := spr.prev;
  spr.prev.next := spr.next;
  FreeMem(spr);
end;

function CA_GetNamedNum(const name: string): integer;
var
  i: integer;
begin
  for i := 0 to MAXCHARTYPES - 1 do
    if SameText(string(charnames[i]), name) then
    begin
      result := TNetScenarios.CharacterLump(i);
      exit;
    end;
  raise Exception.Create('harness: lump ' + name);
end;

procedure DemandLoadMonster(const lump, num: integer);
begin
  HarnessRunner.NoteDemandLoad(lump, num);
end;

function SpawnSprite(const value: integer; const x, y, z, zadj: fixed_t; const angle, angle2: integer;
  const active: boolean; const spawnid: integer): Pscaleobj_t;
begin
  HarnessRunner.NoteSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid, gameloading);
  result := RF_GetSprite;
  result.typ := value;
  result.x := x;
  result.y := y;
  result.basepic := NET_SPAWN_PICTURE_BASE + value;
end;

procedure TryDoor(const x, y: fixed_t);
begin
  HarnessRunner.NoteTryDoor(x, y);
end;

procedure CheckItems(const cx, cy: integer; const useit: boolean; const chartype: integer);
begin
  HarnessRunner.NoteCheckItems(cx, cy, useit, chartype, mapsprites[(cy * MAPCOLS + cx) and (MAPROWS * MAPCOLS - 1)]);
end;

procedure SoundEffect(const n, variation: integer; const x, y: fixed_t);
begin
  HarnessRunner.NoteSound(n, variation, x, y);
end;

procedure CheckHere(const useit: boolean; const x, y: fixed_t; const angle: integer);
begin
  HarnessRunner.NoteCheckHere(useit, x, y, angle);
end;

procedure addscore(const n: integer);
begin
  HarnessRunner.NoteAddScore(n);
end;

procedure writemsg(const s: string);
begin
  HarnessRunner.NoteMessage(s);
end;

procedure Event(const n: integer; const netsend: boolean);
begin
  HarnessRunner.NoteEvent(n, netsend);
end;

function MS_RndT: integer;
begin
  result := TNetScenarios.RandomByte(HarnessRandomCalls);
  inc(HarnessRandomCalls);
end;

procedure MS_Error(const fmt: string; const args: array of const);
begin
  raise Exception.Create(Format(fmt, args));
end;

procedure StartWait;
begin
end;

procedure UpdateWait;
begin
  if Assigned(HarnessUpdateWait) then
    HarnessUpdateWait;
end;

procedure EndWait;
begin
end;

procedure INT_TimerHook(const p: pointer);
begin
end;

end.
