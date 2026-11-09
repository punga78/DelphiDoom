// TEMPORARY HARNESS of issue #154 (not for the build of the game): runs the OLD code of the platform
// thinkers (copied as it was before Libs\Thinkers) next to the NEW library on the live state of the
// game, for every tic of every platform and for every platform that is made. See docs\RUN-154.md.
//
// The engine side effects are replaced on both sides by the same deterministic stub (PP_World): a
// small T_MovePlane on a COPY of the sector (with a crush every now and then), the sounds and the
// removal written down. For each call: copy of the thinker and of its sector (twice) -> old code on
// the first copy -> library machine (with the stub as host) on the second -> compare the fields of
// the thinker, the floor, the events and the random index. Then the real code runs on the real
// thinker as usual. A report is written to plat_parity.txt on exit.

{$I Doom32.inc}

unit plat_parity;

interface

uses
  d_delphi,
  r_defs,
  p_spec;

type
  TPPPlatProc = procedure(plat: Pplat_t);

{$IFNDEF HEXEN}
procedure PP_PlatRaise(plat: Pplat_t; NewProc: TPPPlatProc);
procedure PP_SetupBegin(sec: Psector_t; plat: Pplat_t);
procedure PP_SetupEnd(plat: Pplat_t; _type: plattype_e; picture, amount: integer);
{$ENDIF}
procedure PP_UdmfPlatRaise(plat: Pplat_t; NewProc: TPPPlatProc);
procedure PP_UdmfSetupBegin(sec: Psector_t; plat: Pplat_t);
procedure PP_UdmfSetupEnd(plat: Pplat_t; _type: plattype_e; args: d_delphi.PByteArray);

implementation

uses
  SysUtils,
  Classes,
  m_base,
  m_fixed,
  p_tick,
  doomdef,
  tables,
  DelphiDoom.Thinkers.Teleport.Geometry,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Engine.Light.Services,
{$IFDEF DOOM}
  g_game,
{$ENDIF}
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf,
  DelphiDoom.Thinkers.Platform.Games,
  DelphiDoom.Thinkers.Platform.Factory,
  DelphiDoom.Engine.Plat.Thinker;

const
  KIND_CLASSIC = 0;
  KIND_SETUP = 1;
  KIND_UDMF = 2;
  KIND_UDMF_SETUP = 3;
  KIND_TELEPORT = 4;
  KIND_NAMES: array[0..4] of string = ('classic tic', 'classic setup', 'scripted tic',
    'scripted setup', 'teleport arithmetic');

var
  pp_total: array[0..4] of integer;
  pp_bad: array[0..4] of integer;
  pp_log: TextFile;
  pp_logopen: boolean = false;

procedure PP_EnsureSelfTest; forward;

procedure PP_Open;
begin
  if not pp_logopen then
  begin
    AssignFile(pp_log, 'plat_parity.txt');
    Rewrite(pp_log);
    pp_logopen := true;
  end;
end;

procedure PP_Account(kind: integer; same: boolean; const what: string);
begin
  inc(pp_total[kind]);
  if not same then
  begin
    inc(pp_bad[kind]);
    if pp_bad[kind] <= 20 then
    begin
      PP_Open;
      writeln(pp_log, 'MISMATCH ', KIND_NAMES[kind], ' leveltime=', leveltime, ' ', what);
    end;
  end;
end;

//==============================================================================
// the stub that stands for the engine on both sides
//==============================================================================
type
  TPPWorld = class(TObject, IPlatHost, IPlatSurroundings)
  public
    Events: TStringList;
    Real: Psector_t;
    Removed: boolean;
    constructor Create(AReal: Psector_t);
    destructor Destroy; override;
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function OldMovePlane(sector: Psector_t; speed, dest: fixed_t; crush: boolean; dir: integer): result_e;
    procedure Log(const s: string);
    // IPlatHost
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      ADirection: Integer): TPlatMoveResult;
    function GetFloorHeight(ASector: Pointer): Integer;
    procedure PlaySound(ASector: Pointer; ASound: TPlatSound);
    function GetLevelTime: Integer;
    function IsModernEngine: Boolean;
    procedure RemovePlat(APlat: Pointer);
    // IPlatSurroundings
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
    function GetCeilingHeight(ASector: Pointer): Integer;
    procedure SetFloorPicture(ASector: Pointer; APicture: Integer);
    procedure ClearSpecial(ASector: Pointer);
  end;

