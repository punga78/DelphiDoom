{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the shading functions and the loop that   }
{  applies them (StandardShade, ColorReplace and ShaderDraw of OpenXcom)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Shade;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Intf;

type
  /// <summary>
  ///   StandardShade: a non transparent pixel keeps its color group and takes the shade added to its low four
  ///   bits; if the shade goes over 15 the pixel becomes the darkest (15)
  /// </summary>
  TXcomStandardShade = class(TInterfacedObject, IXcomShadeFunction)
  public
    procedure Apply(var ADest: Byte; ASource: Byte; AShade, ANewColor: Integer);
  end;

  /// <summary>ColorReplace: like the standard shade but the pixel gets the color group ANewColor</summary>
  TXcomColorReplaceShade = class(TInterfacedObject, IXcomShadeFunction)
  public
    procedure Apply(var ADest: Byte; ASource: Byte; AShade, ANewColor: Integer);
  end;

  /// <summary>
  ///   ShaderDraw: walks the part of the destination that the two images share and gives each pair of pixels
  ///   to a shading function. The images are the domains of the surfaces moved to their positions
  /// </summary>
  TXcomShadeDrawer = class
  public
    /// <summary>
    ///   Draws ASource (its domain, at position AX, AY) on ADestination (its domain at its own position).
    ///   Domains are intersected with the surface they belong to
    /// </summary>
    class procedure Draw(ADestination: TXcomSurface; const ADestinationDomain: TXcomGraphSubset;
      ASource: TXcomSurface; const ASourceDomain: TXcomGraphSubset; AX, AY: Integer;
      const AFunction: IXcomShadeFunction; AShade, ANewColor: Integer); static;
  end;

  /// <summary>The shaded blits of Surface (blitNShade) without the Surface class depending on the shading code</summary>
  TXcomSurfaceShader = class
  strict private
    // One of each for every blit: the functions have no state, and an object made in the call and given to a
    // const interface parameter is never released (a blit of the battle map leaked one object per sprite)
    class var FStandard: IXcomShadeFunction;
    class var FColorReplace: IXcomShadeFunction;
    class constructor Create;
  public
    /// <summary>
    ///   Surface::blitNShade(surface, x, y, shade, half, newBaseColor): draws ASource on ADestination with the
    ///   shade added to the low four bits of each pixel. AX, AY are the position of the source in the same
    ///   coordinates as ADestination.X and Y. With AHalf only the right half of the source is drawn; with
    ///   ANewBaseColor not zero the pixels take the color group ANewBaseColor - 1
    /// </summary>
    class procedure Blit(ASource, ADestination: TXcomSurface; AX, AY, AShade: Integer; AHalf: Boolean = False;
      ANewBaseColor: Integer = 0); overload; static;
    /// <summary>Surface::blitNShade(surface, x, y, shade, range): only the part of the destination in ARange</summary>
    class procedure Blit(ASource, ADestination: TXcomSurface; AX, AY, AShade: Integer;
      const ARange: TXcomGraphSubset); overload; static;
  end;

implementation

{ TXcomSurfaceShader }

class constructor TXcomSurfaceShader.Create;
begin
  FStandard := TXcomStandardShade.Create;
  FColorReplace := TXcomColorReplaceShade.Create;
end;

class procedure TXcomSurfaceShader.Blit(ASource, ADestination: TXcomSurface; AX, AY, AShade: Integer; AHalf: Boolean;
  ANewBaseColor: Integer);
var
  LSourceDomain: TXcomGraphSubset;
  LDestinationDomain: TXcomGraphSubset;
begin
  LSourceDomain := TXcomGraphSubset.Make(0, ASource.Width, 0, ASource.Height);
  if AHalf then
    LSourceDomain.BegX := LSourceDomain.EndX div 2;
  LDestinationDomain := TXcomGraphSubset.Make(0, ADestination.Width, 0, ADestination.Height);
  if ANewBaseColor <> 0 then
  begin
    Dec(ANewBaseColor);
    ANewBaseColor := ANewBaseColor shl 4;
    TXcomShadeDrawer.Draw(ADestination, LDestinationDomain, ASource, LSourceDomain, AX, AY,
      FColorReplace, AShade, ANewBaseColor);
  end
  else
    TXcomShadeDrawer.Draw(ADestination, LDestinationDomain, ASource, LSourceDomain, AX, AY,
      FStandard, AShade, 0);
end;

class procedure TXcomSurfaceShader.Blit(ASource, ADestination: TXcomSurface; AX, AY, AShade: Integer;
  const ARange: TXcomGraphSubset);
begin
  TXcomShadeDrawer.Draw(ADestination, ARange, ASource,
    TXcomGraphSubset.Make(0, ASource.Width, 0, ASource.Height), AX, AY, FStandard, AShade, 0);
end;

{ TXcomStandardShade }

procedure TXcomStandardShade.Apply(var ADest: Byte; ASource: Byte; AShade, ANewColor: Integer);
var
  LNewShade: Integer;
begin
  if ASource <> 0 then
  begin
    LNewShade := (ASource and 15) + AShade;
    if LNewShade > 15 then
      // so dark it would flip over to another color: make it black
      ADest := 15
    else
      ADest := Byte(((ASource and (15 shl 4)) or LNewShade) and $FF);
  end;
end;

{ TXcomColorReplaceShade }

procedure TXcomColorReplaceShade.Apply(var ADest: Byte; ASource: Byte; AShade, ANewColor: Integer);
var
  LNewShade: Integer;
begin
  if ASource <> 0 then
  begin
    LNewShade := (ASource and 15) + AShade;
    if LNewShade > 15 then
      ADest := 15
    else
      ADest := Byte((ANewColor or LNewShade) and $FF);
  end;
end;

{ TXcomShadeDrawer }

class procedure TXcomShadeDrawer.Draw(ADestination: TXcomSurface; const ADestinationDomain: TXcomGraphSubset;
  ASource: TXcomSurface; const ASourceDomain: TXcomGraphSubset; AX, AY: Integer;
  const AFunction: IXcomShadeFunction; AShade, ANewColor: Integer);
var
  LDestinationBase, LSourceBase: TXcomGraphSubset;
  LDestinationDomain, LSourceDomain: TXcomGraphSubset;
  LDestinationImage, LSourceImage, LRange: TXcomGraphSubset;
  LGlobalX, LGlobalY: Integer;
  LDestinationPixel: PByte;
begin
  LDestinationBase := TXcomGraphSubset.Make(0, ADestination.Width, 0, ADestination.Height);
  LSourceBase := TXcomGraphSubset.Make(0, ASource.Width, 0, ASource.Height);
  LDestinationDomain := TXcomGraphSubset.Intersection(ADestinationDomain, LDestinationBase);
  LSourceDomain := TXcomGraphSubset.Intersection(ASourceDomain, LSourceBase);
  // image: the domain at the position of the surface
  LDestinationImage := LDestinationDomain.Offset(ADestination.X, ADestination.Y);
  LSourceImage := LSourceDomain.Offset(AX, AY);
  LRange := TXcomGraphSubset.Intersection(LDestinationImage, LSourceImage);
  if (LRange.SizeX = 0) or (LRange.SizeY = 0) then
    Exit;
  for LGlobalY := LRange.BegY to LRange.EndY - 1 do
    for LGlobalX := LRange.BegX to LRange.EndX - 1 do
    begin
      LDestinationPixel := ADestination.PixelPointer(LGlobalX - ADestination.X, LGlobalY - ADestination.Y);
      AFunction.Apply(LDestinationPixel^, ASource.Pixels[(LGlobalY - AY) * ASource.Width + LGlobalX - AX],
        AShade, ANewColor);
    end;
end;

end.
