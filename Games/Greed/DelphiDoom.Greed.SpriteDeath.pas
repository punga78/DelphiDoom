{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what happens when a sprite dies                  }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): KillSprite of utils.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteDeath;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool;

const
  /// <summary>The ids of the kinds of sprites (protos_h.pas) that KillSprite knows</summary>
  GREED_S_CLONE = 605;
  GREED_S_TIME_MINE = 137;
  GREED_S_EXPLODE = 525;
  GREED_S_METAL_PARTS = 607;
  GREED_S_MONSTER1 = 75;
  GREED_S_MONSTER2 = 77;
  GREED_S_MONSTER3 = 79;
  GREED_S_MONSTER4 = 81;
  GREED_S_MONSTER5 = 98;
  GREED_S_MONSTER6 = 84;
  GREED_S_MONSTER7 = 86;
  GREED_S_MONSTER8 = 88;
  GREED_S_MONSTER9 = 90;
  GREED_S_MONSTER10 = 92;
  GREED_S_MONSTER11 = 94;
  GREED_S_MONSTER12 = 96;
  GREED_S_MONSTER13 = 34;
  GREED_S_MONSTER14 = 36;
  GREED_S_MONSTER15 = 38;
  /// <summary>SN_EXPLODE1, the death sounds are listed in the unit</summary>
  GREED_SN_EXPLODE1 = 22;
  /// <summary>ANIM_SELFDEST: the animation removes the sprite at its end</summary>
  GREED_ANIM_SELF_DESTRUCT = 32768;

type
  /// <summary>What dying asks to the rest of the game</summary>
  IGreedDeathHost = interface
    ['{91E4D2A7-6C08-4B35-8F1D-4A7B03E5C926}']
    /// <summary>MS_RndT: the next number of the random table of the game (0..255)</summary>
    function RandomNumber: Integer;
    /// <summary>clock: the system clock of the game, of which only the lowest bit is used</summary>
    function GetClock: Integer;
    /// <summary>playernum</summary>
    function GetPlayerNumber: Integer;
    /// <summary>CA_GetNamedNum(charnames[0]): the first lump of the sprites of the first character</summary>
    function GetFirstCharacterLump: Integer;
    /// <summary>RunEvent(eval, false)</summary>
    procedure RunEvent(AEvent: Integer);
    /// <summary>SoundEffect(sound, variation, x, y)</summary>
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    /// <summary>
    ///   SpawnSprite(kind, x, y, z, 0, 0, 0, false, owner): a new sprite of the pool; its index (the original gives
    ///   the pointer)
    /// </summary>
    function SpawnSprite(AKind, AX, AY, AZ, AOwner: Integer): Integer;
  end;

  /// <summary>
  ///   KillSprite: the death event of the sprite runs; a clone turns into a time mine (the first character) or a
  ///   corpse; a monster of the kinds 1, 2, 5, 7..10 and 12..15 gets the dead picture and its death sound and stays
  ///   as a corpse; the monsters 3 and 4 explode and go away; the monsters 6 and 11 (the machines) throw metal parts
  ///   and explosions and go away. Another kind is a mistake of the game (EGreedException)
  /// </summary>
  TGreedSpriteDeath = class
  strict private
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FHost: IGreedDeathHost;
    procedure Corpse(var ASprite: TGreedSprite; ADeathSound: Integer);
  public
    constructor Create(ASprites: TGreedLinkedPool<TGreedSprite>; const AHost: IGreedDeathHost);
    /// <summary>The sprite at AIndex of the pool dies (the weapon of the original is not used)</summary>
    procedure Kill(AIndex: Integer);
  end;

implementation

{ TGreedSpriteDeath }

constructor TGreedSpriteDeath.Create(ASprites: TGreedLinkedPool<TGreedSprite>; const AHost: IGreedDeathHost);
begin
  inherited Create;
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FSprites := ASprites;
  FHost := AHost;
end;

procedure TGreedSpriteDeath.Corpse(var ASprite: TGreedSprite; ADeathSound: Integer);
begin
  ASprite.BasePic := ASprite.StartPic + 48;
  ASprite.Animation := 0 + (0 shl 1) + (8 shl 5) + ((2 + FHost.RandomNumber and 3) shl 9);
  FHost.PlaySound(ADeathSound, 7, ASprite.X, ASprite.Y);
  ASprite.Rotate := grOne;
  ASprite.Heat := 0;
  ASprite.Active := False;
  ASprite.MoveSpeed := 0;
  ASprite.HitPoints := 0;