constructor TPPWorld.Create(AReal: Psector_t);
begin
  inherited Create;
  Events := TStringList.Create;
  Real := AReal;
end;

destructor TPPWorld.Destroy;
begin
  Events.Free;
  inherited Destroy;
end;

function TPPWorld.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := HResult($80004002);
end;

function TPPWorld._AddRef: Integer;
begin
  Result := -1;
end;

function TPPWorld._Release: Integer;
begin
  Result := -1;
end;

procedure TPPWorld.Log(const s: string);
begin
  Events.Add(s);
end;

// The same small model for both sides: a plane that goes up is crushed once in a while
function TPPWorld.OldMovePlane(sector: Psector_t; speed, dest: fixed_t; crush: boolean; dir: integer): result_e;
begin
  Log(Format('move %d %d %s %d', [speed, dest, BoolToStr(crush, true), dir]));
  result := {$IFDEF HEXEN}RES_OK{$ELSE}ok{$ENDIF};
  if dir < 0 then
  begin
    if sector.floorheight - speed < dest then
    begin
      sector.floorheight := dest;
      result := {$IFDEF HEXEN}RES_PASTDEST{$ELSE}pastdest{$ENDIF};
    end
    else
      sector.floorheight := sector.floorheight - speed;
  end
  else
  begin
    if leveltime mod 61 = 17 then
      result := {$IFDEF HEXEN}RES_CRUSHED{$ELSE}crushed{$ENDIF}
    else if sector.floorheight + speed > dest then
    begin
      sector.floorheight := dest;
      result := {$IFDEF HEXEN}RES_PASTDEST{$ELSE}pastdest{$ENDIF};
    end
    else
      sector.floorheight := sector.floorheight + speed;
  end;
end;

function TPPWorld.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
  ADirection: Integer): TPlatMoveResult;
var
  r: result_e;
begin
  r := OldMovePlane(Psector_t(ASector), ASpeed, ADestination, ACrush, ADirection);
  case r of
    {$IFDEF HEXEN}RES_CRUSHED{$ELSE}crushed{$ENDIF}:
      Result := TPlatMoveResult.Crushed;
    {$IFDEF HEXEN}RES_PASTDEST{$ELSE}pastdest{$ENDIF}:
      Result := TPlatMoveResult.PastDestination;
  else
    Result := TPlatMoveResult.Ok;
  end;
end;

function TPPWorld.GetFloorHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).floorheight;
end;

procedure TPPWorld.PlaySound(ASector: Pointer; ASound: TPlatSound);
begin
  case ASound of
    TPlatSound.Move: Log('sound move');
    TPlatSound.Start: Log('sound start');
    TPlatSound.Stop: Log('sound stop');
  end;
end;

function TPPWorld.GetLevelTime: Integer;
begin
  Result := leveltime;
end;

function TPPWorld.IsModernEngine: Boolean;
begin
{$IFDEF DOOM}
  Result := G_PlayingEngineVersion > VERSION115;
{$ELSE}
  Result := true;
{$ENDIF}
end;

procedure TPPWorld.RemovePlat(APlat: Pointer);
begin
  Removed := true;
  Log('remove');
end;

function TPPWorld.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindLowestFloorSurrounding(Real);
end;

function TPPWorld.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindHighestFloorSurrounding(Real);
end;

function TPPWorld.NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
begin
  Result := P_FindNextHighestFloor(Real, AHeight);
