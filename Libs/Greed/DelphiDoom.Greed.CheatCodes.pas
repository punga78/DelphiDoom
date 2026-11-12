{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the secret codes typed while playing             }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): Check_Secret and            }
{  Special_Code of raven.pas                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.CheatCodes;

// the positions of the sprites are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Level.Intf;

const
  /// <summary>WALL_COLOR of r_public_h.pas: a wall that the player has seen, on its map</summary>
  GREED_WALL_COLOR = 127;

type
  /// <summary>
  ///   Special_Code of raven.pas, line by line: at every frame the letters that the player typed
  ///   (TGreedGameState.SecretBuf, at most 19) are searched for a secret code, without looking at the case; the
  ///   first code found, in the order of the original, does its thing and empties the letters. The codes: belfast
  ///   (kills everything), allahmode or god, raven (health), omni (the whole map), kmfdm (ammunition), beavis (the
  ///   goals of the level), gulliver (bigger sprites), gimme (inventory), taco (the view of the enemy), game1,
  ///   game2, game3 and goNN (another episode, another map), score10000, score20000, score50000, blammoN (a
  ///   weapon in the slot 2) and five that only say something.
  ///   The net game is not ported: the test of the parameter "ravenger", that allows the codes in a net game, is
  ///   not here.
  ///   Kept behaviour of the original: game2 and game3 empty the letters in the demo too, and then do nothing;
  ///   letters with "bl" in them (and more than two) select the slot 2 if it has a weapon, even without a whole
  ///   code; a go code that is not of the episode stays in the letters; belfast also kills what KillSprite makes
  ///   while it runs, if it has hit points.
  ///   Difference: a sprite outside the map does not clear a tile (the original wrote near the array)
  /// </summary>
  TGreedCheatCodes = class
  strict private
    FState: TGreedGameState;
    FMessages: IGreedMessages;
    FHealth: IGreedPlayerHealth;
    FKiller: IGreedSpriteKiller;
    FHost: IGreedCheatHost;
    class function Upper(const AText: string): string; static;
    function GoCode: Boolean;
    procedure KillEverything;
    procedure ToggleGodMode;
    procedure ShowWholeMap;
    procedure ToggleMidgetMode;
    procedure FillInventory;
    procedure SelectEpisode(AEpisode, AMap: Integer);
    procedure GiveWeapon;
  public
    /// <summary>
    ///   AState has the world, the sprites and the globals; AMessages is writemsg, AHealth addscore, AKiller
    ///   KillSprite, AHost the maps, the weapon in the hand and the status bar. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth;
      const AKiller: IGreedSpriteKiller; const AHost: IGreedCheatHost);
    /// <summary>
    ///   What the keyboard does with a key (ControlMovement of the original): a letter or a digit goes at the end
    ///   of SecretBuf, and the first one goes away when there are 19; another character is not kept
    /// </summary>
    procedure AddCharacter(AChar: Char);
    /// <summary>Check_Secret(code): True, and the letters are emptied, if they have the code in them</summary>
    function CheckSecret(const ACode: string): Boolean;
    /// <summary>Special_Code: once a frame</summary>
    procedure SpecialCode;
  end;

implementation

const
  TILE = GREED_FRACTILEUNIT;
  SDeathKiss = 'DeathKiss';
  SGodModeOff = 'GodMode Off';
  SGodModeOn = 'GodMode On';
  SChannel7 = 'Rob Lays Eggs';
  SLizardMan = 'Jeremy Lays Eggs';
  SDominatrix = 'On your knees worm!';
  SCyborg = 'Psyborgs Rule!';
  SMooMan = 'Brady is better than you, and that ain''t saying much!';
  SAmbrosia = 'Ambrosia';
  SOmniscience = 'Omniscience';
  SBackpack = 'Backpack of Holding';
  STimeWarp = 'Time Warp';
  SMidgetOff = 'Midget Mode Off';
  SMidgetOn = 'Midget Mode On';
  SBagOfHolding = 'Bag of Holding';
  SEnemyView = 'Enemy view toggled';

  /// the weapon of blammo1 .. blammo6
  BLAMMO_WEAPONS: array[1..6] of Integer = (2, 3, 4, 16, 17, 18);

{ TGreedCheatCodes }

