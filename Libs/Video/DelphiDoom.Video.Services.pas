{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the services together                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.Services;

interface

uses
  DelphiDoom.Video.Intf;

type
  TVideoServices = class(TInterfacedObject, IVideoServices)
  private
    FPalette: IPaletteConverter;
    FSizeLimiter: ISizeLimiter;
    FStallHack: IMemoryStallHack;
  public
    constructor Create(const APalette: IPaletteConverter; const ASizeLimiter: ISizeLimiter;
      const AStallHack: IMemoryStallHack);
    function GetPalette: IPaletteConverter;
    function GetSizeLimiter: ISizeLimiter;
    function GetStallHack: IMemoryStallHack;
  end;

implementation

{ TVideoServices }

constructor TVideoServices.Create(const APalette: IPaletteConverter;
  const ASizeLimiter: ISizeLimiter; const AStallHack: IMemoryStallHack);
begin
  inherited Create;
  FPalette := APalette;
  FSizeLimiter := ASizeLimiter;
  FStallHack := AStallHack;
end;

function TVideoServices.GetPalette: IPaletteConverter;
begin
  Result := FPalette;
end;

function TVideoServices.GetSizeLimiter: ISizeLimiter;
begin
  Result := FSizeLimiter;
end;

function TVideoServices.GetStallHack: IMemoryStallHack;
begin
  Result := FStallHack;
end;

end.