end;

function TPPWorld.GetCeilingHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).ceilingheight;
end;

procedure TPPWorld.SetFloorPicture(ASector: Pointer; APicture: Integer);
begin
  Psector_t(ASector).floorpic := SmallInt(APicture);
  Log('picture ' + IntToStr(APicture));
end;

procedure TPPWorld.ClearSpecial(ASector: Pointer);
begin
  Psector_t(ASector).special := 0;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  Psector_t(ASector).oldspecial := 0;
{$IFEND}
  Log('clear special');
end;

//==============================================================================
// the comparison of two copies of a thinker
//==============================================================================
function SamePlat(a, b: Pplat_t; classic: boolean): boolean;
begin
  result := (a.speed = b.speed) and (a.low = b.low) and (a.high = b.high) and (a.wait = b.wait) and
    (a.count = b.count) and (a.crush = b.crush) and (a.tag = b.tag) and
    (a.sector.floorheight = b.sector.floorheight) and (a.sector.floorpic = b.sector.floorpic) and
    (a.sector.special = b.sector.special) and (a.status = b.status);
end;

function DescribePlat(p: Pplat_t): string;
begin
  result := Format('speed %d low %d high %d wait %d count %d crush %s status %d floor %d pic %d special %d',
    [p.speed, p.low, p.high, p.wait, p.count, BoolToStr(p.crush, true), Ord(p.status),
     p.sector.floorheight, p.sector.floorpic, p.sector.special]);
end;

{$IFNDEF HEXEN}

//==============================================================================
// the old classic bodies (T_PlatRaise and the type switch of EV_DoPlat of the three games)
//==============================================================================
procedure Old_PlatRaise(w: TPPWorld; plat: Pplat_t);
var
  res: result_e;
begin
  case plat.status of
    up:
      begin
        res := w.OldMovePlane(plat.sector, plat.speed, plat.high, plat.crush, 1);

        if (plat._type = raiseAndChange) or (plat._type = raiseToNearestAndChange)
{$IFDEF STRIFE}
           or (plat._type = slowDWUS)
{$ENDIF}
        then
        begin
          if leveltime and 7 = 0 then
            w.Log('sound move');
        end;

        if (res = crushed) and not plat.crush then
        begin
          plat.count := plat.wait;
          plat.status := down;
          w.Log('sound start');
        end
        else
        begin
          if res = pastdest then
          begin
{$IFNDEF HERETIC}
            if plat._type = toggleUpDn then
            begin
              plat.oldstatus := plat.status;
              plat.status := in_stasis;
            end
            else
{$ENDIF}
            begin
              plat.count := plat.wait;
              plat.status := waiting;
              w.Log('sound stop');
            end;

            case plat._type of
              blazeDWUS,
              downWaitUpStay,
              raiseAndChange,
{$IFNDEF HERETIC}
              genLift,
{$ENDIF}
{$IFDEF STRIFE}
              slowDWUS,
{$ENDIF}
              raiseToNearestAndChange:
                w.RemovePlat(nil);
            end;
          end;
        end;
      end;

    down:
      begin
        res := w.OldMovePlane(plat.sector, plat.speed, plat.low, false, -1);

{$IFDEF STRIFE}
        if plat._type = slowDWUS then
          if leveltime and 7 = 0 then
            w.Log('sound move');
{$ENDIF}

        if res = pastdest then
        begin
{$IFNDEF HERETIC}
          if plat._type = toggleUpDn then
          begin
            plat.oldstatus := plat.status;
            plat.status := in_stasis;
          end
          else
{$ENDIF}
          begin
            plat.count := plat.wait;
            plat.status := waiting;
            w.Log('sound stop');
          end;

