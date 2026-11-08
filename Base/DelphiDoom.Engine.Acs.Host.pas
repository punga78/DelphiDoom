{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the host of the ACS machine                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit DelphiDoom.Engine.Acs.Host;

interface

uses
  DelphiDoom.Acs.Machine.Types,
  DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Zone.Intf;

type
  /// <summary>
  ///   What the scripts of a map ask of the game, answered with the globals of the engine: the
  ///   line specials, the sectors, the lines, the things, the sounds and the messages of the
  ///   player. Lines and activators of the machine are Pline_t and Pmobj_t of the engine
  /// </summary>
  TEngineAcsHost = class(TInterfacedObject, IAcsHost)
  strict private
    FZone: IZoneAllocator;
  public
    /// <param name="AZone">Holds the thinkers of the scripts (PU_LEVSPEC)</param>
    constructor Create(const AZone: IZoneAllocator);
    function TicsPerSecond: Integer;
    function CurrentMap: Integer;
    function LevelTime: Integer;
    function GameType: TAcsGameType;
    function GameSkill: Integer;
    function PlayerCount: Integer;
    function NextRandom: Integer;
    function AllocateScript: PAcsScript;
    procedure ReleaseScript(AScript: PAcsScript);
    procedure ExecuteLineSpecial(ASpecial: Integer; const AArguments: TAcsSpecialArguments;
      ALine, AActivator: Pointer; ASide: Integer);
    function IsTagBusy(ATag: Integer): Boolean;
    function IsPolyobjectBusy(APolyobject: Integer): Boolean;
    procedure ChangeSectorFlat(ATag: Integer; const AFlatName: string; AFloor: Boolean);
    function CountThings(AThingType, ATid: Integer): Integer;
    procedure SetLineTexture(ALineTag, ASide, APosition: Integer; const ATextureName: string);
    procedure SetLineBlocking(ALineTag: Integer; ABlocking: Boolean);
    procedure SetLineSpecial(ALineTag, ASpecial: Integer;
      const AArguments: TAcsLineSpecialArguments);
    procedure ClearLineSpecial(ALine: Pointer);
    procedure PlaySectorSound(ALine: Pointer; const ASoundName: string; AVolume: Integer);
    procedure PlayThingSound(ATid: Integer; const ASoundName: string; AVolume: Integer);
    procedure PlayAmbientSound(const ASoundName: string; AVolume: Integer);
    procedure StartSoundSequence(ALine: Pointer; const ASequenceName: string);
    procedure ShowMessage(AActivator: Pointer; const AText: string);
    procedure ShowMessageToAll(const AText: string);
    procedure ShowConsoleMessage(const AText: string);
  end;

implementation

uses
  d_delphi,
  d_think,
  d_player,
  doomdata,
  doomdef,
  g_game,
  info_h,
  m_rnd,
  p_acs,
  p_inter,
  p_mobj,
  p_mobj_h,
  p_setup,
  p_spec,
  p_tick,
  {$IFDEF HEXEN}
  p_things,
  {$ELSE}
  p_udmf,
  udmf_mobj,
  udmf_spec,
  udmf_things,
  {$ENDIF}
  po_man,
  r_data,
  r_defs,
  s_sound,
  sounddata,
  sounds,
  {$IFDEF HEXEN}
  s_sndseq,
  {$ENDIF}
  System.SysUtils,
  DelphiDoom.Zone.Types;

{ TEngineAcsHost }

constructor TEngineAcsHost.Create(const AZone: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  FZone := AZone;
end;

function TEngineAcsHost.TicsPerSecond: Integer;
begin
  Result := TICRATE;
end;

function TEngineAcsHost.CurrentMap: Integer;
begin
  Result := gamemap;
end;

function TEngineAcsHost.LevelTime: Integer;
begin
  Result := leveltime;
end;

function TEngineAcsHost.GameType: TAcsGameType;
begin
  if not netgame then
    Result := agtSinglePlayer
  else if deathmatch <> 0 then
    Result := agtNetDeathmatch
  else
    Result := agtNetCooperative;
end;

function TEngineAcsHost.GameSkill: Integer;
begin
  Result := Ord(gameskill);
end;

function TEngineAcsHost.PlayerCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to MAXPLAYERS - 1 do
    if playeringame[LIndex] then
      Inc(Result);
end;

function TEngineAcsHost.NextRandom: Integer;
begin
  Result := P_Random;
end;

function TEngineAcsHost.AllocateScript: PAcsScript;
var
  LScript: Pacs_t;
begin
  LScript := FZone.Allocate(SizeOf(acs_t), ZONE_TAG_LEVSPEC, nil);
  memset(LScript, 0, SizeOf(acs_t));
  LScript.thinker._function.acp1 := @TH_InterpretACS;
  P_AddThinker(@LScript.thinker);
  Result := PAcsScript(System.PByte(LScript) + SizeOf(thinker_t));
end;

procedure TEngineAcsHost.ReleaseScript(AScript: PAcsScript);
var
  LScript: Pacs_t;
begin
  LScript := Pacs_t(System.PByte(AScript) - SizeOf(thinker_t));
  P_RemoveThinker(@LScript.thinker);
end;

procedure TEngineAcsHost.ExecuteLineSpecial(ASpecial: Integer;
  const AArguments: TAcsSpecialArguments; ALine, AActivator: Pointer; ASide: Integer);
begin
  P_ExecuteLineSpecial(ASpecial, PByteArray(@AArguments), Pline_t(ALine), ASide,
    Pmobj_t(AActivator));
end;

function TEngineAcsHost.IsTagBusy(ATag: Integer): Boolean;
var
  LSectorIndex: Integer;
begin
  LSectorIndex := -1;
  while P_FindSectorFromTag2(ATag, LSectorIndex) >= 0 do
  begin
    if sectors[LSectorIndex].specialdata <> nil then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TEngineAcsHost.IsPolyobjectBusy(APolyobject: Integer): Boolean;
begin
  Result := PO_Busy(APolyobject);
end;

procedure TEngineAcsHost.ChangeSectorFlat(ATag: Integer; const AFlatName: string;
  AFloor: Boolean);
var
  LFlat: Integer;
  LSectorIndex: Integer;
begin
  LFlat := R_FlatNumForName(AFlatName);
  LSectorIndex := -1;
  while P_FindSectorFromTag2(ATag, LSectorIndex) >= 0 do
  begin
    if AFloor then
      sectors[LSectorIndex].floorpic := LFlat
    else
      sectors[LSectorIndex].ceilingpic := LFlat;
  end;
end;

function TEngineAcsHost.CountThings(AThingType, ATid: Integer): Integer;
var
  LThingType: mobjtype_t;
  {$IFDEF HEXEN}
  LSearcher: Integer;
  {$ELSE}
  LSearcher: Pointer;
  {$ENDIF}
  LMobj: Pmobj_t;
  LThink: Pthinker_t;
begin
  Result := 0;
  if (AThingType <> 0) and
    ((AThingType < Low(TranslateThingType)) or (AThingType > High(TranslateThingType))) then
    Exit; // a type that does not exist: there are no such things
  if AThingType <> 0 then
    LThingType := TranslateThingType[AThingType]
  else
    LThingType := mobjtype_t(0);

  if ATid <> 0 then
  begin // count the things with the tid
    {$IFDEF HEXEN}
    LSearcher := -1;
    {$ELSE}
    LSearcher := @thinkercap;
    {$ENDIF}
    repeat
      LMobj := P_FindMobjFromTID(ATid, {$IFDEF HEXEN}@LSearcher{$ELSE}LSearcher{$ENDIF});
      if LMobj = nil then
        Break;
      if AThingType = 0 then
        Inc(Result) // just count the tid
      else if Ord(LThingType) = LMobj._type then
      begin
        if (LMobj.flags and MF_COUNTKILL <> 0) and (LMobj.health <= 0) then
          Continue; // don't count dead monsters
        Inc(Result);
      end;
    until False;
  end
  else
  begin // count only the type
    LThink := thinkercap.next;
    while LThink <> @thinkercap do
    begin
      if @LThink._function.acp1 = @P_MobjThinker then
      begin
        LMobj := Pmobj_t(LThink);
        if (LMobj._type = Ord(LThingType)) and
          not ((LMobj.flags and MF_COUNTKILL <> 0) and (LMobj.health <= 0)) then
          Inc(Result);
      end;
      LThink := LThink.next;
    end;
  end;
end;

procedure TEngineAcsHost.SetLineTexture(ALineTag, ASide, APosition: Integer;
  const ATextureName: string);
var
  LTexture: Integer;
  LLine: Pline_t;
  LSearcher: Integer;
begin
  LTexture := R_TextureNumForName(ATextureName);
  LSearcher := -1;
  LLine := P_FindLine(ALineTag, @LSearcher);
  while LLine <> nil do
  begin
    if APosition = ACS_TEXTURE_MIDDLE then
      sides[LLine.sidenum[ASide]].midtexture := LTexture
    else if APosition = ACS_TEXTURE_BOTTOM then
      sides[LLine.sidenum[ASide]].bottomtexture := LTexture
    else // the top
      sides[LLine.sidenum[ASide]].toptexture := LTexture;
    LLine := P_FindLine(ALineTag, @LSearcher);
  end;
end;

procedure TEngineAcsHost.SetLineBlocking(ALineTag: Integer; ABlocking: Boolean);
var
  LLine: Pline_t;
  LSearcher: Integer;
  LBlocking: Integer;
begin
  if ABlocking then
    LBlocking := ML_BLOCKING
  else
    LBlocking := 0;
  LSearcher := -1;
  LLine := P_FindLine(ALineTag, @LSearcher);
  while LLine <> nil do
  begin
    LLine.flags := (LLine.flags and not ML_BLOCKING) or LBlocking;
    LLine := P_FindLine(ALineTag, @LSearcher);
  end;
end;

procedure TEngineAcsHost.SetLineSpecial(ALineTag, ASpecial: Integer;
  const AArguments: TAcsLineSpecialArguments);
var
  LLine: Pline_t;
  LSearcher: Integer;
begin
  LSearcher := -1;
  LLine := P_FindLine(ALineTag, @LSearcher);
  while LLine <> nil do
  begin
    LLine.special := ASpecial;
    {$IFNDEF HEXEN}
    if IsIntegerInRange(LLine.special and 1023, 1, UDMF_NORMAL_ADD) then
      LLine.special := (LLine.special and 1023 + UDMF_SPECIAL_START) or (LLine.special and not 1023)
    else if IsIntegerInRange(LLine.special and 1023, UDMF_NORMAL_ADD, UDMF_SPECIAL_START + UDMF_NORMAL_ADD) then
      LLine.special := (LLine.special and 1023 - UDMF_NORMAL_ADD) or (LLine.special and not 1023);
    {$ENDIF}
    LLine.arg1 := AArguments[0];
    LLine.arg2 := AArguments[1];
    LLine.arg3 := AArguments[2];
    LLine.arg4 := AArguments[3];
    LLine.arg5 := AArguments[4];
    LLine := P_FindLine(ALineTag, @LSearcher);
  end;
end;

procedure TEngineAcsHost.ClearLineSpecial(ALine: Pointer);
begin
  if ALine <> nil then
    Pline_t(ALine).special := 0;
end;

procedure TEngineAcsHost.PlaySectorSound(ALine: Pointer; const ASoundName: string;
  AVolume: Integer);
var
  LOrigin: Pmobj_t;
begin
  LOrigin := nil;
  if ALine <> nil then
    LOrigin := Pmobj_t(@Pline_t(ALine).frontsector.soundorg);
  S_StartSoundAtVolume(LOrigin, S_GetSoundNumForName(ASoundName), AVolume);
end;

procedure TEngineAcsHost.PlayThingSound(ATid: Integer; const ASoundName: string;
  AVolume: Integer);
var
  LSound: Integer;
  LMobj: Pmobj_t;
  {$IFDEF HEXEN}
  LSearcher: Integer;
  {$ELSE}
  LSearcher: Pointer;
  {$ENDIF}
begin
  LSound := S_GetSoundNumForName(ASoundName);
  {$IFDEF HEXEN}
  LSearcher := -1;
  {$ELSE}
  LSearcher := @thinkercap;
  {$ENDIF}
  LMobj := P_FindMobjFromTID(ATid, {$IFDEF HEXEN}@LSearcher{$ELSE}LSearcher{$ENDIF});
  while LMobj <> nil do
  begin
    S_StartSoundAtVolume(LMobj, LSound, AVolume);
    LMobj := P_FindMobjFromTID(ATid, {$IFDEF HEXEN}@LSearcher{$ELSE}LSearcher{$ENDIF});
  end;
end;

procedure TEngineAcsHost.PlayAmbientSound(const ASoundName: string; AVolume: Integer);
begin
  S_StartSoundAtVolume(nil, S_GetSoundNumForName(ASoundName), AVolume);
end;

procedure TEngineAcsHost.StartSoundSequence(ALine: Pointer; const ASequenceName: string);
var
  LOrigin: Pmobj_t;
begin
  LOrigin := nil;
  if ALine <> nil then
    LOrigin := Pmobj_t(@Pline_t(ALine).frontsector.soundorg);
  {$IFDEF HEXEN}
  S_StartSequenceName(LOrigin, ASequenceName);
  {$ELSE}
  S_StartSound(LOrigin, ASequenceName);
  {$ENDIF}
end;

procedure TEngineAcsHost.ShowMessage(AActivator: Pointer; const AText: string);
var
  LPlayer: Pplayer_t;
begin
  if (AActivator <> nil) and (Pmobj_t(AActivator).player <> nil) then
    LPlayer := Pmobj_t(AActivator).player
  else
    LPlayer := @players[consoleplayer];
  {$IFDEF HEXEN}
  P_SetMessage(LPlayer, AText, True);
  {$ELSE}
  LPlayer._message := AText;
  {$ENDIF}
end;

procedure TEngineAcsHost.ShowMessageToAll(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAXPLAYERS - 1 do
    if playeringame[LIndex] then
    begin
      {$IFDEF HEXEN}
      P_SetMessage(@players[LIndex], AText, True);
      {$ELSE}
      players[LIndex]._message := AText;
      {$ENDIF}
    end;
end;

procedure TEngineAcsHost.ShowConsoleMessage(const AText: string);
begin
  {$IFDEF HEXEN}
  P_SetMessage(@players[consoleplayer], AText, True);
  {$ELSE}
  players[consoleplayer]._message := AText;
  {$ENDIF}
end;

end.
