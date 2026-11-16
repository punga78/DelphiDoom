{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the player functions of PS_GAME                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  PlayerInGame, keys and cards, artifacts (Heretic and Hexen), weapons,       }
{  ammunition or mana, class (Hexen), message, extra light, powers, view,      }
{  the console player and the quests (Strife): the PS_*Player* of              }
{  psi_game.pas.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Players;

interface

uses
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>The player functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptPlayers = class(TInterfacedObject, IScriptPlayers, IScriptFunctionSection)
  strict private
    FSource: IScriptPlayerSource;
    FGame: TScriptGame;
    function IsInIndex(const APlayer: Integer; const AIndex: Integer; const ACount: Integer): Boolean;
  public
    /// <exception cref="EArgumentNilException">If the source is nil</exception>
    constructor Create(const ASource: IScriptPlayerSource; const AGame: TScriptGame);
    procedure Describe(const ATable: IScriptFunctionTable);
    function PlayerInGame(const APlayer: Integer): Boolean;
    procedure PlayerFaceMobj(const APlayer: Integer; const AActor: Cardinal; const ATicks: Integer);
    /// <summary>The key (Heretic, Hexen) or card (Doom, Strife): scripts have both names for it</summary>
    procedure SetPlayerHasKey(const APlayer: Integer; const AKey: Integer; const AValue: Boolean);
    function GetPlayerHasKey(const APlayer: Integer; const AKey: Integer): Boolean;
    procedure PlayerUseArtifact(const APlayer: Integer; const AArtifact: Integer);
    function GiveArtifactToPlayer(const APlayer: Integer; const AArtifact: Integer): Boolean;
    function CheckPlayerArtifact(const APlayer: Integer; const AArtifact: Integer): Integer;
    procedure SetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer; const AValue: Boolean);
    function GetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
    /// <summary>The ammunition (SetPlayerAmmo) or, in Hexen, the mana (SetPlayerMana)</summary>
    procedure SetPlayerReserve(const APlayer: Integer; const AKind: Integer; const AValue: Integer);
    function GetPlayerReserve(const APlayer: Integer; const AKind: Integer): Integer;
    function GetPlayerClass(const APlayer: Integer): Integer;
    procedure SetPlayerMessage(const APlayer: Integer; const AText: string);
    function GetPlayerMessage(const APlayer: Integer): string;
    procedure SetPlayerExtraLight(const APlayer: Integer; const AValue: Integer);
    function GetPlayerExtraLight(const APlayer: Integer): Integer;
    procedure SetPlayerPowerTicks(const APlayer: Integer; const APower: Integer; const ATicks: Integer);
    function GetPlayerPowerTicks(const APlayer: Integer; const APower: Integer): Integer;
    function GetPlayerViewZ(const APlayer: Integer): Integer;
    function GetPlayerViewHeight(const APlayer: Integer): Integer;
    function GetPlayerActor(const APlayer: Integer): Cardinal;
    function ConsolePlayer: Integer;
    function CheckPlayerQuest(const APlayer: Integer; const AQuest: Cardinal): Boolean;
    procedure SetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
    procedure UnSetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.World.Intf;

{ TScriptPlayers }