{$IFDEF DOOM}
          if G_PlayingEngineVersion > VERSION115 then
            if plat._type in [raiseAndChange, raiseToNearestAndChange] then
              w.RemovePlat(nil);
{$ENDIF}
{$IFDEF STRIFE}
          if plat._type in [raiseAndChange, raiseToNearestAndChange, upWaitDownStay] then
            w.RemovePlat(nil);
{$ENDIF}
        end;
      end;

    waiting:
      begin
        plat.count := plat.count - 1;
        if plat.count = 0 then
        begin
          if plat.sector.floorheight = plat.low then
            plat.status := up
          else
            plat.status := down;
          w.Log('sound start');
        end;
      end;
  end;
end;

// the type switch of EV_DoPlat: low is the floor of the sector first (Doom and Strife)
procedure Old_Setup(w: TPPWorld; plat: Pplat_t; sec: Psector_t; _type: plattype_e;
  picture, amount: integer);
begin
  plat.crush := false;
{$IFNDEF HERETIC}
  plat.low := sec.floorheight;
{$ENDIF}

  case _type of
    raiseToNearestAndChange:
      begin
        plat.speed := PLATSPEED div 2;
        sec.floorpic := picture;
        w.Log('picture ' + IntToStr(picture));
        plat.high := P_FindNextHighestFloor(w.Real, sec.floorheight);
        plat.wait := 0;
        plat.status := up;
        sec.special := 0;
{$IFNDEF HERETIC}
        sec.oldspecial := 0;
{$ENDIF}
        w.Log('clear special');
        w.Log('sound move');
      end;

    raiseAndChange:
      begin
        plat.speed := PLATSPEED div 2;
        sec.floorpic := picture;
        w.Log('picture ' + IntToStr(picture));
        plat.high := sec.floorheight + amount * FRACUNIT;
        plat.wait := 0;
        plat.status := up;
        w.Log('sound move');
      end;

{$IFDEF STRIFE}
    upWaitDownStay:
      begin
        plat.speed := PLATSPEED * 4;
        plat.high := P_FindNextHighestFloor(w.Real, sec.floorheight);
        plat.low := sec.floorheight;
        plat.wait := TICRATE * PLATWAIT;
        plat.status := up;
        w.Log('sound start');
      end;

    slowDWUS:
      begin
        plat.speed := PLATSPEED;
        plat.low := P_FindLowestFloorSurrounding(w.Real);
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := TICRATE * (PLATWAIT * 10);
        plat.status := down;
        w.Log('sound start');
      end;
{$ENDIF}

    downWaitUpStay:
      begin
        plat.speed := PLATSPEED * 4;
        plat.low := P_FindLowestFloorSurrounding(w.Real);
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := TICRATE * PLATWAIT;
        plat.status := down;
        w.Log('sound start');
      end;

    blazeDWUS:
      begin
        plat.speed := PLATSPEED * 8;
        plat.low := P_FindLowestFloorSurrounding(w.Real);
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := TICRATE * PLATWAIT;
        plat.status := down;
        w.Log('sound start');
      end;

    perpetualRaise:
      begin
        plat.speed := PLATSPEED;
        plat.low := P_FindLowestFloorSurrounding(w.Real);
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := P_FindHighestFloorSurrounding(w.Real);
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.wait := TICRATE * PLATWAIT;
        plat.status := plat_e(LightRandom.NextPlay and 1);
        w.Log('sound start');
      end;

{$IFNDEF HERETIC}
    toggleUpDn:
      begin
        plat.speed := PLATSPEED;
        plat.wait := TICRATE * PLATWAIT;
        plat.crush := true;
        plat.low := sec.ceilingheight;
        plat.high := sec.floorheight;
        plat.status := down;
      end;
{$ENDIF}
  end;
end;

var
  pp_setup_sector: sector_t;
  pp_setup_plat: plat_t;

procedure PP_SetupBegin(sec: Psector_t; plat: Pplat_t);
begin
  PP_EnsureSelfTest;
  pp_setup_sector := sec^;
  pp_setup_plat := plat^;
end;

