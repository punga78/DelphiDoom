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
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Render.Types;

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
    FColor: TWarRgba;
  public
    /// <summary>The list receives the blits (it is not owned); wr_init: one state at the origin, scale 1 and fully opaque</summary>
    constructor Create(const ABlits: TList<TWarBlit>);
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
  LBlit: TWarBlit;
begin
  LState := FStates[FTop];
  // combine the per-call scale with the render-state scale
  LCombinedX := LState.ScaleX * AScaleX;
  LCombinedY := LState.ScaleY * AScaleY;
  LBlit.FlipHorizontal := LCombinedX < 0;
  LBlit.FlipVertical := LCombinedY < 0;
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
  LBlit.Source := ASource;
  LBlit.Destination.X := LDestX;
  LBlit.Destination.Y := LDestY;
  LBlit.Destination.Width := LDestWidth;
  LBlit.Destination.Height := LDestHeight;
  LBlit.Color := FColor;
  // (u8)(alpha * 255): the number is cut to its integer part and to the low 8 bits
  LBlit.Color.A := Byte(Trunc(LOpacity));
  FBlits.Add(LBlit);
end;

end.
