{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the players for the functions of scripts               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Players;

interface

uses
  DelphiDoom.ScriptHost.Players.Intf;

type
  /// <summary>
  ///   players[] for the scripts. The only class that reads them for the player functions (they
  ///   were in psi_game.pas) and the one that knows how each game keeps keys, weapons and
  ///   ammunition; the library checks the player and the indexes, so here nothing is checked
  /// </summary>
  TEngineScriptPlayers = class(TInterfacedObject, IScriptPlayerSource)
  public
    function MaxPlayers: Integer;
    function InGame(const APlayer: Integer): Boolean;
    function KeyCount: Integer;
    function HasKey(const APlayer: Integer; const AKey: Integer): Boolean;
    procedure SetKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
    function ArtifactCount: Integer;
    procedure UseArtifact(const APlayer: Integer; const AArtifact: Integer);
    function GiveArtifact(const APlayer: Integer; const AArtifact: Integer): Boolean;
    function ArtifactAmount(const APlayer: Integer; const AArtifact: Integer): Integer;
    function WeaponCount: Integer;
    function HasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
    procedure GiveWeapon(const APlayer: Integer; const AWeapon: Integer);
    function ReserveCount: Integer;
    function Reserve(const APlayer: Integer; const AKind: Integer): Integer;
    procedure SetReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
    function PlayerClass(const APlayer: Integer): Integer;
    function Message(const APlayer: Integer): string;
    procedure SetMessage(const APlayer: Integer; const AText: string);
    function ExtraLight(const APlayer: Integer): Integer;
    procedure SetExtraLight(const APlayer: Integer; const AValue: Integer);
    function PowerCount: Integer;
    function PowerTicks(const APlayer: Integer; const APower: Integer): Integer;
    procedure SetPowerTicks(const APlayer: Integer; const APower: Integer; const ATicks: Integer);
    function ViewZ(const APlayer: Integer): Integer;
    function ViewHeight(const APlayer: Integer): Integer;
    function ActorKey(const APlayer: Integer): Cardinal;
    function ConsolePlayer: Integer;
    function QuestFlags(const APlayer: Integer): Cardinal;
    procedure SetQuestFlags(const APlayer: Integer; const AFlags: Cardinal);
    procedure FaceActor(const APlayer: Integer; const AActorKey: Cardinal; const ATicks: Integer);
  end;

implementation

uses
  d_player,
  doomdef,
  g_game,
  p_inter,
  p_mobj_h,
  p_user,
  psi_game;

{ TEngineScriptPlayers }

function TEngineScriptPlayers.MaxPlayers: Integer;
begin
  // qualified: inside the class MaxPlayers would be this method (the names are the same for Pascal)
  Result := doomdef.MAXPLAYERS;
end;

function TEngineScriptPlayers.InGame(const APlayer: Integer): Boolean;
begin
  Result := playeringame[APlayer];
end;

function TEngineScriptPlayers.KeyCount: Integer;
begin
{$IFDEF DOOM_OR_STRIFE}
  Result := Ord(NUMCARDS);
{$ELSE}
  Result := Ord(NUMKEYCARDS);
{$ENDIF}
end;

function TEngineScriptPlayers.HasKey(const APlayer: Integer; const AKey: Integer): Boolean;
begin
{$IFDEF DOOM_OR_STRIFE}
  Result := players[APlayer].cards[AKey];
{$ENDIF}
{$IFDEF HERETIC}
  Result := players[APlayer].keys[AKey];
{$ENDIF}
{$IFDEF HEXEN}
  Result := players[APlayer].keys and (1 shl AKey) <> 0;
{$ENDIF}
end;

procedure TEngineScriptPlayers.SetKey(const APlayer: Integer; const AKey: Integer;
  const AValue: Boolean);
begin
{$IFDEF DOOM_OR_STRIFE}
  players[APlayer].cards[AKey] := AValue;
{$ENDIF}
{$IFDEF HERETIC}
  players[APlayer].keys[AKey] := AValue;
{$ENDIF}
{$IFDEF HEXEN}
  if AValue then
    players[APlayer].keys := players[APlayer].keys or (1 shl AKey)
  else
    players[APlayer].keys := players[APlayer].keys and not (1 shl AKey);
{$ENDIF}
end;

function TEngineScriptPlayers.ArtifactCount: Integer;
begin
{$IFDEF HERETIC_OR_HEXEN}
  Result := Ord(NUMARTIFACTS);
{$ELSE}
  Result := 0;
{$ENDIF}
end;

procedure TEngineScriptPlayers.UseArtifact(const APlayer: Integer; const AArtifact: Integer);
begin
{$IFDEF HERETIC_OR_HEXEN}
  P_PlayerUseArtifact(@players[APlayer], artitype_t(AArtifact));
{$ENDIF}
end;

function TEngineScriptPlayers.GiveArtifact(const APlayer: Integer; const AArtifact: Integer): Boolean;
begin
{$IFDEF HERETIC_OR_HEXEN}
  Result := P_GiveArtifact(@players[APlayer], artitype_t(AArtifact), nil);
{$ELSE}
  Result := False;
{$ENDIF}
end;

function TEngineScriptPlayers.ArtifactAmount(const APlayer: Integer; const AArtifact: Integer): Integer;
{$IFDEF HERETIC_OR_HEXEN}
var
  LSlot: Integer;
  LPlayer: Pplayer_t;
{$ENDIF}
begin
  Result := 0;
{$IFDEF HERETIC_OR_HEXEN}
  LPlayer := @players[APlayer];
  for LSlot := 0 to LPlayer.inventorySlotNum - 1 do
    if LPlayer.inventory[LSlot]._type = AArtifact then
    begin
      Result := LPlayer.inventory[LSlot].Count;
      Exit;
    end;
{$ENDIF}
end;

function TEngineScriptPlayers.WeaponCount: Integer;
begin
  Result := Ord(NUMWEAPONS);
end;

function TEngineScriptPlayers.HasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
begin
  Result := players[APlayer].weaponowned[AWeapon]{$IFDEF DOOM_OR_HERETIC} <> 0{$ENDIF};
end;

procedure TEngineScriptPlayers.GiveWeapon(const APlayer: Integer; const AWeapon: Integer);
begin
  players[APlayer].weaponowned[AWeapon] := {$IFDEF DOOM_OR_HERETIC}1{$ELSE}true{$ENDIF};
end;

function TEngineScriptPlayers.ReserveCount: Integer;
begin
{$IFDEF HEXEN}
  Result := Ord(NUMMANA);
{$ELSE}
  Result := Ord(NUMAMMO);
{$ENDIF}
end;

function TEngineScriptPlayers.Reserve(const APlayer: Integer; const AKind: Integer): Integer;
begin
{$IFDEF HEXEN}
  Result := players[APlayer].mana[AKind];
{$ELSE}
  Result := players[APlayer].ammo[AKind];
{$ENDIF}
end;

procedure TEngineScriptPlayers.SetReserve(const APlayer: Integer; const AKind: Integer;
  const AValue: Integer);
begin
{$IFDEF HEXEN}
  players[APlayer].mana[AKind] := AValue;
{$ELSE}
  players[APlayer].ammo[AKind] := AValue;
{$ENDIF}
end;

function TEngineScriptPlayers.PlayerClass(const APlayer: Integer): Integer;
begin
{$IFDEF HEXEN}
  Result := Ord(players[APlayer]._class);
{$ELSE}
  Result := 0;
{$ENDIF}
end;

function TEngineScriptPlayers.Message(const APlayer: Integer): string;
begin
  Result := players[APlayer]._message;
end;

procedure TEngineScriptPlayers.SetMessage(const APlayer: Integer; const AText: string);
begin
  players[APlayer]._message := AText;
end;

function TEngineScriptPlayers.ExtraLight(const APlayer: Integer): Integer;
begin
  Result := players[APlayer].extralight;
end;

procedure TEngineScriptPlayers.SetExtraLight(const APlayer: Integer; const AValue: Integer);
begin
  players[APlayer].extralight := AValue;
end;

function TEngineScriptPlayers.PowerCount: Integer;
begin
  Result := Ord(NUMPOWERS);
end;

function TEngineScriptPlayers.PowerTicks(const APlayer: Integer; const APower: Integer): Integer;
begin
  Result := players[APlayer].powers[APower];
end;

procedure TEngineScriptPlayers.SetPowerTicks(const APlayer: Integer; const APower: Integer;
  const ATicks: Integer);
begin
  players[APlayer].powers[APower] := ATicks;
end;

function TEngineScriptPlayers.ViewZ(const APlayer: Integer): Integer;
begin
  Result := players[APlayer].viewz;
end;

function TEngineScriptPlayers.ViewHeight(const APlayer: Integer): Integer;
begin
  Result := players[APlayer].viewheight;
end;

function TEngineScriptPlayers.ActorKey(const APlayer: Integer): Cardinal;
begin
  if players[APlayer].mo = nil then
  begin
    Result := ACTOR_INVALID;
    Exit;
  end;
  try
    Result := players[APlayer].mo.key;
  except
    Result := ACTOR_INVALID;
  end;
end;

function TEngineScriptPlayers.ConsolePlayer: Integer;
begin
  Result := g_game.consoleplayer;
end;

function TEngineScriptPlayers.QuestFlags(const APlayer: Integer): Cardinal;
begin
{$IFDEF STRIFE}
  Result := players[APlayer].questflags;
{$ELSE}
  Result := 0;
{$ENDIF}
end;

procedure TEngineScriptPlayers.SetQuestFlags(const APlayer: Integer; const AFlags: Cardinal);
begin
{$IFDEF STRIFE}
  players[APlayer].questflags := AFlags;
{$ENDIF}
end;

procedure TEngineScriptPlayers.FaceActor(const APlayer: Integer; const AActorKey: Cardinal;
  const ATicks: Integer);
{$IFDEF DOOM_OR_STRIFE}
var
  LActor: Pmobj_t;
{$ENDIF}
begin
{$IFDEF DOOM_OR_STRIFE}
  LActor := mobj_from_key(AActorKey);
  if LActor = nil then
    Exit;
  P_PlayerFaceMobj(@players[APlayer], LActor, ATicks);
{$ENDIF}
end;

end.