procedure PP_SetupEnd(plat: Pplat_t; _type: plattype_e; picture, amount: integer);
var
  oldsec, newsec: sector_t;
  oldplat, newplat: plat_t;
  oldworld, newworld: TPPWorld;
  machine: IPlatMachine;
  game: TPlatGame;
  state: TPlatState;
  idxafter, idx0, idxold, idxnew: integer;
begin
  if not TPlatGames.TryFromName(_GAME, game) then
    exit;
  idxafter := LightRandom.PlayIndex;
  // the old code, on a copy of the state before the real setup
  oldsec := pp_setup_sector;
  oldplat := pp_setup_plat;
  oldplat.sector := @oldsec;
  oldworld := TPPWorld.Create(plat.sector);
  newworld := TPPWorld.Create(plat.sector);
  try
    idx0 := idxafter;
    // the real setup used one random number (and only the perpetual kind does): go back to the start
    if _type = perpetualRaise then
      idx0 := (idxafter + 255) and 255;
    LightRandom.PlayIndex := idx0;
    Old_Setup(oldworld, @oldplat, @oldsec, _type, picture, amount);
    idxold := LightRandom.PlayIndex;
    // the library, on another copy of the same state
    newsec := pp_setup_sector;
    newplat := pp_setup_plat;
    newplat.sector := @newsec;
    machine := TPlatFactory.CreateMachine(game, newworld, newworld, LightRandom);
    LightRandom.PlayIndex := idx0;
    PlatLoadState(@newplat, state);
    machine.Configure(@newsec, PlatKindOf(_type), picture, amount, state);
    PlatStoreState(@newplat, state);
    idxnew := LightRandom.PlayIndex;
    LightRandom.PlayIndex := idxafter;
    machine := nil;
    PP_Account(KIND_SETUP, SamePlat(@oldplat, @newplat, true) and (idxold = idxnew) and
      (oldworld.Events.Text = newworld.Events.Text) and
      (idxnew = idxafter), 'type ' + IntToStr(Ord(_type)) + ' old: ' + DescribePlat(@oldplat) +
      ' idx ' + IntToStr(idxold) + ' new: ' + DescribePlat(@newplat) + ' idx ' + IntToStr(idxnew));
  finally
    newworld.Free;
    oldworld.Free;
  end;
end;

procedure PP_PlatRaise(plat: Pplat_t; NewProc: TPPPlatProc);
var
  oldplat, newplat: plat_t;
  oldsec, newsec: sector_t;
  oldworld, newworld: TPPWorld;
  machine: IPlatMachine;
  game: TPlatGame;
  state: TPlatState;
begin
  if TPlatGames.TryFromName(_GAME, game) then
  begin
    oldsec := plat.sector^;
    newsec := plat.sector^;
    oldplat := plat^;
    newplat := plat^;
    oldplat.sector := @oldsec;
    newplat.sector := @newsec;
    oldworld := TPPWorld.Create(plat.sector);
    newworld := TPPWorld.Create(plat.sector);
    try
      Old_PlatRaise(oldworld, @oldplat);
      machine := TPlatFactory.CreateMachine(game, newworld, newworld, LightRandom);
      PlatLoadState(@newplat, state);
      machine.Tick(nil, @newsec, PlatKindOf(newplat._type), state);
      PlatStoreState(@newplat, state);
      machine := nil;
      PP_Account(KIND_CLASSIC, SamePlat(@oldplat, @newplat, true) and
        (oldworld.Events.Text = newworld.Events.Text) and (oldworld.Removed = newworld.Removed),
        'type ' + IntToStr(Ord(newplat._type)) + ' old: ' + DescribePlat(@oldplat) + ' events [' +
        oldworld.Events.CommaText + '] new: ' + DescribePlat(@newplat) + ' events [' +
        newworld.Events.CommaText + ']');
    finally
      newworld.Free;
      oldworld.Free;
    end;
  end;
  // the real code runs as usual
  NewProc(plat);
