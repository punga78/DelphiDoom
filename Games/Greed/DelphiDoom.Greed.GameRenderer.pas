{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the renderer of the view as the game uses it     }
{  Port of xGreed (Jim Valavanis): RF_RenderView with the                       }
{  globals that the game writes (reallight, the translation tables, colormaps,  }
{  backdrop) and DemandLoadMonster of spawn.pas                                 }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameRenderer;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types,
  DelphiDoom.Greed.Render.Assets.Intf, DelphiDoom.Greed.Render.ArchiveAssets,
  DelphiDoom.Greed.Render.FrameRenderer, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.GameRenderer.Intf, DelphiDoom.Greed.Hud.Intf,
  DelphiDoom.Greed.WeaponLight;

type
  /// <summary>
  ///   TGreedFrameRenderer and the lumps of the archive that it draws with, behind the contract of the game. The
  ///   pictures of a monster get their colour 255 turned into 0 the first time the spawner asks for them
  ///   (DemandLoadMonster), in the copy of the lump that the renderer reads
  /// </summary>
  TGreedGameRenderer = class(TInterfacedObject, IGreedGameRenderer, IGreedFrameRenderer, IGreedRenderMemory)
  strict private
    FArchive: IGreedArchive;
    FAssets: TGreedArchiveRenderAssets;
    FAssetsIntf: IGreedRenderAssets;
    FRenderer: TGreedFrameRenderer;
    FRendererIntf: IGreedFrameRenderer;
    FFixed: TArray<Boolean>;
    FLight: TGreedWeaponLight;
    FLightIntf: IGreedWeaponLight;
  public
    /// <summary>EArgumentNilException if the archive, the sprites, the clock or the random numbers are nil</summary>
    constructor Create(const AArchive: IGreedArchive; ASprites: TGreedLinkedPool<TGreedSprite>;
      const AClock: IGreedRenderClock; const ARandom: IGreedRandom);
    procedure Render(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; var AFrame: TGreedFrame);
    procedure RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    procedure RenderCamera(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    function TileLights: PGreedTileLights;
    procedure SetLights(ABlackZ: TGreedFixed);
    procedure SetFlatTranslation(AFlat, APicture: Integer);
    procedure SetWallTranslation(AWall, APicture: Integer);
    procedure LoadColorMaps(const ALumpName: string);
    procedure SetBackdrop(const APixels: TBytes);
    procedure SetActionHook(const AHook: IGreedRenderActionHook);
    procedure SetEffectsTime(ATime: Integer);
    function WeaponLight: IGreedWeaponLight;
    function TileLightReader: IGreedTileLights;
    procedure DemandLoadMonster(ALump, ACount: Integer);
    procedure SubtractAfterTileLights(AOffset, AAmount: Integer);
  end;

implementation

uses
  DelphiDoom.Greed.MonsterPictureFix, DelphiDoom.Greed.Render.State;

{ TGreedGameRenderer }

constructor TGreedGameRenderer.Create(const AArchive: IGreedArchive; ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock; const ARandom: IGreedRandom);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  FArchive := AArchive;
  FAssets := TGreedArchiveRenderAssets.Create(AArchive);
  FAssetsIntf := FAssets;
  // LoadData of intro.pas calls RF_PreloadGraphics before the game starts
  FAssets.PreloadGraphics;
  FRenderer := TGreedFrameRenderer.Create(FAssetsIntf, ASprites, AClock, ARandom);
  FRendererIntf := FRenderer;
  SetLength(FFixed, AArchive.LumpCount);
  FLight := TGreedWeaponLight.Create(FRenderer.State);
  FLightIntf := FLight;
end;

procedure TGreedGameRenderer.Render(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord;
  var AFrame: TGreedFrame);
begin
  FRenderer.Render(AWorld, APlayer, AFrame);
end;

procedure TGreedGameRenderer.RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY,
  AZ: TGreedFixed; AAngle: Integer; var AFrame: TGreedFrame);
begin
  FRenderer.RenderView(AWorld, APlayer, AX, AY, AZ, AAngle, AFrame);
end;

procedure TGreedGameRenderer.RenderCamera(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY,
  AZ: TGreedFixed; AAngle: Integer; var AFrame: TGreedFrame);
begin
  FRenderer.RenderCamera(AWorld, APlayer, AX, AY, AZ, AAngle, AFrame);