end;

procedure TGreedSpriteDeath.Kill(AIndex: Integer);
var
  LSprite: TGreedLinkedPool<TGreedSprite>.PItem;
  LNew: Integer;
  LCount: Integer;
  LX, LY, LZ: TGreedFixed;
begin
  LSprite := FSprites.Item(AIndex);
  if LSprite^.DeathEvent <> 0 then
    FHost.RunEvent(LSprite^.DeathEvent);
  case LSprite^.Kind of
    GREED_S_CLONE:
      begin
        if LSprite^.StartPic = FHost.GetFirstCharacterLump then
        begin
          LNew := FHost.SpawnSprite(GREED_S_TIME_MINE, LSprite^.X, LSprite^.Y, 0, FHost.GetPlayerNumber);
          // the spawn may have used the pool: the pointer of the sprite stays valid, the pool does not move
          FSprites.Item(LNew)^.BasePic := LSprite^.StartPic + 40;
          FSprites.Item(LNew)^.Scale := 1;
          LSprite^.Animation := 0 + (0 shl 1) + (1 shl 5) + (0 shl 9) + GREED_ANIM_SELF_DESTRUCT;
        end
        else
          LSprite^.Animation := 0 + (0 shl 1) + (8 shl 5) + ((4 + FHost.RandomNumber and 3) shl 9);
        LSprite^.BasePic := LSprite^.StartPic + 40;
        LSprite^.Rotate := grOne;
        LSprite^.Heat := 0;
        LSprite^.Active := False;
        LSprite^.MoveSpeed := 0;
        LSprite^.HitPoints := 0;
      end;
    GREED_S_MONSTER1:
      Corpse(LSprite^, 54);
    GREED_S_MONSTER2:
      Corpse(LSprite^, 57);
    GREED_S_MONSTER5:
      Corpse(LSprite^, 66);
    GREED_S_MONSTER7:
      Corpse(LSprite^, 72);
    GREED_S_MONSTER8:
      Corpse(LSprite^, 2);
    GREED_S_MONSTER9:
      Corpse(LSprite^, 5);
    GREED_S_MONSTER10:
      Corpse(LSprite^, 8);
    GREED_S_MONSTER12:
      Corpse(LSprite^, 75);
    GREED_S_MONSTER13:
      Corpse(LSprite^, 78);
    GREED_S_MONSTER14:
      Corpse(LSprite^, 81);
    GREED_S_MONSTER15:
      Corpse(LSprite^, 84);
    GREED_S_MONSTER3:
      begin
        FHost.SpawnSprite(GREED_S_EXPLODE, LSprite^.X, LSprite^.Y, LSprite^.Z, 0);
        FHost.PlaySound(60, 7, LSprite^.X, LSprite^.Y);
        FSprites.Remove(AIndex);
      end;
    GREED_S_MONSTER4:
      begin
        FHost.SpawnSprite(GREED_S_EXPLODE, LSprite^.X, LSprite^.Y, LSprite^.Z, 0);
        FHost.PlaySound(63, 7, LSprite^.X, LSprite^.Y);
        FSprites.Remove(AIndex);
      end;
    GREED_S_MONSTER6, GREED_S_MONSTER11:
      begin
        for LCount := 0 to 29 do
          FHost.SpawnSprite(GREED_S_METAL_PARTS, LSprite^.X, LSprite^.Y, LSprite^.Z + 64 * GREED_FRACUNIT, 0);
        for LCount := 0 to 9 do
        begin
          LX := LSprite^.X + ((-64 + (FHost.RandomNumber and 127)) * GREED_FRACUNIT);
          LY := LSprite^.Y + ((-64 + (FHost.RandomNumber and 127)) * GREED_FRACUNIT);
          LZ := LSprite^.Z + ((FHost.RandomNumber and 127) * GREED_FRACUNIT);
          FHost.SpawnSprite(GREED_S_EXPLODE + (FHost.RandomNumber and 1), LX, LY, LZ, 0);
        end;
        FHost.PlaySound(GREED_SN_EXPLODE1 + (FHost.GetClock and 1), 15, LX, LY);
        FHost.PlaySound(11, 7, LSprite^.X, LSprite^.Y);
        FHost.PlaySound(11, 7, LSprite^.X, LSprite^.Y);
        FSprites.Remove(AIndex);
      end;
  else
    raise EGreedException.CreateFmt(SGreedIllegalKill, [LSprite^.Kind]);
  end;
end;

end.