constructor TGreedCheatCodes.Create(AState: TGreedGameState; const AMessages: IGreedMessages;
  const AHealth: IGreedPlayerHealth; const AKiller: IGreedSpriteKiller; const AHost: IGreedCheatHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(AKiller) then
    raise EArgumentNilException.Create('AKiller');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FMessages := AMessages;
  FHealth := AHealth;
  FKiller := AKiller;
  FHost := AHost;
end;

class function TGreedCheatCodes.Upper(const AText: string): string;
var
  LIndex: Integer;
begin
  // strupper of the original: the letters a..z only
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

procedure TGreedCheatCodes.AddCharacter(AChar: Char);
begin
  // only letters and digits are kept
  if not (((AChar >= 'a') and (AChar <= 'z')) or ((AChar >= 'A') and (AChar <= 'Z')) or
    ((AChar >= '0') and (AChar <= '9'))) then
    Exit;
  if Length(FState.SecretBuf) >= GREED_SECRET_BUFFER_SIZE - 1 then
    Delete(FState.SecretBuf, 1, 1);
  FState.SecretBuf := FState.SecretBuf + AChar;
end;

function TGreedCheatCodes.CheckSecret(const ACode: string): Boolean;
begin
  Result := Pos(Upper(ACode), Upper(FState.SecretBuf)) > 0;
  if Result then
    FState.SecretBuf := '';
end;

procedure TGreedCheatCodes.KillEverything;
var
  LSprite, LPrevious, LMapSpot: Integer;
  LItem: PGreedSprite;
begin
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FState.Sprites.Item(LSprite));
    if LItem^.HitPoints <> 0 then
    begin
      LMapSpot := (LItem^.Y div TILE) * GREED_MAP_SIZE + (LItem^.X div TILE);
      if (LMapSpot >= 0) and (LMapSpot < GREED_MAP_TILES) then
        FState.World.SetValue(gpMapSprites, LMapSpot, 0);
      // the next one is the one after the sprite before: KillSprite may take this one out of the list
      LPrevious := FState.Sprites.Previous(LSprite);
      FKiller.KillSprite(LSprite, GREED_S_BULLET3);
      Inc(FState.Player.BodyCount);
      if LPrevious = GREED_POOL_NIL then
        LSprite := FState.Sprites.First
      else
        LSprite := FState.Sprites.Next(LPrevious);
    end
    else
      LSprite := FState.Sprites.Next(LSprite);
  end;
  FMessages.WriteMessage(SDeathKiss);
end;

procedure TGreedCheatCodes.ToggleGodMode;
begin
  if FState.GodMode then
  begin
    FState.GodMode := False;
    FMessages.WriteMessage(SGodModeOff);
  end
  else
  begin
    FState.GodMode := True;
    FMessages.WriteMessage(SGodModeOn);
  end;
end;

procedure TGreedCheatCodes.ShowWholeMap;
var
  LSpot: Integer;
begin
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    if FState.World.GetValue(gpNorthWall, LSpot) <> 0 then
      FState.Player.NorthMap[LSpot] := GREED_WALL_COLOR;
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    if FState.World.GetValue(gpWestWall, LSpot) <> 0 then
      FState.Player.WestMap[LSpot] := GREED_WALL_COLOR;
  FMessages.WriteMessage(SOmniscience);
end;

procedure TGreedCheatCodes.ToggleMidgetMode;
var
  LSprite, LStep: Integer;
begin
  if FState.MidgetMode then
    LStep := -1
  else
    LStep := 1;
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    PGreedSprite(FState.Sprites.Item(LSprite))^.Scale := PGreedSprite(FState.Sprites.Item(LSprite))^.Scale + LStep;
    LSprite := FState.Sprites.Next(LSprite);
  end;
  FState.MidgetMode := not FState.MidgetMode;
  if FState.MidgetMode then
    FMessages.WriteMessage(SMidgetOn)
  else
    FMessages.WriteMessage(SMidgetOff);
end;

procedure TGreedCheatCodes.FillInventory;
var
  LIndex: Integer;
begin
  FState.Player.Inventory[0] := 20;
  FState.Player.Inventory[1] := 20;
  FState.Player.Inventory[2] := 15;
  for LIndex := 3 to 8 do
    FState.Player.Inventory[LIndex] := 10;
  if not FState.Demo then
    for LIndex := 9 to 12 do
      FState.Player.Inventory[LIndex] := 10;
  FMessages.WriteMessage(SBagOfHolding);
end;

procedure TGreedCheatCodes.SelectEpisode(AEpisode, AMap: Integer);
begin
  FState.Game1 := AEpisode = 1;
  FState.Game2 := AEpisode = 2;
  FState.Game3 := AEpisode = 3;
  FHost.SetGameEpisode(AEpisode);
  FHost.NewMap(AMap, 2);
