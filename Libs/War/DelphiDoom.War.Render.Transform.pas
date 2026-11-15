{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the transform of the drawing                      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_render.c (wr_init, wr_save, wr_restore,    }
{  wr_translate, wr_scale, wr_globalAlpha, wr_subImage), (c) 2019 Alejandro    }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Render.Transform;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Blitter;

type
  /// <summary>
  ///   The stack of transforms of the renderer and what an image drawn through it becomes: instead of calling SDL,
  ///   SubImage adds a TWarBlit to the list it was given. Every operation is one float (Single) operation, rounded as
  ///   the original rounds it
  /// </summary>
  TWarRenderTransform = class
  strict private
    FStates: array[0..WAR_MAX_RENDER_STATE_STACK - 1] of TWarRenderState;
    FTop: Integer;
    FBlits: TList<TWarBlit>;
    FTarget: TWarImageBlitter;
    FColor: TWarRgba;
    function MakeBlit(const ASource, ADestination: TWarRectF; AScaleX, AScaleY: Single): TWarBlit;
    function TransformRect(const ARect: TWarRectF): TWarRectF;
    function StateColor(const AColor: TWarRgba): TWarRgba;
  public
    /// <summary>The list receives the blits (it is not owned); wr_init: one state at the origin, scale 1 and fully opaque</summary>
    constructor Create(const ABlits: TList<TWarBlit>); overload;
    /// <summary>
    ///   The blits are drawn on ATarget (not owned) as they are made, without a list: the way the renderer of the
    ///   game works (no allocation, no call through an interface for every image)
    /// </summary>
    constructor Create(const ATarget: TWarImageBlitter); overload;
    /// <summary>wr_init: back to one state at the origin, scale 1, fully opaque and a white color mod (every frame starts so)</summary>
    procedure Reset;
    /// <summary>
    ///   wr_subImage on a texture: the blit is made as SubImage makes it and drawn on the target (and added to the list, if
    ///   there is one). EWarException if there is no target
    /// </summary>
    procedure SubImageOf(const ATexture: TWarImage; const ASource, ADestination: TWarRectF; AScaleX, AScaleY: Single);
    /// <summary>wr_fillRect: the rectangle is transformed (a negative size moves the origin) and filled blending the color, its alpha times the state alpha</summary>
    procedure FillRect(const ARect: TWarRectF; const AColor: TWarRgba);
    /// <summary>wr_strokeRect: the same for the outline</summary>
    procedure StrokeRect(const ARect: TWarRectF; const AColor: TWarRgba);
    /// <summary>wr_save; EWarException if the 32 states are used (the original asserts)</summary>
    procedure Save;
    /// <summary>wr_restore; EWarException if there is no state to go back to</summary>
    procedure Restore;
    /// <summary>wr_translate: the offset moves by the amount in the units of the current scale</summary>
    procedure Translate(ATranslateX, ATranslateY: Single);
    /// <summary>wr_scale</summary>
    procedure Scale(AScaleX, AScaleY: Single);
    /// <summary>wr_globalAlpha</summary>
    procedure GlobalAlpha(AAlpha: Single);
    /// <summary>SDL_SetTextureColorMod of the image the next blits use</summary>
    procedure SetColorMod(ARed, AGreen, ABlue: Byte);
    /// <summary>
    ///   wr_subImage: the part ASource of the image goes to ADestination scaled by the state and by AScaleX, AScaleY. A
    ///   negative total scale flips the image; a negative scale of the state moves the origin of the rectangle
    /// </summary>
    procedure SubImage(const ASource, ADestination: TWarRectF; AScaleX, AScaleY: Single);
    /// <summary>The state in use</summary>
    function CurrentState: TWarRenderState;
    /// <summary>States saved above the first</summary>
    property Depth: Integer read FTop;
  end;

implementation

{ TWarRenderTransform }

constructor TWarRenderTransform.Create(const ABlits: TList<TWarBlit>);
begin
  inherited Create;
  FBlits := ABlits;
  Reset;