end;

{$ENDIF}

//==============================================================================
// the scripted platforms (all games)
//==============================================================================
procedure Old_UdmfPlatRaise(w: TPPWorld; plat: Pplat_t);
var
  res: result_e;
begin
  case plat.status of
    PLAT_UP:
      begin
        res := w.OldMovePlane(plat.sector, plat.speed, plat.high, plat.crush, 1);
        if (res = {$IFDEF HEXEN}RES_CRUSHED{$ELSE}crushed{$ENDIF}) and not plat.crush then
        begin
          plat.count := plat.wait;
          plat.status := PLAT_DOWN;
          w.Log('sound start');
        end
        else if res = {$IFDEF HEXEN}RES_PASTDEST{$ELSE}pastdest{$ENDIF} then
        begin
          plat.count := plat.wait;
          plat.status := PLAT_WAITING;
          w.Log('sound stop');
          if (plat._type = PLAT_DOWNWAITUPSTAY) or (plat._type = PLAT_DOWNBYVALUEWAITUPSTAY) or
            (plat._type = PLAT_DOWNWAITUPSTAYLIP) then
            w.RemovePlat(nil);
        end;
      end;
    PLAT_DOWN:
      begin
        res := w.OldMovePlane(plat.sector, plat.speed, plat.low, false, -1);
        if res = {$IFDEF HEXEN}RES_PASTDEST{$ELSE}pastdest{$ENDIF} then
        begin
          plat.count := plat.wait;
          plat.status := PLAT_WAITING;
          if (plat._type = PLAT_UPWAITDOWNSTAY) or (plat._type = PLAT_UPBYVALUEWAITDOWNSTAY) or
            (plat._type = PLAT_UPNEARESTWAITDOWNSTAY) then
            w.RemovePlat(nil);
          w.Log('sound stop');
        end;
      end;
    PLAT_WAITING:
      begin
        dec(plat.count);
        if plat.count <= 0 then
        begin
          if plat.sector.floorheight = plat.low then
            plat.status := PLAT_UP
          else
            plat.status := PLAT_DOWN;
          w.Log('sound start');
        end;
      end;
  end;
end;

procedure Old_UdmfSetup(w: TPPWorld; plat: Pplat_t; sec: Psector_t; _type: plattype_e; args: d_delphi.PByteArray);
begin
  plat.crush := false;
  plat.tag := args[0];
  plat.speed := args[1] * (FRACUNIT div 8);
  case _type of
    PLAT_DOWNWAITUPSTAY:
      begin
        plat.low := P_FindLowestFloorSurrounding(w.Real) + 8 * FRACUNIT;
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_DOWN;
      end;
    PLAT_DOWNWAITUPSTAYLIP:
      begin
        plat.low := P_FindLowestFloorSurrounding(w.Real) + args[3] * FRACUNIT;
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_DOWN;
      end;
    PLAT_DOWNBYVALUEWAITUPSTAY:
      begin
        plat.low := sec.floorheight - args[3] * 8 * FRACUNIT;
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_DOWN;
      end;
    PLAT_UPWAITDOWNSTAY:
      begin
        plat.high := P_FindHighestFloorSurrounding(w.Real);
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.low := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_UP;
      end;
    PLAT_UPNEARESTWAITDOWNSTAY:
      begin
        plat.high := P_FindNextHighestFloor(w.Real, sec.floorheight);
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.low := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_UP;
      end;
    PLAT_UPBYVALUEWAITDOWNSTAY:
      begin
        plat.high := sec.floorheight + args[3] * 8 * FRACUNIT;
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.low := sec.floorheight;
        plat.wait := args[2];
        plat.status := PLAT_UP;
      end;
    PLAT_PERPETUALRAISE:
      begin
        plat.low := P_FindLowestFloorSurrounding(w.Real) + 8 * FRACUNIT;
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := P_FindHighestFloorSurrounding(w.Real);
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.wait := args[2];
        plat.status := plat_e((LightRandom.NextPlay and 1) + Ord(PLAT_UP));
      end;
    PLAT_PERPETUALRAISELIP:
      begin
        plat.low := P_FindLowestFloorSurrounding(w.Real) + args[3] * FRACUNIT;
        if plat.low > sec.floorheight then
          plat.low := sec.floorheight;
        plat.high := P_FindHighestFloorSurrounding(w.Real);
        if plat.high < sec.floorheight then
          plat.high := sec.floorheight;
        plat.wait := args[2];
        plat.status := plat_e((LightRandom.NextPlay and 1) + Ord(PLAT_UP));
      end;
  end;
