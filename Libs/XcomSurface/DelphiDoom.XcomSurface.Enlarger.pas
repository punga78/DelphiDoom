{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - pictures made a whole number of times     }
{  larger by the nearest pixel (the original pictures in a finer drawing,       }
{  issue 183)                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Enlarger;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomSurface.Types;

type
  /// <summary>
  ///   Copies of 8 bit pictures where every pixel becomes a square of AScale x AScale pixels of the same index.
  ///   Only the indexes are copied: the palette of the result is the caller's business
  /// </summary>
  TXcomSurfaceEnlarger = class
  public
    /// <summary>A new surface AScale times the source (its whole picture, the crop is not looked at); the caller owns it</summary>
    class function Enlarge(ASource: TXcomSurface; AScale: Integer): TXcomSurface; static;
    /// <summary>A new set with every frame of the source enlarged, under the same numbers; the caller owns it</summary>
    class function EnlargeSet(ASource: TXcomSurfaceSet; AScale: Integer): TXcomSurfaceSet; static;
    /// <summary>
    ///   Draws the source enlarged on the target with its top left corner at (AX, AY) in pixels of the target;
    ///   the color 0 of the source is transparent and what falls outside the target is cut
    /// </summary>
    class procedure BlitEnlarged(ASource, ATarget: TXcomSurface; AX, AY, AScale: Integer); static;
    /// <summary>Lays the source over a target of the same size: every pixel that is not 0 replaces the one under it</summary>
    class procedure Overlay(ASource, ATarget: TXcomSurface); static;
  end;

implementation

const
  SBadScale = 'XcomSurface: the scale of an enlarged picture is 1 or more';
  SBadOverlay = 'XcomSurface: an overlay needs two pictures of the same size';

class function TXcomSurfaceEnlarger.Enlarge(ASource: TXcomSurface; AScale: Integer): TXcomSurface;
begin
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if AScale < 1 then
    raise EXcomSurfaceException.Create(SBadScale);
  Result := TXcomSurface.Create(ASource.Width * AScale, ASource.Height * AScale);
  try
    BlitEnlarged(ASource, Result, 0, 0, AScale);
  except
    Result.Free;
    raise;
  end;
end;

class function TXcomSurfaceEnlarger.EnlargeSet(ASource: TXcomSurfaceSet; AScale: Integer): TXcomSurfaceSet;
var
  LIndex: Integer;
begin
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if AScale < 1 then
    raise EXcomSurfaceException.Create(SBadScale);
  Result := TXcomSurfaceSet.Create(ASource.Width * AScale, ASource.Height * AScale);
  try
    Result.MaxSharedFrames := ASource.MaxSharedFrames;
    for LIndex in ASource.Indexes do
      BlitEnlarged(ASource.GetFrame(LIndex), Result.AddFrame(LIndex), 0, 0, AScale);
  except
    Result.Free;
    raise;
  end;
end;

class procedure TXcomSurfaceEnlarger.BlitEnlarged(ASource, ATarget: TXcomSurface; AX, AY, AScale: Integer);
var
  LSource: TBytes;
  LTarget: TBytes;
  LSourceWidth: Integer;
  LTargetWidth: Integer;
  LTargetHeight: Integer;
  LX: Integer;
  LY: Integer;
  LSubX: Integer;
  LSubY: Integer;
  LTargetX: Integer;
  LTargetY: Integer;
  LValue: Byte;
begin
  if AScale < 1 then
    raise EXcomSurfaceException.Create(SBadScale);
  LSource := ASource.Pixels;
  LTarget := ATarget.Pixels;
  LSourceWidth := ASource.Width;
  LTargetWidth := ATarget.Width;
  LTargetHeight := ATarget.Height;
  for LY := 0 to ASource.Height - 1 do
    for LX := 0 to LSourceWidth - 1 do
    begin
      LValue := LSource[LY * LSourceWidth + LX];
      if LValue = 0 then
        Continue;
      for LSubY := 0 to AScale - 1 do
      begin
        LTargetY := AY + LY * AScale + LSubY;
        if (LTargetY < 0) or (LTargetY >= LTargetHeight) then
          Continue;
        for LSubX := 0 to AScale - 1 do
        begin
          LTargetX := AX + LX * AScale + LSubX;
          if (LTargetX >= 0) and (LTargetX < LTargetWidth) then
            LTarget[LTargetY * LTargetWidth + LTargetX] := LValue;
        end;
      end;
    end;
end;

class procedure TXcomSurfaceEnlarger.Overlay(ASource, ATarget: TXcomSurface);
var
  LSource: TBytes;
  LTarget: TBytes;
  LIndex: Integer;
begin
  if (ASource.Width <> ATarget.Width) or (ASource.Height <> ATarget.Height) then
    raise EXcomSurfaceException.Create(SBadOverlay);
  LSource := ASource.Pixels;
  LTarget := ATarget.Pixels;
  for LIndex := 0 to ASource.Width * ASource.Height - 1 do
    if LSource[LIndex] <> 0 then
      LTarget[LIndex] := LSource[LIndex];
end;

end.