end;

constructor TWarRenderTransform.Create(const ATarget: TWarImageBlitter);
begin
  inherited Create;
  FTarget := ATarget;
  Reset;
end;

procedure TWarRenderTransform.Reset;
begin
  FTop := 0;
  FStates[0].OffsetX := 0;
  FStates[0].OffsetY := 0;
  FStates[0].ScaleX := 1;
  FStates[0].ScaleY := 1;
  FStates[0].Alpha := 1;
  FColor.R := 255;
  FColor.G := 255;
  FColor.B := 255;
  FColor.A := 255;
end;

procedure TWarRenderTransform.FillRect(const ARect: TWarRectF; const AColor: TWarRgba);
var
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  if not Assigned(FTarget) then
    raise EWarException.Create(SWarRenderNoTarget);
  LRect := TransformRect(ARect);
  LColor := StateColor(AColor);
  FTarget.FillRect(LRect, LColor);
end;

procedure TWarRenderTransform.StrokeRect(const ARect: TWarRectF; const AColor: TWarRgba);
var
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  if not Assigned(FTarget) then
    raise EWarException.Create(SWarRenderNoTarget);
  LRect := TransformRect(ARect);
  LColor := StateColor(AColor);
  FTarget.StrokeRect(LRect, LColor);
end;

function TWarRenderTransform.TransformRect(const ARect: TWarRectF): TWarRectF;
var
  LScaleX: Single;
  LScaleY: Single;
  LStepX: Single;
  LStepY: Single;
begin
  // renderTransformRect: a negative size flips the origin
  LScaleX := FStates[FTop].ScaleX;
  LScaleY := FStates[FTop].ScaleY;
  LStepX := ARect.X * LScaleX;
  LStepY := ARect.Y * LScaleY;
  Result.X := FStates[FTop].OffsetX + LStepX;
  Result.Y := FStates[FTop].OffsetY + LStepY;
  Result.Width := ARect.Width * LScaleX;
  Result.Height := ARect.Height * LScaleY;
  if Result.Width < 0 then
  begin
    LStepX := Result.X + Result.Width;
    Result.X := LStepX;
    Result.Width := -Result.Width;
  end;
  if Result.Height < 0 then
  begin
    LStepY := Result.Y + Result.Height;
    Result.Y := LStepY;
    Result.Height := -Result.Height;
  end;
end;

function TWarRenderTransform.StateColor(const AColor: TWarRgba): TWarRgba;
var
  LAlpha: Single;
begin
  // wr_renderSetDrawColor: (u8)(color.a * alpha)
  Result := AColor;
  LAlpha := AColor.A * FStates[FTop].Alpha;
  Result.A := Byte(Trunc(LAlpha));
end;

procedure TWarRenderTransform.Save;
begin
  if FTop + 1 >= WAR_MAX_RENDER_STATE_STACK then
    raise EWarException.CreateFmt(SWarRenderStackFull, [WAR_MAX_RENDER_STATE_STACK]);
  FStates[FTop + 1] := FStates[FTop];
  Inc(FTop);
end;

procedure TWarRenderTransform.Restore;
begin
  if FTop <= 0 then
    raise EWarException.Create(SWarRenderStackEmpty);
  Dec(FTop);
end;

procedure TWarRenderTransform.Translate(ATranslateX, ATranslateY: Single);
var
  LStepX: Single;
  LStepY: Single;
begin
  // each product and each sum is rounded to a float, as in the original (the x87 would keep more bits)
  LStepX := ATranslateX * FStates[FTop].ScaleX;
  LStepY := ATranslateY * FStates[FTop].ScaleY;
  FStates[FTop].OffsetX := FStates[FTop].OffsetX + LStepX;
  FStates[FTop].OffsetY := FStates[FTop].OffsetY + LStepY;
end;

procedure TWarRenderTransform.Scale(AScaleX, AScaleY: Single);
var
  LScaleX: Single;
  LScaleY: Single;
