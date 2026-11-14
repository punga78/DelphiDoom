{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixActionRules                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the arithmetic of radix_actions.pas, of RX_LightLevel and           }
{  RX_RadixX2Doom/RX_RadixY2Doom (radix_map_extra.pas), of G_ExitRadixLevel    }
{  and G_DoCompleted (g_game.pas), of RX_PlayerMessage (radix_player.pas) and  }
{  of S_GetWaveLength (radix_sounds.pas) of Rad-X, without the engine          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Action.Rules;

interface

uses
  System.SysUtils;

type
  /// <summary>Where an "end of level" action sends the game</summary>
  TRadixExitKind = (
    /// <summary>The next level of the episode</summary>
    rekNextLevel,
    /// <summary>The secret level of the episode (the ninth)</summary>
    rekSecretLevel,
    /// <summary>The level that the action names (the way back from the secret level)</summary>
    rekNamedLevel,
    /// <summary>The episode is over</summary>
    rekVictory);

  TRadixExit = record
    Kind: TRadixExitKind;
    /// <summary>The level to go to, 1 based; 0 for a victory</summary>
    Map: Integer;
  end;

  /// <summary>The numbers that the actions of the levels of Radix are made of</summary>
  TRadixActionRules = class
  public
    const
      TIC_RATE = 35;
      /// <summary>A message is not shown again before this many tics (MSGTIMEOUT)</summary>
      MESSAGE_TIMEOUT = 4 * TIC_RATE;
      /// <summary>The tics before a sound without a known length is played again</summary>
      UNKNOWN_SOUND_REPEAT = 10 * TIC_RATE;
      /// <summary>A moving surface faster than this moves 2^10 units a tic (MOVINGSURFACETHRESHHOLD)</summary>
      SURFACE_SPEED_THRESHOLD = 10;
      /// <summary>The speed of the "new moving surface" that means ten units a tic</summary>
      SURFACE_SPEED_TEN = 35;
      SECRET_MAP = 9;
      LAST_MAP = 8;
      /// <summary>The vertical momentum (fixed point) that a gravity sector cannot push past</summary>
      GRAVITY_MOMENTUM_LIMIT = 16 * 65536;
      GRAVITY_MOMENTUM_UNIT = 8192;
  public
    /// <summary>
    ///   The light of a sector of the engine (0..255) from the one of Radix (0..63; more in the
    ///   sectors with fog). A sector with fog or darkness spreads it on the whole range; the
    ///   others stay bright. Kept from the old code: a level past 111 in a sector without fog
    ///   wraps around the byte
    /// </summary>
    class function LightLevel(ALevel: Integer; ASectorFlags: Integer): Byte; static;
    /// <summary>The next level of a light that goes up and down between two levels; ARising turns at the ends</summary>
    class function Oscillate(ACurrent, AMinimum, AMaximum: Integer; var ARising: Boolean): Integer; static;
    /// <summary>
    ///   The units that a moving surface (action 1) or a "new" one (action 13) moves in a tic,
    ///   always positive
    /// </summary>
    class function SurfaceStep(ASpeed: Integer; ANewSurface: Boolean): Integer; static;
    /// <summary>A point of RADIX.DAT in the Doom map; ASplitMap is the level with two halves (E3M2)</summary>
    class function RadixToDoomX(ARadixX: Integer; ASplitMap: Boolean): Integer; static;
    class function RadixToDoomY(ARadixX, ARadixY: Integer; ASplitMap: Boolean): Integer; static;
    /// <summary>
    ///   Where the "end of level" action goes: AReturnValue -1 is the end of the episode, 0 the
    ///   next level, 9 the secret level, another number that level. The eighth level always ends
    ///   the episode
    /// </summary>
    class function ExitOf(AReturnValue: Integer; ACurrentMap: Integer): TRadixExit; static;
    /// <summary>
    ///   True when the kills of the player are enough for a "kill ratio" action (also when the
    ///   level has no enemy to kill)
    /// </summary>
    class function KillRatioReached(ARadixEnemies, ATotalKills, APlayerKills, APercentage: Integer): Boolean; static;
    /// <summary>
    ///   The same test with the enemies still alive, for the ones that died without the player.
    ///   Kept from the old code: the division is done before the subtraction
    /// </summary>
    class function KillRatioReachedByLiving(ARadixEnemies, ALiving, ATotalKills, APercentage: Integer): Boolean; static;
    /// <summary>The damage of a "hurt player" explosion at ADistance units; 0 from AMaxRadius on</summary>
    class function ExplosionDamage(AHitPointsAtCenter, ASpawnShield, AMaxRadius, ADistance: Integer): Integer; static;
    /// <summary>The new vertical momentum of a craft in a gravity sector (ADirection 1 or -1, AStrength 0..3)</summary>
    class function GravityMomentum(AMomentumZ, ADirection, AStrength: Integer): Integer; static;
    /// <summary>True when a message shown the last time at ALastTime (0: never) can be shown again</summary>
    class function CanShowMessage(ALastTime, ALevelTime: Integer): Boolean; static;
    /// <summary>The damage that a shot does to a wall: the damage plus up to twice as much, by ARandom (0..255)</summary>
    class function WallDamage(ADamage, ARandom: Integer): Integer; static;
    /// <summary>
    ///   The length in tics of a sound of RADIX.DAT (a RIFF WAVE file): the bytes of its data
    ///   chunk at the bytes per second of its format chunk. -1 when the bytes are not such a file
    /// </summary>
    class function WaveDurationTics(const AWave: TBytes): Integer; static;
    /// <summary>The lump of the sound of RADIX.DAT with that number, as the translation names it</summary>
    class function SoundLumpName(ASound: Integer): string; static;
    /// <summary>
    ///   The momentum (fixed point, one axis) of a craft that a transporter carries from AStart
    ///   to ATarget in AStartTics tics, when ATicsLeft are left: it grows from nothing to twice
    ///   the mean speed. 0 when no tic is left
    /// </summary>
    class function TranspoMomentum(AStart, ATarget, AStartTics, ATicsLeft: Integer): Integer; static;
    /// <summary>The angle (the whole turn is 2^32) of the craft on the way, by the shorter side when it crosses 0</summary>
    class function TranspoAngle(AStart, ATarget: Cardinal; ATicsLeft, AStartTics: Integer): Cardinal; static;
    /// <summary>
    ///   True when the wall from (AX1, AY1) to (AX2, AY2) is in front of a shot that was at
    ///   APointX, APointY and went along ADirectionX, ADirectionY (any length, not both 0), with
    ///   ADistance from the shot to the nearest point of the wall. A wall that the shot already
    ///   touches (less than one unit away) is in front of it whatever the direction
    /// </summary>
    class function WallAhead(APointX, APointY, ADirectionX, ADirectionY, AX1, AY1, AX2, AY2: Double;
      out ADistance: Double): Boolean; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Radix.Level.Types;

{ TRadixActionRules }

class function TRadixActionRules.LightLevel(ALevel: Integer; ASectorFlags: Integer): Byte;
begin
  if ASectorFlags and (RSF_FOG or RSF_DARKNESS) = 0 then
    Result := Byte((200 + ALevel div 2) and $FF)
  else if ALevel >= RADIX_MAX_LIGHT_LEVEL then
    Result := 255
  else
    Result := Byte((ALevel * 4 + 2) and $FF);
end;

class function TRadixActionRules.Oscillate(ACurrent, AMinimum, AMaximum: Integer; var ARising: Boolean): Integer;
begin
  if ARising then
  begin
    Result := EnsureRange(ACurrent + 1, AMinimum, AMaximum);
    if Result = AMaximum then
      ARising := False;
  end
  else
  begin
    Result := EnsureRange(ACurrent - 1, AMinimum, AMaximum);
    if Result = AMinimum then
      ARising := True;
  end;
end;

class function TRadixActionRules.SurfaceStep(ASpeed: Integer; ANewSurface: Boolean): Integer;
begin
  if ANewSurface and (ASpeed = SURFACE_SPEED_TEN) then
    Result := 10
  else if ASpeed > SURFACE_SPEED_THRESHOLD then
    Result := 1 shl SURFACE_SPEED_THRESHOLD
  else if ASpeed < 0 then
    Result := 1
  else
    Result := 1 shl ASpeed;
end;

class function TRadixActionRules.RadixToDoomX(ARadixX: Integer; ASplitMap: Boolean): Integer;
begin
  if ASplitMap and (ARadixX > E3M2_SPLIT_X) then
    Result := ARadixX * RADIX_MAP_X_MULT + RADIX_MAP_X_ADD2
  else
    Result := ARadixX * RADIX_MAP_X_MULT + RADIX_MAP_X_ADD;
end;

class function TRadixActionRules.RadixToDoomY(ARadixX, ARadixY: Integer; ASplitMap: Boolean): Integer;
begin
  if ASplitMap and (ARadixX > E3M2_SPLIT_X) then
    Result := ARadixY * RADIX_MAP_Y_MULT + RADIX_MAP_Y_ADD2
  else
    Result := ARadixY * RADIX_MAP_Y_MULT + RADIX_MAP_Y_ADD;
end;

class function TRadixActionRules.ExitOf(AReturnValue: Integer; ACurrentMap: Integer): TRadixExit;
begin
  if (AReturnValue = -1) or (ACurrentMap = LAST_MAP) then
  begin
    Result.Kind := rekVictory;
    Result.Map := 0;
  end
  else if AReturnValue = 0 then
  begin
    Result.Kind := rekNextLevel;
    Result.Map := ACurrentMap + 1;
  end
  else if AReturnValue = SECRET_MAP then
  begin
    Result.Kind := rekSecretLevel;
    Result.Map := SECRET_MAP;
  end
  else
  begin
    Result.Kind := rekNamedLevel;
    Result.Map := AReturnValue;
  end;
end;

class function TRadixActionRules.KillRatioReached(ARadixEnemies, ATotalKills, APlayerKills,
  APercentage: Integer): Boolean;
begin
  Result := (ARadixEnemies = 0) or (ATotalKills = 0) or (APlayerKills >= ATotalKills) or
    ((APlayerKills * 100) div ATotalKills >= APercentage);
end;

class function TRadixActionRules.KillRatioReachedByLiving(ARadixEnemies, ALiving, ATotalKills,
  APercentage: Integer): Boolean;
begin
  if ATotalKills = 0 then
    Exit(True);
  Result := ARadixEnemies - ALiving * 100 div ATotalKills >= APercentage;
end;

class function TRadixActionRules.ExplosionDamage(AHitPointsAtCenter, ASpawnShield, AMaxRadius,
  ADistance: Integer): Integer;
begin
  if (AMaxRadius <= 0) or (ADistance >= AMaxRadius) then
    Exit(0);
  Result := (AHitPointsAtCenter * ASpawnShield div 300) * (AMaxRadius - ADistance) div AMaxRadius;
end;

class function TRadixActionRules.GravityMomentum(AMomentumZ, ADirection, AStrength: Integer): Integer;
begin
  Result := AMomentumZ;
  if (AMomentumZ < -GRAVITY_MOMENTUM_LIMIT) or (AMomentumZ > GRAVITY_MOMENTUM_LIMIT) then
    Exit;
  Result := EnsureRange(AMomentumZ + ADirection * GRAVITY_MOMENTUM_UNIT * (1 shl (AStrength and 31)),
    -GRAVITY_MOMENTUM_LIMIT, GRAVITY_MOMENTUM_LIMIT);
end;

class function TRadixActionRules.CanShowMessage(ALastTime, ALevelTime: Integer): Boolean;
begin
  Result := (ALastTime = 0) or (ALevelTime > ALastTime + MESSAGE_TIMEOUT);
end;

class function TRadixActionRules.WallDamage(ADamage, ARandom: Integer): Integer;
begin
  Result := ADamage + (ADamage * ARandom) div 128;
end;

class function TRadixActionRules.WaveDurationTics(const AWave: TBytes): Integer;
const
  HEADER_SIZE = 12;
  CHUNK_HEADER_SIZE = 8;
  BYTES_PER_SECOND_OFFSET = 8;
var
  LPosition: Integer;
  LChunkSize: Integer;
  LBytesPerSecond: Integer;
  LDataSize: Integer;

  function Tag(AOffset: Integer; const AText: AnsiString): Boolean;
  var
    LIndex: Integer;
  begin
    Result := AOffset + Length(AText) <= Length(AWave);
    if Result then
      for LIndex := 1 to Length(AText) do
        if AWave[AOffset + LIndex - 1] <> Ord(AText[LIndex]) then
          Exit(False);
  end;

begin
  Result := -1;
  if (Length(AWave) < HEADER_SIZE) or not Tag(0, 'RIFF') or not Tag(8, 'WAVE') then
    Exit;
  LBytesPerSecond := 0;
  LDataSize := -1;
  LPosition := HEADER_SIZE;
  while LPosition + CHUNK_HEADER_SIZE <= Length(AWave) do
  begin
    Move(AWave[LPosition + 4], LChunkSize, SizeOf(LChunkSize));
    if Tag(LPosition, 'fmt ') then
    begin
      if LPosition + CHUNK_HEADER_SIZE + BYTES_PER_SECOND_OFFSET + 4 > Length(AWave) then
        Exit;
      Move(AWave[LPosition + CHUNK_HEADER_SIZE + BYTES_PER_SECOND_OFFSET], LBytesPerSecond,
        SizeOf(LBytesPerSecond));
    end
    else if Tag(LPosition, 'data') then
    begin
      LDataSize := LChunkSize;
      Break;
    end;
    if LChunkSize < 0 then
      Exit;
    // a chunk is padded to an even size
    LPosition := LPosition + CHUNK_HEADER_SIZE + LChunkSize + (LChunkSize and 1);
  end;
  if (LBytesPerSecond > 0) and (LDataSize > 0) then
    Result := Round(LDataSize / LBytesPerSecond * TIC_RATE);
end;

class function TRadixActionRules.SoundLumpName(ASound: Integer): string;
begin
  Result := Format('DS_%.5d', [ASound]);
end;

class function TRadixActionRules.WallAhead(APointX, APointY, ADirectionX, ADirectionY, AX1, AY1, AX2,
  AY2: Double; out ADistance: Double): Boolean;
const
  TOUCHING = 1.0;
var
  LWallX: Double;
  LWallY: Double;
  LLengthSquared: Double;
  LAlong: Double;
  LNearX: Double;
  LNearY: Double;
begin
  LWallX := AX2 - AX1;
  LWallY := AY2 - AY1;
  LLengthSquared := LWallX * LWallX + LWallY * LWallY;
  if LLengthSquared > 0.0 then
    LAlong := EnsureRange(((APointX - AX1) * LWallX + (APointY - AY1) * LWallY) / LLengthSquared, 0.0, 1.0)
  else
    LAlong := 0.0;
  LNearX := AX1 + LAlong * LWallX - APointX;
  LNearY := AY1 + LAlong * LWallY - APointY;
  ADistance := Sqrt(LNearX * LNearX + LNearY * LNearY);
  Result := (ADistance < TOUCHING) or (LNearX * ADirectionX + LNearY * ADirectionY > 0.0);
end;

class function TRadixActionRules.TranspoMomentum(AStart, ATarget, AStartTics, ATicsLeft: Integer): Integer;
var
  LMean: Int64;
  LHalf: Integer;
begin
  if (ATicsLeft <= 0) or (AStartTics <= 0) then
    Exit(0);
  LMean := (Int64(ATarget) - Int64(AStart)) div AStartTics;
  // the old code divided by zero for a way of one tic
  LHalf := Max(AStartTics div 2, 1);
  Result := Integer(LMean * (AStartTics - ATicsLeft) div LHalf);
end;

class function TRadixActionRules.TranspoAngle(AStart, ATarget: Cardinal; ATicsLeft, AStartTics: Integer): Cardinal;
const
  QUARTER_TURN = Cardinal($40000000);
  THREE_QUARTERS = Cardinal($C0000000);
  WHOLE_TURN = 4294967296.0;
var
  LFraction: Double;
  LStart: Double;
  LTarget: Double;
  LMiddle: Double;
begin
  if (AStart = ATarget) or (AStartTics <= 0) then
    Exit(ATarget);
  LFraction := 1.0 - ATicsLeft / AStartTics;
  if ((AStart < QUARTER_TURN) and (ATarget > THREE_QUARTERS)) or
    ((ATarget < QUARTER_TURN) and (AStart > THREE_QUARTERS)) then
  begin
    LStart := AStart / WHOLE_TURN;
    LTarget := ATarget / WHOLE_TURN;
    if AStart > ATarget then
      LTarget := LTarget + 1.0
    else
      LStart := LStart + 1.0;
    LMiddle := LStart + (LTarget - LStart) * LFraction;
    if LMiddle >= 1.0 then
      LMiddle := LMiddle - 1.0;
    Result := Cardinal(Round(LMiddle * WHOLE_TURN) and $FFFFFFFF);
  end
  else if AStart > ATarget then
    Result := AStart - Cardinal(Round((AStart - ATarget) * LFraction))
  else
    Result := AStart + Cardinal(Round((ATarget - AStart) * LFraction));
end;

end.
