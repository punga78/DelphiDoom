{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the aspect of the monitor                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the choice of the screen mode of R_InitAspect of r_aspect.pas       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.MonitorAspect;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf,
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   Looks for the biggest screen mode of the monitor. It is done once, when the renderer
  ///   starts: the aspect of the widescreen view comes from it
  /// </summary>
  TRendererMonitorAspect = class(TInterfacedObject, IRendererMonitorAspect)
  strict private
    FSource: IDisplayModeSource;
  public
    /// <param name="ASource">The modes of the system, in the order the system lists them</param>
    constructor Create(const ASource: IDisplayModeSource);
    function Measure: TRendererMonitorSize;
  end;

implementation

uses
  DelphiDoom.Video.Types;

const
  // the size that is always there (the old code started from it)
  BASE_WIDTH = 640;
  BASE_HEIGHT = 480;
  FULL_COLOR_BITS = 32;

{ TRendererMonitorAspect }

constructor TRendererMonitorAspect.Create(const ASource: IDisplayModeSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

function TRendererMonitorAspect.Measure: TRendererMonitorSize;
var
  LModes: TArray<TDisplayMode>;
  LIndex: Integer;
begin
  Result.Width := BASE_WIDTH;
  Result.Height := BASE_HEIGHT;
  LModes := FSource.ListModes;
  // the first filter keeps the modes bigger than the base size in both sides; then a mode that
  // is not smaller than the best so far in both sides becomes the best (the order counts)
  for LIndex := 0 to High(LModes) do
    if (LModes[LIndex].Width > BASE_WIDTH) and (LModes[LIndex].Height > BASE_HEIGHT) and
      (LModes[LIndex].BitsPerPixel = FULL_COLOR_BITS) then
      if (LModes[LIndex].Width >= Result.Width) and (LModes[LIndex].Height >= Result.Height) then
      begin
        Result.Width := LModes[LIndex].Width;
        Result.Height := LModes[LIndex].Height;
      end;
end;

end.
