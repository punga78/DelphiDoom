// Tools\Verifica\175-net: il corpo di net.pas di xGreed RIPRISTINATO dal commento che segue "end." in
// Reference\xGreed\Greed\net.pas (righe 186-965). In xGreed quel codice e' un C tradotto a meta' che non compila
// e le routine vere sono vuote: qui ogni routine e' il testo del commento completato riga per riga nel minimo
// che serve a compilarlo (sintassi, sprintf -> Format, i nomi come stringhe C in un array a parte). Le strutture
// dei pacchetti sono quelle del commento, con l'allineamento a 4 byte di un compilatore C a 32 bit (ievent_t e
// mevent_t di 40 byte). Compila.ps1 lo mette dopo l'interfaccia ORIGINALE di net.pas. Non e' codice del gioco:
// e' il riferimento con cui si confronta TGreedNetSession.

const
  TICRATE = 70; // d_ints.pas

(**** TYPES ****)

type
  Pievent_t = ^ievent_t;
  ievent_t = packed record
    id: integer;
    playerid: integer;
    found: integer;
    start: integer;
    netname: array[0..12] of AnsiChar;
    pad: array[0..2] of byte;
    map: integer;
    difficulty: integer;
  end; // initialization

  Psevent_t = ^sevent_t;
  sevent_t = packed record
    id: integer;
    playerid: integer;
    value: integer;
    x: fixed_t;
    y: fixed_t;
    z: fixed_t;
    zadj: fixed_t;
    angle: integer;
    angle2: integer;
    active: integer;
    spawnid: integer;
  end; // spawn

  Pqevent_t = ^qevent_t;
  qevent_t = packed record
    id: integer;
    playerid: integer;
  end; // quit game

  Pdevent_t = ^devent_t;
  devent_t = packed record
    id: integer;
    playerid: integer;
    x, y: fixed_t;
    angle: integer;
  end; // door open (by player) / trigger flipped

  Pfevent_t = ^fevent_t;
  fevent_t = packed record
    id: integer;
    playerid: integer;
    bulletid: integer;
  end; // frag

  Pbevent_t = ^bevent_t;
  bevent_t = packed record
    id: integer;
    playerid: integer;
    time, score: integer;
    tilex, tiley: integer;
    num: integer;
  end; // bonus item spawn

  Pipevent_t = ^ipevent_t;
  ipevent_t = packed record
    id: integer;
    playerid: integer;
    tilex, tiley, mapspot: integer;
    typ, chartype: integer;
  end; // item pickup

  Peevent_t = ^eevent_t;
  eevent_t = packed record
    id: integer;
    playerid: integer;
    x, y: fixed_t;
    effect, variation: integer;
  end; // sound effect

  Pmevent_t = ^mevent_t;
  mevent_t = packed record
    id: integer;
    playerid: integer;
    message: array[0..29] of AnsiChar;
    pad: array[0..1] of byte;
  end;

(**** VARIABLES ****)

var
  pevent: Ppevent_t;
  sevent: Psevent_t;
  ievent: Pievent_t;
  qevent: Pqevent_t;
  devent: Pdevent_t;
  fevent: Pfevent_t;
  bevent: Pbevent_t;
  ipevent: Pipevent_t;
  eevent: Peevent_t;
  mevent: Pmevent_t;
  msg: string;
  playersprites: array[0..MAXPLAYERS - 1] of Pscaleobj_t;
  sprite_p, sprite2_p, temp_p: Pscaleobj_t;
  playermapspot: array[0..MAXPLAYERS - 1] of integer;
  pmapspot: integer;
  // netnames del C: char[13] con lo zero in fondo; netnames (string[13]) dell'interfaccia ne e' la copia
  cnames: array[0..MAXPLAYERS - 1, 0..12] of AnsiChar;

(**** FUNCTIONS ****)

procedure NETINT;
begin
  HarnessNetInt(greedcom);
end;

procedure strncpy12(dst, src: PAnsiChar);
var
  i: integer;
  ended: boolean;
begin
  ended := false;
  for i := 0 to 11 do
  begin
    if src[i] = #0 then
      ended := true;
    if ended then
      dst[i] := #0
    else
      dst[i] := src[i];
  end;
end;

procedure syncname(const n: integer);
begin
  netnames[n] := ShortString(AnsiString(PAnsiChar(@cnames[n])));
end;

function HarnessPlayerSprite(const n: integer): Pscaleobj_t;
begin
  result := playersprites[n];
end;