end;

var
  pp_usetup_sector: sector_t;
  pp_usetup_plat: plat_t;

procedure PP_UdmfSetupBegin(sec: Psector_t; plat: Pplat_t);
begin
  PP_EnsureSelfTest;
  pp_usetup_sector := sec^;
  pp_usetup_plat := plat^;
end;

procedure PP_UdmfSetupEnd(plat: Pplat_t; _type: plattype_e; args: d_delphi.PByteArray);
var
  oldsec, newsec: sector_t;
  oldplat, newplat: plat_t;
  oldworld, newworld: TPPWorld;
  machine: IUdmfPlatMachine;
  state: TPlatState;
  idxafter, idx0, idxold, idxnew: integer;
begin
  idxafter := LightRandom.PlayIndex;
  oldsec := pp_usetup_sector;
  oldplat := pp_usetup_plat;
  oldplat.sector := @oldsec;
  oldworld := TPPWorld.Create(plat.sector);
  newworld := TPPWorld.Create(plat.sector);
  try
    idx0 := idxafter;
    if (_type = PLAT_PERPETUALRAISE) or (_type = PLAT_PERPETUALRAISELIP) then
      idx0 := (idxafter + 255) and 255;
    LightRandom.PlayIndex := idx0;
    Old_UdmfSetup(oldworld, @oldplat, @oldsec, _type, args);
    idxold := LightRandom.PlayIndex;
    newsec := pp_usetup_sector;
    newplat := pp_usetup_plat;
    newplat.sector := @newsec;
    machine := TPlatFactory.CreateUdmfMachine(newworld, newworld, LightRandom);
    LightRandom.PlayIndex := idx0;
    UdmfPlatLoadState(@newplat, state);
    machine.Configure(@newsec, UdmfPlatKindOf(_type), args[0], args[1], args[2], args[3], state);
    UdmfPlatStoreState(@newplat, state);
    idxnew := LightRandom.PlayIndex;
    LightRandom.PlayIndex := idxafter;
    machine := nil;
    PP_Account(KIND_UDMF_SETUP, SamePlat(@oldplat, @newplat, false) and (idxold = idxnew) and
      (idxnew = idxafter), 'type ' + IntToStr(Ord(_type)) + ' old: ' + DescribePlat(@oldplat) +
      ' idx ' + IntToStr(idxold) + ' new: ' + DescribePlat(@newplat) + ' idx ' + IntToStr(idxnew));
  finally
    newworld.Free;
    oldworld.Free;
  end;
end;

procedure PP_UdmfPlatRaise(plat: Pplat_t; NewProc: TPPPlatProc);
var
  oldplat, newplat: plat_t;
  oldsec, newsec: sector_t;
  oldworld, newworld: TPPWorld;
  machine: IUdmfPlatMachine;
  state: TPlatState;