end;

function TGreedGameRenderer.TileLights: PGreedTileLights;
begin
  Result := PGreedTileLights(@FRenderer.State.RealLight[0]);
end;

procedure TGreedGameRenderer.SetLights(ABlackZ: TGreedFixed);
begin
  FRenderer.State.SetLights(ABlackZ);
end;

procedure TGreedGameRenderer.SetFlatTranslation(AFlat, APicture: Integer);
begin
  // a game with fewer flats than the original expects has nothing to animate there
  if (AFlat >= 0) and (AFlat < Length(FRenderer.State.FlatTranslation)) then
    FRenderer.State.FlatTranslation[AFlat] := APicture;
end;

procedure TGreedGameRenderer.SetWallTranslation(AWall, APicture: Integer);
begin
  if (AWall >= 0) and (AWall < Length(FRenderer.State.WallTranslation)) then
    FRenderer.State.WallTranslation[AWall] := APicture;
end;

procedure TGreedGameRenderer.LoadColorMaps(const ALumpName: string);
var
  LLump: Integer;
  LBytes: TBytes;
  LCount: Integer;
begin
  LLump := FArchive.IndexOf(ALumpName);
  if LLump < 0 then
    Exit;
  LBytes := FArchive.ReadLumpRaw(LLump);
  // the original reads the lump over the tables that are in memory: the pointers of the lights stay the same
  LCount := Length(LBytes);
  if LCount > FRenderer.State.NumColorMaps * 256 then
    LCount := FRenderer.State.NumColorMaps * 256;
  if LCount > 0 then
    Move(LBytes[0], FRenderer.State.ColorMaps^, LCount);
end;

procedure TGreedGameRenderer.SetBackdrop(const APixels: TBytes);
begin
  if Length(APixels) > 0 then
    FAssets.SetBackdrop(APixels);
end;

procedure TGreedGameRenderer.SetActionHook(const AHook: IGreedRenderActionHook);
begin
  FRenderer.ActionHook := AHook;
end;

function TGreedGameRenderer.WeaponLight: IGreedWeaponLight;
begin
  Result := FLightIntf;
end;

function TGreedGameRenderer.TileLightReader: IGreedTileLights;
begin
  Result := FLight;
end;

procedure TGreedGameRenderer.SetEffectsTime(ATime: Integer);
begin
  FRenderer.State.FxTimeCount := ATime;
end;

procedure TGreedGameRenderer.SubtractAfterTileLights(AOffset, AAmount: Integer);
var
  S: TGreedRenderState;
begin
  S := FRenderer.State;
  // the order of the declarations of r_render.pas after "actionflag: integer"
  case AOffset of
    1: S.WallGlow := S.WallGlow - AAmount;
    2: S.WallGlowIndex := S.WallGlowIndex - AAmount;
    3: S.WallRotate := S.WallRotate - AAmount;
    4: S.MapLight := S.MapLight - AAmount;
    5: S.WallFlicker1 := S.WallFlicker1 - AAmount;
    6: S.WallFlicker2 := S.WallFlicker2 - AAmount;
    7: S.WallFlicker3 := S.WallFlicker3 - AAmount;
    8: S.WallFlicker4 := S.WallFlicker4 - AAmount;
    9: S.WallFlags := S.WallFlags - AAmount;
    10: S.WallCycle := S.WallCycle - AAmount;
    11: S.FrameOn := S.FrameOn - AAmount;
  else
    if (AOffset >= 12) and (AOffset - 12 <= High(S.FrameValid)) then
      S.FrameValid[AOffset - 12] := S.FrameValid[AOffset - 12] - AAmount;
  end;
end;

procedure TGreedGameRenderer.DemandLoadMonster(ALump, ACount: Integer);
var
  LIndex: Integer;
  LBytes: TBytes;
begin
  if (ALump < 0) or (ALump >= Length(FFixed)) or FFixed[ALump] then
    Exit;
  for LIndex := ALump to ALump + ACount - 1 do
    if (LIndex < Length(FFixed)) and not FFixed[LIndex] then
    begin
      FFixed[LIndex] := True;
      // the array is the one that the renderer keeps: the fix is made where it reads
      LBytes := FAssets.SpriteLump(LIndex);
      TGreedMonsterPictureFix.Apply(LBytes);
    end;
end;

end.
