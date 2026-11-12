{******************************************************************************}
{                                                                              }
{  Greed32: the state of a game as text, for the proofs without a keyboard     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameDump;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Game;

type
  /// <summary>
  ///   What Greed32 -dump writes at the end of a game: the map, the clocks, the player (place, health, shield,
  ///   weapons, ammunition, inventory, score, kills), how many sprites of each kind are in the level, the
  ///   elevators, the doors and the spawn areas. One "name=value" for each line, the kinds of the sprites in
  ///   order, so two games can be compared as text
  /// </summary>
  TGreedGameDump = class
  public
    /// <summary>ATics and AFrames are the ones of the loop of the program (the clock of the game restarts at every map)</summary>
    class procedure Write(AGame: TGreedGame; ATics, AFrames, ARandomOffset: Integer; ALines: TStrings); static;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.World.Intf;

{ TGreedGameDump }

class procedure TGreedGameDump.Write(AGame: TGreedGame; ATics, AFrames, ARandomOffset: Integer; ALines: TStrings);
var
  S: TGreedGameState;
  LCounts: TDictionary<Integer, Integer>;
  LKinds: TArray<Integer>;
  LIndex, LKind, LCount, LActive, LDead, LOpen: Integer;
  LSprite: PGreedSprite;
  LText: string;
begin
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(ALines) then
    raise EArgumentNilException.Create('ALines');
  S := AGame.State;
  ALines.Add(Format('map=%d', [S.Player.Map]));
  ALines.Add(Format('tics=%d', [ATics]));
  ALines.Add(Format('frames=%d', [AFrames]));
  ALines.Add(Format('timecount=%d', [S.TimeCount]));
  ALines.Add(Format('rndofs=%d', [ARandomOffset]));
  ALines.Add(Format('quitgame=%d', [Ord(S.QuitGame)]));
  ALines.Add(Format('warping=%d lighting=%d changelight=%d exitexists=%d godmode=%d', [S.Warping, S.Lighting,
    S.ChangeLight, Ord(S.ExitExists), Ord(S.GodMode)]));
  ALines.Add(Format('player.x=%d', [S.Player.X]));
  ALines.Add(Format('player.y=%d', [S.Player.Y]));
  ALines.Add(Format('player.z=%d', [S.Player.Z]));
  ALines.Add(Format('player.tile=%d,%d', [S.Player.X div GREED_FRACTILEUNIT, S.Player.Y div GREED_FRACTILEUNIT]));
  ALines.Add(Format('player.angle=%d', [S.Player.Angle]));
  ALines.Add(Format('player.angst=%d', [S.Player.Angst]));
  ALines.Add(Format('player.shield=%d', [S.Player.Shield]));
  ALines.Add(Format('player.chartype=%d', [S.Player.CharType]));
  ALines.Add(Format('player.difficulty=%d', [S.Player.Difficulty]));
  ALines.Add(Format('player.currentweapon=%d', [S.Player.CurrentWeapon]));
  ALines.Add(Format('player.weapons=%d,%d,%d,%d,%d', [S.Player.Weapons[0], S.Player.Weapons[1],
    S.Player.Weapons[2], S.Player.Weapons[3], S.Player.Weapons[4]]));
  ALines.Add(Format('player.ammo=%d,%d,%d', [S.Player.Ammo[0], S.Player.Ammo[1], S.Player.Ammo[2]]));
  LText := '';
  for LIndex := Low(S.Player.Inventory) to High(S.Player.Inventory) do
  begin
    if LIndex > Low(S.Player.Inventory) then
      LText := LText + ',';
    LText := LText + IntToStr(S.Player.Inventory[LIndex]);
  end;
  ALines.Add('player.inventory=' + LText);
  ALines.Add(Format('inventorycursor=%d', [AGame.Inventory.Cursor]));
  ALines.Add(Format('player.score=%d', [S.Player.Score]));
  ALines.Add(Format('player.levelscore=%d', [S.Player.LevelScore]));
  ALines.Add(Format('player.bodycount=%d', [S.Player.BodyCount]));
  ALines.Add(Format('player.primaries=%d,%d', [S.Player.Primaries[0], S.Player.Primaries[1]]));
  LCounts := TDictionary<Integer, Integer>.Create;
  try
    LActive := 0;
    LDead := 0;
    LIndex := S.Sprites.First;
    while LIndex <> GREED_POOL_NIL do
    begin
      LSprite := PGreedSprite(S.Sprites.Item(LIndex));
      if not LCounts.TryGetValue(LSprite^.Kind, LCount) then
        LCount := 0;
      LCounts.AddOrSetValue(LSprite^.Kind, LCount + 1);
      if LSprite^.Active then
        Inc(LActive);
      if (LSprite^.HitPoints = 0) and (LSprite^.Intelligence <> 0) then
        Inc(LDead);
      LIndex := S.Sprites.Next(LIndex);
    end;
    ALines.Add(Format('sprites=%d', [S.Sprites.Count]));
    ALines.Add(Format('sprites.active=%d', [LActive]));
    ALines.Add(Format('sprites.thinking.nohitpoints=%d', [LDead]));
    LKinds := LCounts.Keys.ToArray;
    TArray.Sort<Integer>(LKinds);
    for LKind in LKinds do
      ALines.Add(Format('sprites.kind.%d=%d', [LKind, LCounts[LKind]]));
  finally
    LCounts.Free;
  end;
  ALines.Add(Format('elevators=%d', [S.Elevators.Count]));
  LOpen := 0;
  for LIndex := 0 to AGame.World.DoorCount - 1 do
    if AGame.World.GetDoor(LIndex).Open then
      Inc(LOpen);
  ALines.Add(Format('doors=%d', [AGame.World.DoorCount]));
  ALines.Add(Format('doors.open=%d', [LOpen]));
  ALines.Add(Format('spawnareas=%d', [AGame.World.SpawnAreaCount]));
  ALines.Add(Format('numprocesses=%d', [S.NumProcesses]));
  ALines.Add(Format('numzones=%d', [S.NumZones]));
end;

end.
