{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the nearest color for the Imaging library              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Imaging.ColorIndex;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   Answers the Imaging library with the color matcher of the Palette library (the one that
  ///   V_FindAproxColorIndex stands for)
  /// </summary>
  TEngineImagingColorIndex = class(TInterfacedObject, IImagingColorIndex)
  strict private
    FMatcher: IColorMatcher;
  public
    constructor Create(const AMatcher: IColorMatcher);
    function Nearest(const APalette: TImagingPixels; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
  end;

implementation

{ TEngineImagingColorIndex }

constructor TEngineImagingColorIndex.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
end;

function TEngineImagingColorIndex.Nearest(const APalette: TImagingPixels; AColor: Cardinal;
  ALow, AHigh: Integer): Integer;
begin
  Result := FMatcher.FindApproximateIndex(APalette, AColor, ALow, AHigh);
end;

end.