constructor TScriptPlayers.Create(const ASource: IScriptPlayerSource; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FGame := AGame;
end;

procedure TScriptPlayers.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethod('function PlayerInGame(const plnum: integer): boolean;', Self,
    @TScriptPlayers.PlayerInGame);
  if FGame in [sgDoom, sgStrife] then
    ATable.AddMethod(
      'procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);',
      Self, @TScriptPlayers.PlayerFaceMobj);
  // the cards of Doom and Strife and the keys of Heretic and Hexen are the same two functions
  // for scripts, under both names
  ATable.AddMethod(
    'procedure SetPlayerHasCard(const plnum: integer; const card: integer; const value: boolean);',
    Self, @TScriptPlayers.SetPlayerHasKey);
  ATable.AddMethod('function GetPlayerHasCard(const plnum: integer; const card: integer): boolean;',
    Self, @TScriptPlayers.GetPlayerHasKey);
  ATable.AddMethod(
    'procedure SetPlayerHasKey(const plnum: integer; const key: integer; const value: boolean);',
    Self, @TScriptPlayers.SetPlayerHasKey);
  ATable.AddMethod('function GetPlayerHasKey(const plnum: integer; const key: integer): boolean;',
    Self, @TScriptPlayers.GetPlayerHasKey);
  if FGame in [sgHeretic, sgHexen] then
  begin
    ATable.AddMethod('procedure PlayerUseArtifact(const plnum: Integer; const arti: Integer);', Self,
      @TScriptPlayers.PlayerUseArtifact);
    ATable.AddMethod('function GiveArtifactToPlayer(const plnum: Integer; const arti: Integer): Boolean;',
      Self, @TScriptPlayers.GiveArtifactToPlayer);
    ATable.AddMethod('function CheckPlayerArtifact(const plnum: Integer; const arti: Integer): Integer;',
      Self, @TScriptPlayers.CheckPlayerArtifact);
  end;
  ATable.AddMethod(
    'procedure SetPlayerHasWeapon(const plnum: integer; const weapon: integer; const value: boolean);',
    Self, @TScriptPlayers.SetPlayerHasWeapon);
  ATable.AddMethod('function GetPlayerHasWeapon(const plnum: integer; const weapon: integer): boolean;',
    Self, @TScriptPlayers.GetPlayerHasWeapon);
  if FGame <> sgHexen then
  begin
    ATable.AddMethod(
      'procedure SetPlayerAmmo(const plnum: integer; const ammotype: integer; const value: integer);',
      Self, @TScriptPlayers.SetPlayerReserve);
    ATable.AddMethod('function GetPlayerAmmo(const plnum: integer; const ammotype: integer): integer;',
      Self, @TScriptPlayers.GetPlayerReserve);
  end
  else
  begin
    ATable.AddMethod(
      'procedure SetPlayerMana(const plnum: integer; const mana: integer; const value: integer);',
      Self, @TScriptPlayers.SetPlayerReserve);
    ATable.AddMethod('function GetPlayerMana(const plnum: integer; const mana: integer): integer;',
      Self, @TScriptPlayers.GetPlayerReserve);
    ATable.AddMethod('function GetPlayerClass(const plnum: Integer): Integer;', Self,
      @TScriptPlayers.GetPlayerClass);
  end;
  ATable.AddMethod('procedure SetPlayerMessage(const plnum: integer; const msg: string);', Self,
    @TScriptPlayers.SetPlayerMessage);
  ATable.AddMethod('function GetPlayerMessage(const plnum: integer): string;', Self,
    @TScriptPlayers.GetPlayerMessage);
  ATable.AddMethod('procedure SetPlayerExtraLight(const plnum: Integer; const l: Integer);', Self,
    @TScriptPlayers.SetPlayerExtraLight);
  ATable.AddMethod('function GetPlayerExtraLight(const plnum: Integer): Integer;', Self,
    @TScriptPlayers.GetPlayerExtraLight);
  ATable.AddMethod(
    'procedure SetPlayerPowerTicks(const plnum: integer; const powertype: integer; const ticks: integer);',
    Self, @TScriptPlayers.SetPlayerPowerTicks);
  ATable.AddMethod('function GetPlayerPowerTicks(const plnum: integer; const powertype: integer): integer;',
    Self, @TScriptPlayers.GetPlayerPowerTicks);
  ATable.AddMethod('function GetPlayerViewZ(const plnum: integer): fixed_t;', Self,
    @TScriptPlayers.GetPlayerViewZ);
  ATable.AddMethod('function GetPlayerViewHeight(const plnum: integer): fixed_t;', Self,
    @TScriptPlayers.GetPlayerViewHeight);
  ATable.AddMethod('function ConsolePlayer: Integer;', Self, @TScriptPlayers.ConsolePlayer);
  if FGame = sgStrife then
  begin
    ATable.AddMethod('function CheckPlayerQuest(const plnum: Integer; const quest: LongWord): Boolean;',
      Self, @TScriptPlayers.CheckPlayerQuest);
    ATable.AddMethod('procedure SetPlayerQuest(const plnum: Integer; const quest: LongWord);', Self,
      @TScriptPlayers.SetPlayerQuest);
    ATable.AddMethod('procedure UnSetPlayerQuest(const plnum: Integer; const quest: LongWord);', Self,
      @TScriptPlayers.UnSetPlayerQuest);
  end;
end;

function TScriptPlayers.IsInIndex(const APlayer: Integer; const AIndex: Integer;
  const ACount: Integer): Boolean;
begin
  Result := PlayerInGame(APlayer) and (AIndex >= 0) and (AIndex < ACount);
end;

function TScriptPlayers.PlayerInGame(const APlayer: Integer): Boolean;
begin
  if (APlayer >= 0) and (APlayer < FSource.MaxPlayers) then
    Result := FSource.InGame(APlayer)
  else
    Result := False;
end;

procedure TScriptPlayers.PlayerFaceMobj(const APlayer: Integer; const AActor: Cardinal;
  const ATicks: Integer);
begin
  if not PlayerInGame(APlayer) then
    Exit;
  if ATicks <= 0 then
    Exit;
  FSource.FaceActor(APlayer, AActor, ATicks);
end;

procedure TScriptPlayers.SetPlayerHasKey(const APlayer: Integer; const AKey: Integer;
  const AValue: Boolean);
begin
  if IsInIndex(APlayer, AKey, FSource.KeyCount) then
    FSource.SetKey(APlayer, AKey, AValue);
end;

function TScriptPlayers.GetPlayerHasKey(const APlayer: Integer; const AKey: Integer): Boolean;
begin
  Result := IsInIndex(APlayer, AKey, FSource.KeyCount) and FSource.HasKey(APlayer, AKey);
end;

procedure TScriptPlayers.PlayerUseArtifact(const APlayer: Integer; const AArtifact: Integer);
begin
  if IsInIndex(APlayer, AArtifact, FSource.ArtifactCount) then
    FSource.UseArtifact(APlayer, AArtifact);
end;

function TScriptPlayers.GiveArtifactToPlayer(const APlayer: Integer;
  const AArtifact: Integer): Boolean;
begin
  Result := IsInIndex(APlayer, AArtifact, FSource.ArtifactCount) and
    FSource.GiveArtifact(APlayer, AArtifact);
end;

function TScriptPlayers.CheckPlayerArtifact(const APlayer: Integer; const AArtifact: Integer): Integer;
begin
  if IsInIndex(APlayer, AArtifact, FSource.ArtifactCount) then
    Result := FSource.ArtifactAmount(APlayer, AArtifact)
  else
    Result := 0;
end;

procedure TScriptPlayers.SetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer;
  const AValue: Boolean);
