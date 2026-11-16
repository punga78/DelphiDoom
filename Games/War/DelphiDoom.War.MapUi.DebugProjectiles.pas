{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the debug drawing of a projectile                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_entities.c (renderProjectile with           }
{  WAR_DEBUG_RENDER_PROJECTILES), (c) 2019 Alejandro Coto Gutierrez, zlib       }
{  License (see Games\War\LICENSE-war1.txt). This is an altered version, not the }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugProjectiles;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Model.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   What the flag "projectiles" adds to a projectile, before the sprite: the frame of its sprite in gray (centered on the
  ///   position), the frame of the image that is drawn in red, and a line in the color of its id from where it was shot to
  ///   where it goes, with a pixel of magenta at each end. No state: the transform is the one of the panel of the map
  /// </summary>
  TWarDebugProjectiles = class
  public
    /// <summary>The three drawings, each in its own save of the transform</summary>
    class procedure Draw(const ATransform: TWarRenderTransform; AEntity: PWarEntity; const ASprite: IWarUiSprite;
      const AFrame: TWarSpriteFrame); static;
  end;

implementation

uses
  DelphiDoom.War.MapUi.Types, DelphiDoom.War.Render.ColorList.Data;

const
  /// <summary>WAR_COLOR_RGB(255, 0, 255)</summary>
  MAGENTA: TWarRgba = (R: 255; G: 0; B: 255; A: 255);

{ TWarDebugProjectiles }

class procedure TWarDebugProjectiles.Draw(const ATransform: TWarRenderTransform; AEntity: PWarEntity;
  const ASprite: IWarUiSprite; const AFrame: TWarSpriteFrame);
var
  LRect: TWarRectF;
  LHalfWidth: Single;
  LHalfHeight: Single;
  LPoint: TWarRectF;
begin
  // the frame of the sprite, centered on the position (-(f32)frameWidth / 2)
  ATransform.Save;
  LHalfWidth := -Single(ASprite.FrameWidth);
  LHalfWidth := LHalfWidth / 2;
  LHalfHeight := -Single(ASprite.FrameHeight);
  LHalfHeight := LHalfHeight / 2;
  ATransform.Translate(LHalfWidth, LHalfHeight);
  ATransform.Translate(AEntity^.Position.X, AEntity^.Position.Y);
  LRect.X := 0;
  LRect.Y := 0;
  LRect.Width := ASprite.FrameWidth;
  LRect.Height := ASprite.FrameHeight;
  ATransform.FillRect(LRect, WAR_MAPUI_GRAY_TRANSPARENT);
  ATransform.Restore;
  // the frame that is drawn
  ATransform.Save;
  LHalfWidth := -Single(AFrame.Width);
  LHalfWidth := LHalfWidth / 2;
  LHalfHeight := -Single(AFrame.Height);
  LHalfHeight := LHalfHeight / 2;
  ATransform.Translate(LHalfWidth, LHalfHeight);
  ATransform.Translate(AEntity^.Position.X, AEntity^.Position.Y);
  LRect.Width := AFrame.Width;
  LRect.Height := AFrame.Height;
  ATransform.FillRect(LRect, WAR_MAPUI_RED_TRANSPARENT);
  ATransform.Restore;
  // from where it was shot to where it goes, in the color of its id (wr_getColorFromList(entity->id))
  ATransform.Save;
  ATransform.StrokeLine(AEntity^.Projectile.Origin.X, AEntity^.Projectile.Origin.Y, AEntity^.Projectile.Target.X,
    AEntity^.Projectile.Target.Y, WAR_COLOR_LIST[AEntity^.Id mod WAR_COLOR_LIST_COUNT]);
  LPoint.X := AEntity^.Projectile.Origin.X;
  LPoint.Y := AEntity^.Projectile.Origin.Y;
  LPoint.Width := 1;
  LPoint.Height := 1;
  ATransform.FillRect(LPoint, MAGENTA);
  LPoint.X := AEntity^.Projectile.Target.X;
  LPoint.Y := AEntity^.Projectile.Target.Y;
  ATransform.FillRect(LPoint, MAGENTA);
  ATransform.Restore;
end;

end.
