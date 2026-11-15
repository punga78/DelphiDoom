{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the mapping of view angles to columns        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the tables of R_InitTextureMapping of r_main.pas (from r_main.c     }
{  of Linux Doom)                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.TextureMapping;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Fills the tables that map the angles of the view to the columns of the screen and
  ///   back, from the focal length: viewangletox gives the next greatest x after a view
  ///   angle, xtoviewangle the smallest view angle that maps to x. It is done when the size
  ///   of the view changes, never for a frame
  /// </summary>
  TRendererTextureMappingBuilder = class(TInterfacedObject, IRendererTextureMappingBuilder)
  public
    function Build(AFocalLength, ACenterXFrac, AViewWidth: Integer;
      const AFineTangent: TArray<Integer>): TRendererTextureMapping;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

// as in the engine: the angles are 32 bit unsigned numbers that wrap around
{$Q-}
{$R-}

const
  SFineTangentTooShort = 'The table of the tangents has less than half of the fine angles';
  SNegativeViewWidth = 'The width of the view is negative';

{ TRendererTextureMappingBuilder }

function TRendererTextureMappingBuilder.Build(AFocalLength, ACenterXFrac,
  AViewWidth: Integer; const AFineTangent: TArray<Integer>): TRendererTextureMapping;
var
  LIndex: Integer;
  LColumn: Integer;
  LValue: Integer;
  LAngle: Integer;
begin
  if Length(AFineTangent) < RENDERER_FINEANGLES div 2 then
    raise ERendererException.Create(SFineTangentTooShort);
  if AViewWidth < 0 then
    raise ERendererException.Create(SNegativeViewWidth);

  SetLength(Result.ViewAngleToX, RENDERER_FINEANGLES div 2);
  SetLength(Result.XToViewAngle, AViewWidth + 1);

  // use the tangent table to generate viewangletox
  for LIndex := 0 to RENDERER_FINEANGLES div 2 - 1 do
  begin
    if AFineTangent[LIndex] > RENDERER_FRACUNIT * 2 then
      LValue := -1
    else if AFineTangent[LIndex] < -RENDERER_FRACUNIT * 2 then
      LValue := AViewWidth + 1
    else
    begin
      LValue := TFixedMath.Mul(AFineTangent[LIndex], AFocalLength);
      LValue := (ACenterXFrac - LValue + (RENDERER_FRACUNIT - 1)) div RENDERER_FRACUNIT;

      if LValue < -1 then
        LValue := -1
      else if LValue > AViewWidth + 1 then
        LValue := AViewWidth + 1;
    end;
    Result.ViewAngleToX[LIndex] := LValue;
  end;

  // scan viewangletox to generate xtoviewangle: the smallest view angle that maps to x
  for LColumn := 0 to AViewWidth do
  begin
    LAngle := 0;
    while Result.ViewAngleToX[LAngle] > LColumn do
      Inc(LAngle);
    Result.XToViewAngle[LColumn] := Cardinal(LAngle) * RENDERER_ANGLE_TO_FINE_UNIT -
      RENDERER_ANGLE_90;
  end;

  // take out the fencepost cases from viewangletox
  for LIndex := 0 to RENDERER_FINEANGLES div 2 - 1 do
  begin
    if Result.ViewAngleToX[LIndex] = -1 then
      Result.ViewAngleToX[LIndex] := 0
    else if Result.ViewAngleToX[LIndex] = AViewWidth + 1 then
      Result.ViewAngleToX[LIndex] := AViewWidth;
  end;

  Result.ClipAngle := Result.XToViewAngle[0];
end;

end.
