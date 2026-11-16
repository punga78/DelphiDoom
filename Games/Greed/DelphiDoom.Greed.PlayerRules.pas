{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the rules of the player                          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): heal, medpaks, hurt,        }
{  addscore and newplayer of utils.pas, the tables of constant.pas              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlayerRules;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Player.Intf;

type
  /// <summary>
  ///   What happens to the record of the player (the state that the saved game keeps): health and shield, the
  ///   score, the start of a game. The things that are not in the record (god mode, the special effect, the sounds)
  ///   go through the context and the feedback that the constructor receives
  /// </summary>
  TGreedPlayerRules = class
  strict private
    FContext: IGreedPlayerContext;
    FFeedback: IGreedPlayerFeedback;
  public
    constructor Create(const AContext: IGreedPlayerContext; const AFeedback: IGreedPlayerFeedback);
    /// <summary>heal: the shield goes up, up to its maximum</summary>
    procedure Heal(var APlayer: TGreedPlayerRecord; AAmount: Integer);
    /// <summary>medpaks: the health goes up, up to its maximum; a dead player (health 0 or less) is not healed</summary>
    procedure MedPaks(var APlayer: TGreedPlayerRecord; AAmount: Integer);
    /// <summary>
    ///   hurt: not with god mode or when the player is dead. Invisibility divides the damage by 3; the reverso pill
    ///   makes it healing (half of it to the shield and half to the health). The shield takes the damage first. When
    ///   the health reaches 0 the death sound plays twice, else the hit sound (and in a net game the other players
    ///   hear it at most once in 35 tics)
    /// </summary>
    procedure Hurt(var APlayer: TGreedPlayerRecord; AAmount: Integer);
    /// <summary>addscore: the score has a limit of 2000000000 (then it restarts from 0), the level score does not go under 0</summary>
    class procedure AddScore(var APlayer: TGreedPlayerRecord; AAmount: Integer); static;
    /// <summary>
    ///   newplayer without the part that loads the map: the record for a new game of a character (0..5). The scroll
    ///   range is the height of the window; x is -1 (the player has no place yet); the first weapon of the character
    ///   and the second one, three empty slots, 100 of each ammo and the first items. EGreedException if the
    ///   character does not exist
    /// </summary>
    class procedure NewPlayer(var APlayer: TGreedPlayerRecord; AMap, ACharType, ADifficulty, ALevelScore,
      AWindowHeight: Integer); static;
  end;

implementation

const
  PLAYER_MOVE_SPEED = (GREED_FRACUNIT * 5) div 2;
  NET_HURT_SOUND_PERIOD = 35;
  MAXIMUM_SCORE = 2000000000;

  HEIGHTS: array[0..GREED_CHAR_TYPES - 1] of Integer = (
    42 * GREED_FRACUNIT, 35 * GREED_FRACUNIT, 50 * GREED_FRACUNIT, 35 * GREED_FRACUNIT, 38 * GREED_FRACUNIT,
    32 * GREED_FRACUNIT);
  MAX_SHIELDS: array[0..GREED_CHAR_TYPES - 1] of Integer = (700, 400, 500, 300, 500, 700);
  MAX_ANGSTS: array[0..GREED_CHAR_TYPES - 1] of Integer = (600, 400, 700, 500, 500, 700);
  WALK_MODS: array[0..GREED_CHAR_TYPES - 1] of Integer = (
    -PLAYER_MOVE_SPEED, PLAYER_MOVE_SPEED, -PLAYER_MOVE_SPEED, PLAYER_MOVE_SPEED, 0, PLAYER_MOVE_SPEED * 3 div 2);
  RUN_MODS: array[0..GREED_CHAR_TYPES - 1] of Integer = (
    -PLAYER_MOVE_SPEED, PLAYER_MOVE_SPEED div 2, -PLAYER_MOVE_SPEED, PLAYER_MOVE_SPEED div 2, 0,
    PLAYER_MOVE_SPEED * 2);
  JUMP_MODS: array[0..GREED_CHAR_TYPES - 1] of Integer = (-GREED_FRACUNIT, 0, 0, 0, -GREED_FRACUNIT, 0);
  // the two weapons of the start: cyborg, lizardman, mooman, specimen 7, dominatrix, bighead
  FIRST_WEAPONS: array[0..GREED_CHAR_TYPES - 1] of Integer = (7, 8, 13, 14, 15, 8);
  SECOND_WEAPONS: array[0..GREED_CHAR_TYPES - 1] of Integer = (1, 9, 11, 10, 12, 9);

{ TGreedPlayerRules }

constructor TGreedPlayerRules.Create(const AContext: IGreedPlayerContext; const AFeedback: IGreedPlayerFeedback);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  if not Assigned(AFeedback) then
    raise EArgumentNilException.Create('AFeedback');
  FContext := AContext;
  FFeedback := AFeedback;
end;

procedure TGreedPlayerRules.Heal(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  APlayer.Shield := APlayer.Shield + AAmount;
  if APlayer.Shield > APlayer.MaxShield then
    APlayer.Shield := APlayer.MaxShield;
  FFeedback.ShowHurtBorder;
end;

procedure TGreedPlayerRules.MedPaks(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  if APlayer.Angst <= 0 then
    Exit;
  APlayer.Angst := APlayer.Angst + AAmount;
  if APlayer.Angst > APlayer.MaxAngst then
    APlayer.Angst := APlayer.MaxAngst;
  FFeedback.ShowHurtBorder;
end;

procedure TGreedPlayerRules.Hurt(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  if FContext.GodMode or (APlayer.Angst = 0) then
    Exit;
  if FContext.SpecialEffect = GREED_SE_INVISIBILITY then
    AAmount := AAmount div 3;
  if FContext.SpecialEffect = GREED_SE_REVERSO_PILL then
  begin
    MedPaks(APlayer, AAmount div 2);
    Heal(APlayer, AAmount div 2);
    Exit;
  end;
  APlayer.Status := 1;
  if AAmount > APlayer.Shield then
  begin
    AAmount := AAmount - APlayer.Shield;
    APlayer.Shield := 0;
    APlayer.Angst := APlayer.Angst - AAmount;
    if APlayer.Angst < 0 then
      APlayer.Angst := 0;
  end
  else
    APlayer.Shield := APlayer.Shield - AAmount;
  FFeedback.ShowHurtBorder;
  if APlayer.Angst = 0 then
  begin
    // twice, as the original
    FFeedback.PlaySound(GREED_SN_DEATH0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
    if FContext.NetMode then
      FFeedback.PlayNetSound(GREED_SN_DEATH0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
    FFeedback.PlaySound(GREED_SN_DEATH0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
    if FContext.NetMode then
      FFeedback.PlayNetSound(GREED_SN_DEATH0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
  end
  else
  begin
    FFeedback.PlaySound(GREED_SN_HIT0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
    if FContext.NetMode and (FContext.TimeCount > FContext.NetHurtSoundTime) then
    begin
      FFeedback.PlayNetSound(GREED_SN_HIT0 + APlayer.CharType, 15, APlayer.X, APlayer.Y);
      FContext.NetHurtSoundTime := FContext.TimeCount + NET_HURT_SOUND_PERIOD;
    end;
  end;
end;

class procedure TGreedPlayerRules.AddScore(var APlayer: TGreedPlayerRecord; AAmount: Integer);
begin
  APlayer.Score := APlayer.Score + AAmount;
  if APlayer.Score > MAXIMUM_SCORE then
    APlayer.Score := 0;
  APlayer.LevelScore := APlayer.LevelScore - AAmount;
  if APlayer.LevelScore < 0 then
    APlayer.LevelScore := 0;
end;

class procedure TGreedPlayerRules.NewPlayer(var APlayer: TGreedPlayerRecord; AMap, ACharType, ADifficulty,
  ALevelScore, AWindowHeight: Integer);
begin
  if (ACharType < 0) or (ACharType >= GREED_CHAR_TYPES) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [ACharType, 'the character', 0, GREED_CHAR_TYPES - 1]);
  FillChar(APlayer, SizeOf(APlayer), 0);
  APlayer.ScrollMin := 0;
  APlayer.ScrollMax := AWindowHeight;
  APlayer.X := -1;
  APlayer.Map := AMap;
  APlayer.Height := HEIGHTS[ACharType];
  APlayer.MaxAngst := MAX_ANGSTS[ACharType];
  APlayer.MaxShield := MAX_SHIELDS[ACharType];
  APlayer.WalkMod := WALK_MODS[ACharType];
  APlayer.RunMod := RUN_MODS[ACharType];
  APlayer.JumpMod := JUMP_MODS[ACharType];
  APlayer.Shield := APlayer.MaxShield;
  APlayer.Angst := APlayer.MaxAngst;
  APlayer.LevelScore := ALevelScore;
  APlayer.CharType := ACharType;
  APlayer.Difficulty := ADifficulty;
  APlayer.Weapons[0] := FIRST_WEAPONS[ACharType];
  APlayer.Weapons[1] := SECOND_WEAPONS[ACharType];
  APlayer.Weapons[2] := -1;
  APlayer.Weapons[3] := -1;
  APlayer.Weapons[4] := -1;
  APlayer.Ammo[0] := 100;
  APlayer.Ammo[1] := 100;
  APlayer.Ammo[2] := 100;
  APlayer.Inventory[7] := 2;
  APlayer.Inventory[5] := 2;
  APlayer.Inventory[4] := 2;
  APlayer.Inventory[2] := 4;
end;

end.