begin
  // Defect of the old code, kept: the value is ignored, a weapon can be given but not taken away
  if IsInIndex(APlayer, AWeapon, FSource.WeaponCount) then
    FSource.GiveWeapon(APlayer, AWeapon);
end;

function TScriptPlayers.GetPlayerHasWeapon(const APlayer: Integer; const AWeapon: Integer): Boolean;
begin
  Result := IsInIndex(APlayer, AWeapon, FSource.WeaponCount) and FSource.HasWeapon(APlayer, AWeapon);
end;

procedure TScriptPlayers.SetPlayerReserve(const APlayer: Integer; const AKind: Integer;
  const AValue: Integer);
begin
  if IsInIndex(APlayer, AKind, FSource.ReserveCount) then
    FSource.SetReserve(APlayer, AKind, AValue);
end;

function TScriptPlayers.GetPlayerReserve(const APlayer: Integer; const AKind: Integer): Integer;
begin
  if IsInIndex(APlayer, AKind, FSource.ReserveCount) then
    Result := FSource.Reserve(APlayer, AKind)
  else
    Result := 0;
end;

function TScriptPlayers.GetPlayerClass(const APlayer: Integer): Integer;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.PlayerClass(APlayer)
  else
    Result := 0;
end;

procedure TScriptPlayers.SetPlayerMessage(const APlayer: Integer; const AText: string);
begin
  if PlayerInGame(APlayer) then
    FSource.SetMessage(APlayer, AText);
end;

function TScriptPlayers.GetPlayerMessage(const APlayer: Integer): string;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.Message(APlayer)
  else
    Result := '';
end;

procedure TScriptPlayers.SetPlayerExtraLight(const APlayer: Integer; const AValue: Integer);
begin
  if PlayerInGame(APlayer) then
    FSource.SetExtraLight(APlayer, AValue);
end;

function TScriptPlayers.GetPlayerExtraLight(const APlayer: Integer): Integer;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.ExtraLight(APlayer)
  else
    Result := 0;
end;

procedure TScriptPlayers.SetPlayerPowerTicks(const APlayer: Integer; const APower: Integer;
  const ATicks: Integer);
begin
  if IsInIndex(APlayer, APower, FSource.PowerCount) then
    FSource.SetPowerTicks(APlayer, APower, ATicks);
end;

function TScriptPlayers.GetPlayerPowerTicks(const APlayer: Integer; const APower: Integer): Integer;
begin
  if IsInIndex(APlayer, APower, FSource.PowerCount) then
    Result := FSource.PowerTicks(APlayer, APower)
  else
    Result := 0;
end;

function TScriptPlayers.GetPlayerViewZ(const APlayer: Integer): Integer;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.ViewZ(APlayer)
  else
    Result := 0;
end;

function TScriptPlayers.GetPlayerViewHeight(const APlayer: Integer): Integer;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.ViewHeight(APlayer)
  else
    Result := 0;
end;

function TScriptPlayers.GetPlayerActor(const APlayer: Integer): Cardinal;
begin
  if PlayerInGame(APlayer) then
    Result := FSource.ActorKey(APlayer)
  else
    Result := Cardinal(SCRIPT_INVALID_ID);
end;

function TScriptPlayers.ConsolePlayer: Integer;
begin
  Result := FSource.ConsolePlayer;
end;

function TScriptPlayers.CheckPlayerQuest(const APlayer: Integer; const AQuest: Cardinal): Boolean;
begin
  Result := PlayerInGame(APlayer) and (FSource.QuestFlags(APlayer) and AQuest <> 0);
end;

procedure TScriptPlayers.SetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
begin
  if PlayerInGame(APlayer) then
    FSource.SetQuestFlags(APlayer, FSource.QuestFlags(APlayer) or AQuest);
end;

procedure TScriptPlayers.UnSetPlayerQuest(const APlayer: Integer; const AQuest: Cardinal);
begin
  if PlayerInGame(APlayer) then
    FSource.SetQuestFlags(APlayer, FSource.QuestFlags(APlayer) and not AQuest);
end;

end.