begin
  oldsec := plat.sector^;
  newsec := plat.sector^;
  oldplat := plat^;
  newplat := plat^;
  oldplat.sector := @oldsec;
  newplat.sector := @newsec;
  oldworld := TPPWorld.Create(plat.sector);
  newworld := TPPWorld.Create(plat.sector);
  try
    Old_UdmfPlatRaise(oldworld, @oldplat);
    machine := TPlatFactory.CreateUdmfMachine(newworld, newworld, LightRandom);
    UdmfPlatLoadState(@newplat, state);
    machine.Tick(nil, @newsec, UdmfPlatKindOf(newplat._type), state);
    UdmfPlatStoreState(@newplat, state);
    machine := nil;
    PP_Account(KIND_UDMF, SamePlat(@oldplat, @newplat, false) and
      (oldworld.Events.Text = newworld.Events.Text) and (oldworld.Removed = newworld.Removed),
      'type ' + IntToStr(Ord(newplat._type)) + ' old: ' + DescribePlat(@oldplat) + ' events [' +
      oldworld.Events.CommaText + '] new: ' + DescribePlat(@newplat) + ' events [' +
      newworld.Events.CommaText + ']');
  finally
    newworld.Free;
    oldworld.Free;
  end;
  // the real code runs as usual
  NewProc(plat);
end;

//==============================================================================
// the arithmetic of the teleports: the formulas of the old p_telept / udmf_telept with the tables
// and FixedMul of the engine against TTeleportGeometry, on random values
//==============================================================================
var
  pp_seed: LongWord = 12345;

function PP_Next: LongWord;
begin
  pp_seed := pp_seed * 1664525 + 1013904223;
  result := pp_seed;
end;

procedure PP_TeleportSelfTest;
var
  i: integer;
  x, y, speed, momx, momy, s, c: fixed_t;
  angle, exitangle, lineangle: angle_t;
  an: LongWord;
  same: boolean;
begin
  for i := 1 to 200000 do
  begin
    x := fixed_t(PP_Next);
    y := fixed_t(PP_Next);
    speed := fixed_t(PP_Next shr 6);
    momx := fixed_t(PP_Next shr 8);
    momy := fixed_t(PP_Next shr 8);
    angle := PP_Next;
    exitangle := PP_Next;
    lineangle := PP_Next;
    an := angle shr ANGLETOFINESHIFT;
    same := (x + 20 * finecosine[an] = TTeleportGeometry.FogX(x, angle)) and
            (y + 20 * finesine[an] = TTeleportGeometry.FogY(y, angle)) and
            (FixedMul(speed, finecosine[an]) = TTeleportGeometry.MissileMomentumX(speed, angle)) and
            (FixedMul(speed, finesine[an]) = TTeleportGeometry.MissileMomentumY(speed, angle));
    angle := lineangle - exitangle + ANG90;
    s := finesine[angle shr ANGLETOFINESHIFT];
    c := finecosine[angle shr ANGLETOFINESHIFT];
    same := same and (angle = TTeleportGeometry.SilentExitAngle(lineangle, exitangle)) and
            (s = TTeleportGeometry.SineOf(angle)) and (c = TTeleportGeometry.CosineOf(angle)) and
            (FixedMul(momx, c) - FixedMul(momy, s) = TTeleportGeometry.RotatedMomentumX(momx, momy, s, c)) and
            (FixedMul(momy, c) + FixedMul(momx, s) = TTeleportGeometry.RotatedMomentumY(momx, momy, s, c));
    PP_Account(KIND_TELEPORT, same, Format('x %d y %d angle %u', [x, y, angle]));
  end;
end;

procedure PP_WriteReport;
var
  i: integer;
begin
  PP_Open;
  for i := 0 to 4 do
    writeln(pp_log, KIND_NAMES[i], ' calls=', pp_total[i], ' mismatches=', pp_bad[i]);
  CloseFile(pp_log);
  pp_logopen := false;
end;

var
  pp_selftest_done: boolean = false;

// Not in the initialization: the tables and the engine are not ready before ComposeEngine
procedure PP_EnsureSelfTest;
begin
  if not pp_selftest_done then
  begin
    pp_selftest_done := true;
    PP_TeleportSelfTest;
  end;
end;

initialization

finalization
  PP_TeleportSelfTest;
  PP_WriteReport;

end.