function HarnessPlayerMapSpot(const n: integer): integer;
begin
  result := playermapspot[n];
end;

procedure SpawnNewPlayer;
begin
  sprite_p := RF_GetSprite;
  playersprites[pevent.playerid] := sprite_p;
  sprite_p.rotate := rt_eight;
  sprite_p.basepic := CA_GetNamedNum(string(charnames[pevent.chartype]));
  DemandLoadMonster(sprite_p.basepic, 48);
  sprite_p.scale := 1;
  sprite_p.startpic := sprite_p.basepic;
  sprite_p.intelligence := 255;
  sprite_p.x := pevent.x;
  sprite_p.y := pevent.y;
  sprite_p.z := pevent.z;
  sprite_p.angle := pevent.angle;
  sprite_p.typ := S_NETPLAYER;
  sprite_p.hitpoints := 500;
  sprite_p.height := 60 * FRACUNIT;
  pmapspot := (sprite_p.y div FRACTILEUNIT) * MAPCOLS + (sprite_p.x div FRACTILEUNIT);
  playermapspot[pevent.playerid] := pmapspot;
  if mapsprites[pmapspot] = 0 then
    mapsprites[pmapspot] := SM_NETPLAYER;
end;


procedure NetInit(const addr: pointer);
begin
  greedcom := Pgreedcom_t(addr);
  if greedcom.id <> integer(GREEDCOM_ID) then
    MS_Error('Invalid ComData Address not  ID := $%X', [greedcom.id]);
  playernum := greedcom.consoleplayer;
  if greedcom.nettype = NETIPX then
  else if greedcom.nettype = NETSERIAL then
  else if greedcom.nettype = NETMODEM then
  else
    MS_Error('Unknown net type!', []);
  pevent := Ppevent_t(@greedcom.data);
  sevent := Psevent_t(@greedcom.data);
  ievent := Pievent_t(@greedcom.data);
  qevent := Pqevent_t(@greedcom.data);
  devent := Pdevent_t(@greedcom.data);
  fevent := Pfevent_t(@greedcom.data);
  bevent := Pbevent_t(@greedcom.data);
  ipevent := Pipevent_t(@greedcom.data);
  eevent := Peevent_t(@greedcom.data);
  mevent := Pmevent_t(@greedcom.data);
end;


procedure NetWaitStart;
var
  players, playersfound: array[0..MAXPLAYERS - 1] of integer;
  found, ready, i: integer;
  timeout, waittime: integer;
  scname: array[0..12] of AnsiChar;