end;

function TGreedCheatCodes.GoCode: Boolean;

  function Go(AFirst, ALast: Integer): Boolean;
  var
    LNumber: Integer;
  begin
    for LNumber := AFirst to ALast do
      if CheckSecret(Format('go%.2d', [LNumber])) then
      begin
        // goNN is the map NN - 1
        FHost.NewMap(LNumber - 1, 2);
        Exit(True);
      end;
    Result := False;
  end;

begin
  Result := False;
  if FState.Demo or FState.Game1 then
    Result := Go(1, 3);
  if not FState.Demo then
  begin
    // after a code that was found the letters are empty: the other tests of the original find nothing
    if FState.Game1 and not Result then
      Result := Go(4, 7);
    if FState.Game2 and not Result then
      Result := Go(8, 15);
    if FState.Game3 and not Result then
      Result := Go(16, 22);
    if not Result then
      Result := Go(23, 32);
  end;
end;

procedure TGreedCheatCodes.GiveWeapon;
var
  LNumber: Integer;
begin
  for LNumber := Low(BLAMMO_WEAPONS) to High(BLAMMO_WEAPONS) do
    if CheckSecret('blammo' + IntToStr(LNumber)) then
    begin
      FState.Player.Weapons[2] := BLAMMO_WEAPONS[LNumber];
      Break;
    end;
  if FState.Player.Weapons[2] >= 0 then
  begin
    FHost.LoadWeapon(FState.Player.Weapons[2]);
    FState.Player.CurrentWeapon := 2;
    FState.WeapMode := 0;
  end;
end;

procedure TGreedCheatCodes.SpecialCode;
var
  LIndex: Integer;
begin
  if CheckSecret('belfast') then
    KillEverything
  else if CheckSecret('allahmode') or CheckSecret('god') then
    ToggleGodMode
  else if CheckSecret('channel7') then
    FMessages.WriteMessage(SChannel7)
  else if CheckSecret('lizardman') then
    FMessages.WriteMessage(SLizardMan)
  else if CheckSecret('dominatrix') then
    FMessages.WriteMessage(SDominatrix)
  else if CheckSecret('cyborg') then
    FMessages.WriteMessage(SCyborg)
  else if CheckSecret('mooman') then
    FMessages.WriteMessage(SMooMan)
  else if CheckSecret('raven') then
  begin
    FState.Player.Angst := FState.Player.MaxAngst;
    FState.Player.Shield := FState.Player.MaxShield;
    FMessages.WriteMessage(SAmbrosia);
  end
  else if CheckSecret('omni') then
    ShowWholeMap
  else if CheckSecret('kmfdm') then
  begin
    FState.Player.Ammo[0] := 999;
    FState.Player.Ammo[1] := 999;
    FState.Player.Ammo[2] := 999;
    FMessages.WriteMessage(SBackpack);
    FHost.RefreshAmmo;
  end
  else if CheckSecret('beavis') then
  begin
    FState.Player.LevelScore := 100;
    FState.Player.Primaries[0] := FState.PCount[0];
    FState.Player.Primaries[1] := FState.PCount[1];
    for LIndex := 0 to 6 do
      FState.Player.Secondaries[LIndex] := FState.SCount[LIndex];
    FMessages.WriteMessage(STimeWarp);
  end
  else if CheckSecret('gulliver') then
    ToggleMidgetMode
  else if CheckSecret('gimme') then
    FillInventory
  else if CheckSecret('taco') then
  begin
    FState.EnemyViewMode := FState.EnemyViewMode xor 1;
    FMessages.WriteMessage(SEnemyView);
  end
  else if CheckSecret('game1') then
    SelectEpisode(1, 0)
  else if CheckSecret('game2') and not FState.Demo then
    SelectEpisode(2, 8)
  else if CheckSecret('game3') and not FState.Demo then
    SelectEpisode(3, 16)
  else if CheckSecret('score10000') then
    FHealth.AddScore(10000)
  else if CheckSecret('score20000') then
    FHealth.AddScore(20000)
  else if CheckSecret('score50000') then
    FHealth.AddScore(50000)
  else if Length(FState.SecretBuf) > 2 then
  begin
    if Pos('GO', Upper(FState.SecretBuf)) > 0 then
    begin
      GoCode;
      FHost.RestoreTimerHook;
    end;
    if Pos('BL', Upper(FState.SecretBuf)) > 0 then
      GiveWeapon;
  end;
end;

end.
