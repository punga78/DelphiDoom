{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the factory: the composition root                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.Factory;

interface

uses
  DelphiDoom.Video.Intf;

type
  /// <summary>The only place that knows the classes behind the video contracts</summary>
  TVideoFactory = class
  public
    class function CreatePaletteConverter: IPaletteConverter; static;
    class function CreateSizeLimiter(const AMetrics: IDisplayMetrics): ISizeLimiter; static;
    class function CreateMemoryStallHack: IMemoryStallHack; static;
    class function CreateWindowsDisplayMetrics: IDisplayMetrics; static;
    /// <summary>The services on the screen of Windows</summary>
    class function CreateServices: IVideoServices; static;
  end;

implementation

uses
  DelphiDoom.Video.PaletteConverter, DelphiDoom.Video.SizeLimiter,
  DelphiDoom.Video.MemoryStallHack, DelphiDoom.Video.WindowsDisplayMetrics,
  DelphiDoom.Video.Services;

{ TVideoFactory }

class function TVideoFactory.CreatePaletteConverter: IPaletteConverter;
begin
  Result := TPaletteConverter.Create;
end;

class function TVideoFactory.CreateSizeLimiter(const AMetrics: IDisplayMetrics): ISizeLimiter;
begin
  Result := TSizeLimiter.Create(AMetrics);
end;

class function TVideoFactory.CreateMemoryStallHack: IMemoryStallHack;
begin
  Result := TMemoryStallHack.Create;
end;

class function TVideoFactory.CreateWindowsDisplayMetrics: IDisplayMetrics;
begin
  Result := TWindowsDisplayMetrics.Create;
end;

class function TVideoFactory.CreateServices: IVideoServices;
begin
  Result := TVideoServices.Create(CreatePaletteConverter,
    CreateSizeLimiter(CreateWindowsDisplayMetrics), CreateMemoryStallHack);
end;

end.