begin
  INT_TimerHook(nil);
  StartWait;
  FillChar(players, SizeOf(players), 0);
  FillChar(playersfound, SizeOf(playersfound), 0);
  FillChar(scname, SizeOf(scname), 0);
  for i := 1 to length(SC.netname) do
    scname[i - 1] := SC.netname[i];
  strncpy12(@cnames[playernum], @scname);
  if cnames[playernum][10] = ' ' then
  begin
    i := 10;
    while (i > 0) and (cnames[playernum][i] = ' ') do
    begin
      cnames[playernum][i] := #0;
      dec(i);
    end;
  end;
  syncname(playernum);
  players[playernum] := 1; // found ourself
  found := 1;
  ready := 0;
  timeout := timecount + 42000; // 10 minute wait
  newascii := false;
  waittime := timecount + TICRATE;
  while true do
  begin
    UpdateWait;
    if timecount > timeout then
      MS_Error('Multiplayer synch time-out error', []);
    if newascii and (lastascii = #27) then
      MS_Error('Multiplay Cancelled', []);
    newascii := false;
    if timecount > waittime then
    begin
      found := 0;
      for i := 0 to greedcom.numplayers - 1 do
        if players[i] <> 0 then
          inc(found);                               // count how many we've found
      playersfound[playernum] := found;
      greedcom.command := CMD_SEND;
      greedcom.remotenode := MAXPLAYERS;           // broadcast
      greedcom.datalength := SizeOf(ievent_t);
      ievent.id := INITEVENTID;
      ievent.playerid := playernum;                 // tell who we are
      ievent.found := found;                        // tell how many we've found
      ievent.start := ready;                        // player 0 tells when to start
      ievent.map := player.map;
      ievent.difficulty := player.difficulty;
      strncpy12(@ievent.netname, @cnames[playernum]);
      NETINT;
      waittime := timecount + 140;
    end;
    if ievent.start = greedcom.numplayers then
      break;
    greedcom.command := CMD_GET;
    NETINT;
    if greedcom.remotenode = -1 then
      continue; // no broadcasts
    if ievent.id <> INITEVENTID then
      continue; // wrong packet id
    if (greedcom.nettype <> NETIPX) and (ievent.start = greedcom.numplayers) then
      break; // we can start now

    if ievent.playerid = 0 then
      player.difficulty := ievent.difficulty;

    if ievent.map <> player.map then
      MS_Error('Player #%d is playing a different map!', [ievent.playerid]);

    players[ievent.playerid] := 1;                  // found new player
    playersfound[ievent.playerid] := ievent.found; // how many they've found
    strncpy12(@cnames[ievent.playerid], @ievent.netname);
    syncname(ievent.playerid);
    if playernum = 0 then // player 0 checks for readiness
    begin
      ready := 0;
      for i := 0 to greedcom.numplayers - 1 do
        if playersfound[i] = greedcom.numplayers then
          inc(ready); // check everybody
    end;
  end;
  timecount := 0;
  greedcom.maxusage := 0;
  EndWait;
  NetNewPlayerData;
  INT_TimerHook(nil);
  if (greedcom.nettype <> NETIPX) and (greedcom.consoleplayer = 0) then
    timecount := 19;
  NetGetData;
end;


procedure NetGetData;
var
  i, angle, angleinc, guard: integer;
begin
  repeat
    greedcom.command := CMD_GET;
    NETINT;
    if greedcom.remotenode = -1 then
      exit;
    if pevent.playerid = playernum then
      continue;
    case pevent.id of
    PLAYEREVENTID:
      begin
        sprite_p := playersprites[pevent.playerid];
        if sprite_p = nil then
          continue;
        sprite_p.x := pevent.x;
        sprite_p.y := pevent.y;
        sprite_p.z := pevent.z - pevent.height;
        sprite_p.angle := pevent.angle;
        sprite_p.hitpoints := 500;
        pmapspot := playermapspot[pevent.playerid];
        if mapsprites[pmapspot] = SM_NETPLAYER then
          mapsprites[pmapspot] := 0;
        pmapspot := (sprite_p.y div FRACTILEUNIT) * MAPCOLS + (sprite_p.x div FRACTILEUNIT);
        if mapsprites[pmapspot] = 0 then
          mapsprites[pmapspot] := SM_NETPLAYER;
        playermapspot[pevent.playerid] := pmapspot;

        if pevent.status = 1 then // hit
        begin
          sprite_p.basepic := sprite_p.startpic + 32;
          sprite_p.modetime := timecount + 12;
        end
        else if pevent.status = 2 then // firing
        begin
          sprite_p.basepic := sprite_p.startpic + 24;
          sprite_p.modetime := timecount + 12;
          playerdata[pevent.playerid].x := -1; // so it draws the walk frame
        end;

        if timecount > sprite_p.modetime then
        begin
          if (playerdata[pevent.playerid].x <> pevent.x) or (playerdata[pevent.playerid].y <> pevent.y) then
          begin
            if sprite_p.movemode = 3 then
            begin
              sprite_p.movemode := 0;
              sprite_p.basepic := sprite_p.startpic;
            end
            else if sprite_p.movemode = 2 then
            begin
              sprite_p.basepic := sprite_p.startpic + 8; // midstep
              inc(sprite_p.movemode);
            end
            else
            begin
              inc(sprite_p.movemode);
              sprite_p.basepic := sprite_p.startpic + sprite_p.movemode * 8;
            end;
          end;
          sprite_p.modetime := timecount + 12;
        end;

        Move(pevent^, playerdata[pevent.playerid], SizeOf(pevent_t));

        if pevent.holopic <> 0 then
        begin
          sprite_p.basepic := pevent.holopic;
          sprite_p.scale := pevent.holoscale;
          sprite_p.rotate := rt_one;
        end;

        if pevent.specialeffect = SE_INVISIBILITY then
          sprite_p.specialtype := st_transparent
        else
          sprite_p.specialtype := st_none;
      end;
    SPAWNEVENTID:
      begin
        gameloading := true;
        if sevent.value = S_BULLET18 then
        begin
          angleinc := ANGLES div 12;
          angle := 0;
          for i := 0 to 11 do
          begin
            SpawnSprite(sevent.value, sevent.x, sevent.y, sevent.z, sevent.zadj, angle, sevent.angle2, sevent.active <> 0, sevent.spawnid);
            angle := angle + angleinc;
          end;
        end
        else if sevent.value = S_SOULBULLET then
        begin
          angleinc := ANGLES div 16;
          angle := 0;
          for i := 0 to 15 do
          begin
            SpawnSprite(sevent.value, sevent.x, sevent.y, sevent.z, sevent.zadj, angle, sevent.angle2, sevent.active <> 0, sevent.spawnid);
            angle := angle + angleinc;
          end;
        end
        else
          SpawnSprite(sevent.value, sevent.x, sevent.y, sevent.z, sevent.zadj, sevent.angle, sevent.angle2, sevent.active <> 0, sevent.spawnid);
        gameloading := false;
      end;
    DOOREVENTID:
      TryDoor(devent.x, devent.y);
    ITEMEVENTID:
      begin
        mapsprites[ipevent.mapspot] := ipevent.typ;
        CheckItems(ipevent.tilex, ipevent.tiley, false, ipevent.chartype);
        mapsprites[ipevent.mapspot] := 0;
      end;
    SOUNDEVENTID:
      SoundEffect(eevent.effect, eevent.variation, eevent.x, eevent.y);
    BONUSEVENTID:
      begin
        if BonusItem.score > 0 then
        begin
          sprite_p := firstscaleobj.next;
          while sprite_p <> @lastscaleobj do
          begin
            if sprite_p.typ = S_BONUSITEM then
            begin
              RF_RemoveSprite(sprite_p);
              mapsprites[BonusItem.mapspot] := 0;
              break;
            end;
            sprite_p := sprite_p.next;
          end;
          SpawnSprite(S_WARP, (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT, (BonusItem.tiley * MAPSIZE + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
        end;
        guard := 0;
        repeat
          BonusItem.tilex := bevent.tilex;
          BonusItem.tiley := bevent.tiley;
          BonusItem.mapspot := BonusItem.tiley * MAPCOLS + BonusItem.tilex;
          // dell'harness: il ciclo del commento non finisce mai se la casella non e' libera
          inc(guard);
          if guard > 1000 then
            MS_Error('harness: BONUSEVENTID loops for ever', []);
        until not ((floorpic[BonusItem.mapspot] = 0) or (mapsprites[BonusItem.mapspot] > 0) or (mapeffects[BonusItem.mapspot] and FL_FLOOR <> 0));
        BonusItem.score := bevent.score;
        BonusItem.time := bevent.time;
        BonusItem.num := bevent.num;
        BonusItem.name := randnames[BonusItem.num];
        BonusItem.sprite := SpawnSprite(S_BONUSITEM, (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT, (BonusItem.tiley * MAPSIZE + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
        SpawnSprite(S_WARP, (BonusItem.tilex * MAPSIZE + 32) * FRACUNIT, (BonusItem.tiley * MAPSIZE + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
        BonusItem.sprite.basepic := BonusItem.sprite.basepic + BonusItem.num;
        oldgoalitem := -1;
        writemsg('Bonus item located!');
      end;
    TRIGGEREVENTID:
      CheckHere(false, devent.x, devent.y, devent.angle);
    FRAGEVENTID:
      begin
        if fevent.bulletid < MAXPLAYERS then
        begin
          oldgoalitem := -1;
          inc(fragcount[fevent.bulletid]);
          goalitem := fevent.bulletid + 1;
        end;
        if playernum = fevent.bulletid then
        begin
          inc(player.frags[fevent.playerid]);
          addscore(5000);
          msg := Format('Fragged %s! %d of %d', [string(netnames[fevent.playerid]), player.frags[fevent.playerid], fragcount[playernum]]);
          writemsg(msg);
        end
        else if fevent.bulletid < MAXPLAYERS then
        begin
          msg := Format('%s fragged %s.', [string(netnames[fevent.bulletid]), string(netnames[fevent.playerid])]);
          writemsg(msg);
        end
        else
        begin
          msg := Format('%s was killed.', [string(netnames[fevent.playerid])]);
          writemsg(msg);
        end;

        sprite_p := playersprites[fevent.playerid];
        if sprite_p.startpic = CA_GetNamedNum(string(charnames[0])) then
        begin
          gameloading := true;  // do not transmit
          sprite2_p := SpawnSprite(S_TIMEMINE, sprite_p.x, sprite_p.y, 0, 0, 0, 0, false, playernum);
          gameloading := false;
          sprite2_p.basepic := sprite_p.startpic + 40;
          sprite_p.basepic := sprite_p.startpic + 40;
          sprite2_p.scale := 1;
          sprite_p.animation := 0 + (0 shl 1) + (0 shl 5) + (0 shl 9) + ANIM_SELFDEST;
        end
        else
        begin
          sprite_p.basepic := sprite_p.startpic + 40;
          sprite_p.animation := 0 + (0 shl 1) + (8 shl 5) + ((6 + (MS_RndT and 3)) shl 9);
        end;
        sprite_p.rotate := rt_one;
        sprite_p.heat := 0;
        sprite_p.active := false;
        sprite_p.moveSpeed := 0;
        sprite_p.hitpoints := 0;
        sprite_p.intelligence := 0;
        mapsprites[playermapspot[fevent.playerid]] := 0;
        playersprites[fevent.playerid] := nil;
      end;
    NEWPLAYEREVENTID:
      SpawnNewPlayer; // new player
    PAUSEEVENTID:
      netpaused := true;
    UNPAUSEEVENTID:
      netpaused := false;
    JAMMEREVENTID:
      begin
        // il "for" del commento avanza anche nel terzo campo, dopo che il corpo e' gia' avanzato
        sprite_p := firstscaleobj.next;
        while sprite_p <> @lastscaleobj do
        begin
          if (sprite_p.typ = S_GENERATOR) or ((sprite_p.typ >= S_GENSTART) and (sprite_p.typ <= S_GENEND)) then
          begin
            mapsprites[(sprite_p.y div FRACTILEUNIT) * MAPCOLS + (sprite_p.x div FRACTILEUNIT)] := 0;
            temp_p := sprite_p;
            sprite_p := sprite_p.next;
            RF_RemoveSprite(temp_p);
          end
          else
            sprite_p := sprite_p.next;
          sprite_p := sprite_p.next;
        end;
        msg := Format('%s activated Warp Jammer!', [string(netnames[qevent.playerid])]);
        writemsg(msg);
        netwarpjammer := true;
        netwarpjamtime := timecount + 70 * 60;
      end;
    EVENTEVENTID:
      Event(fevent.bulletid, false);
    QUITEVENTID:
      begin
        msg := Format('%s has left the game!', [string(netnames[qevent.playerid])]);
        writemsg(msg);
      end;
    MESSAGEEVENTID:
      begin
        msg := Format('%s: %s', [string(netnames[mevent.playerid]), string(AnsiString(PAnsiChar(@mevent.message)))]);
        writemsg(msg);
        SoundEffect(SN_NEXUS, 0, player.x, player.y);
      end;
    end;
  until false;
end;


procedure NetSendPlayerData;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := SizeOf(pevent_t);
  pevent.playerid := playernum;
  pevent.id := PLAYEREVENTID;
  pevent.x := player.x;
  pevent.y := player.y;
  pevent.z := player.z;
  pevent.angle := player.angle;
  pevent.angst := player.angst;
  pevent.height := player.height;
  pevent.chartype := player.chartype;
  pevent.status := player.status;
  pevent.holopic := player.holopic;
  pevent.holoscale := player.holoscale;
  pevent.specialeffect := specialeffect;
  player.status := 0;
  Move(pevent^, playerdata[playernum], SizeOf(pevent_t));
  NETINT;
end;


procedure NetNewPlayerData;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := SizeOf(pevent_t);
  pevent.playerid := playernum;
  pevent.id := NEWPLAYEREVENTID;
  pevent.x := player.x;
  pevent.y := player.y;
  pevent.z := player.z;
  pevent.angle := player.angle;
  pevent.angst := player.angst;
  pevent.height := player.height;
  pevent.chartype := player.chartype;
  pevent.status := player.status;
  pevent.holopic := player.holopic;
  pevent.specialeffect := specialeffect;
  player.status := 0;
  Move(pevent^, playerdata[playernum], SizeOf(pevent_t));
  NETINT;
end;


procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS; // broadcast
  greedcom.datalength := SizeOf(sevent_t);
  sevent.id := SPAWNEVENTID;
  sevent.value := value;
  sevent.x := x;
  sevent.y := y;
  sevent.z := z;
  sevent.zadj := zadj;
  sevent.angle := angle;
  sevent.angle2 := angle2;
  sevent.active := ord(active);
  sevent.spawnid := spawnid;
  sevent.playerid := playernum;
  NETINT;
end;


procedure NetQuitGame;
begin
  NetDeath(255);
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(qevent_t);
  qevent.id := QUITEVENTID;
  qevent.playerid := playernum;
  NETINT;
end;


procedure NetOpenDoor(const x, y: fixed_t);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(devent_t);
  devent.id := DOOREVENTID;
  devent.playerid := playernum;
  devent.x := x;
  devent.y := y;
  NETINT;
end;


procedure NetDeath(const bulletid: integer);
var
  str1: string;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(fevent_t);
  fevent.id := FRAGEVENTID;
  fevent.playerid := playernum;
  fevent.bulletid := bulletid;
  if fevent.bulletid < MAXPLAYERS then
  begin
    oldgoalitem := -1;
    inc(fragcount[bulletid]);
    goalitem := bulletid + 1;
    str1 := Format('You were fragged by %s!', [string(netnames[fevent.bulletid])]);
    writemsg(str1);
  end;
  NETINT;
end;


procedure NetItemPickup(const x, y: integer);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(ipevent_t);
  ipevent.id := ITEMEVENTID;
  ipevent.playerid := playernum;
  ipevent.tilex := x;
  ipevent.tiley := y;
  ipevent.mapspot := y * MAPCOLS + x;
  ipevent.typ := mapsprites[ipevent.mapspot];
  ipevent.chartype := player.chartype;
  NETINT;
end;


procedure NetBonusItem;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(bevent_t);
  bevent.id := BONUSEVENTID;
  bevent.playerid := playernum;
  bevent.time := BonusItem.time;
  bevent.score := BonusItem.score;
  bevent.tilex := BonusItem.tilex;
  bevent.tiley := BonusItem.tiley;
  bevent.num := BonusItem.num;
  NETINT;
end;


procedure NetGetClosestPlayer(const sx, sy: integer);
var
  mindist, minplayer, dist: integer;
  i, px, py: integer;
begin
  minplayer := -1;
  mindist := $7FFFFFFF;
  for i := 0 to greedcom.numplayers - 1 do
    if (playerdata[i].angst <> 0) and (playerdata[i].specialeffect <> SE_INVISIBILITY) then
    // gotta be alive and visible
    begin
      px := playerdata[i].x div FRACTILEUNIT;
      py := playerdata[i].y div FRACTILEUNIT;
      dist := (px - sx) * (px - sx) + (py - sy) * (py - sy);
      if dist < mindist then
      begin
        mindist := dist;
        minplayer := i;
      end;
    end;
  targx := playerdata[minplayer].x;
  targy := playerdata[minplayer].y;
  targz := playerdata[minplayer].z;
end;


procedure NetPause;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(qevent_t);
  qevent.id := PAUSEEVENTID;
  qevent.playerid := playernum;
  NETINT;
end;


procedure NetUnPause;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(qevent_t);
  qevent.id := UNPAUSEEVENTID;
  qevent.playerid := playernum;
  NETINT;
end;


procedure NetCheckHere(const centerx, centery: fixed_t; const angle: integer);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(devent_t);
  devent.id := TRIGGEREVENTID;
  devent.playerid := playernum;
  devent.x := centerx;
  devent.y := centery;
  devent.angle := angle;
  NETINT;
end;


procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(eevent_t);
  eevent.id := SOUNDEVENTID;
  eevent.playerid := playernum;
  eevent.x := x;
  eevent.y := y;
  eevent.variation := variation;
  eevent.effect := n;
  NETINT;
end;


procedure NetWarpJam;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(qevent_t);
  qevent.id := JAMMEREVENTID;
  qevent.playerid := playernum;
  NETINT;
end;


procedure NetEvent(const n: integer);
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(fevent_t);
  fevent.id := EVENTEVENTID;
  fevent.playerid := playernum;
  fevent.bulletid := n;
  NETINT;
end;


procedure NetSendMessage(const s: string);
var
  i: integer;
  a: AnsiString;
begin
  greedcom.command := CMD_SEND;
  greedcom.remotenode := MAXPLAYERS;
  greedcom.datalength := SizeOf(mevent_t);
  mevent.id := MESSAGEEVENTID;
  mevent.playerid := playernum;
  // strcpy(mevent.message, s)
  a := AnsiString(s);
  for i := 1 to length(a) do
    mevent.message[i - 1] := a[i];
  mevent.message[length(a)] := #0;
  NETINT;
end;


procedure HarnessClearNet;
begin
  FillChar(playersprites, SizeOf(playersprites), 0);
  FillChar(playermapspot, SizeOf(playermapspot), 0);
  FillChar(cnames, SizeOf(cnames), 0);
  playernum := 1;
  greedcom := nil;
end;