begin
  LScaleX := FStates[FTop].ScaleX * AScaleX;
  LScaleY := FStates[FTop].ScaleY * AScaleY;
  FStates[FTop].ScaleX := LScaleX;
  FStates[FTop].ScaleY := LScaleY;
end;

procedure TWarRenderTransform.GlobalAlpha(AAlpha: Single);
var
  LAlpha: Single;
begin
  LAlpha := FStates[FTop].Alpha * AAlpha;
  FStates[FTop].Alpha := LAlpha;
end;

procedure TWarRenderTransform.SetColorMod(ARed, AGreen, ABlue: Byte);
begin
  FColor.R := ARed;
  FColor.G := AGreen;
  FColor.B := ABlue;
end;

function TWarRenderTransform.CurrentState: TWarRenderState;
begin
  Result := FStates[FTop];
end;

procedure TWarRenderTransform.SubImage(const ASource, ADestination: TWarRectF; AScaleX, AScaleY: Single);
var
  LBlit: TWarBlit;
begin
  LBlit := MakeBlit(ASource, ADestination, AScaleX, AScaleY);
  if Assigned(FBlits) then
    FBlits.Add(LBlit);
end;

procedure TWarRenderTransform.SubImageOf(const ATexture: TWarImage; const ASource, ADestination: TWarRectF;
  AScaleX, AScaleY: Single);
var
  LBlit: TWarBlit;
begin
  if not Assigned(FTarget) then
    raise EWarException.Create(SWarRenderNoTarget);
  LBlit := MakeBlit(ASource, ADestination, AScaleX, AScaleY);
  if Assigned(FBlits) then
    FBlits.Add(LBlit);
  FTarget.Draw(ATexture, LBlit);
end;

function TWarRenderTransform.MakeBlit(const ASource, ADestination: TWarRectF; AScaleX, AScaleY: Single): TWarBlit;
var
  LState: TWarRenderState;
  LCombinedX: Single;
  LCombinedY: Single;
  LAbsX: Single;
  LAbsY: Single;
  LStepX: Single;
  LStepY: Single;
  LDestX: Single;
  LDestY: Single;
  LDestWidth: Single;
  LDestHeight: Single;
  LOpacity: Single;
begin
  LState := FStates[FTop];
  // combine the per-call scale with the render-state scale
  LCombinedX := LState.ScaleX * AScaleX;
  LCombinedY := LState.ScaleY * AScaleY;
  Result.FlipHorizontal := LCombinedX < 0;
  Result.FlipVertical := LCombinedY < 0;
  if LCombinedX < 0 then
    LAbsX := -LCombinedX
  else
    LAbsX := LCombinedX;
  if LCombinedY < 0 then
    LAbsY := -LCombinedY
  else
    LAbsY := LCombinedY;
  LStepX := ADestination.X * LState.ScaleX;
  LStepY := ADestination.Y * LState.ScaleY;
  LDestX := LState.OffsetX + LStepX;
  LDestY := LState.OffsetY + LStepY;
  LDestWidth := ADestination.Width * LAbsX;
  LDestHeight := ADestination.Height * LAbsY;
  // if the scale of the state is negative, the origin moves
  if LState.ScaleX < 0 then
  begin
    LStepX := LDestX - LDestWidth;
    LDestX := LStepX;
  end;
  if LState.ScaleY < 0 then
  begin
    LStepY := LDestY - LDestHeight;
    LDestY := LStepY;
  end;
  LOpacity := LState.Alpha * 255;
  Result.Source := ASource;
  Result.Destination.X := LDestX;
  Result.Destination.Y := LDestY;
  Result.Destination.Width := LDestWidth;
  Result.Destination.Height := LDestHeight;
  Result.Color := FColor;
  // (u8)(alpha * 255): the number is cut to its integer part and to the low 8 bits
  Result.Color.A := Byte(Trunc(LOpacity));
end;

end.
