{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Factory;

interface

uses
  DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the renderer library</summary>
  TRendererFactory = class
  public
    /// <param name="APatchSource">The patches of the WAD</param>
    /// <param name="ALog">Where the warnings go (only in developer mode)</param>
    class function CreateTextureLookup(const APatchSource: IRendererPatchSource;
      const ALog: ILog): IRendererTextureLookup; static;
    class function CreateLevelPrecalc: IRendererLevelPrecalc; static;
  end;

implementation

uses
  DelphiDoom.Renderer.TextureLookup, DelphiDoom.Renderer.LevelPrecalc;

{ TRendererFactory }

class function TRendererFactory.CreateTextureLookup(const APatchSource: IRendererPatchSource;
  const ALog: ILog): IRendererTextureLookup;
begin
  Result := TRendererTextureLookup.Create(APatchSource, ALog);
end;

class function TRendererFactory.CreateLevelPrecalc: IRendererLevelPrecalc;
begin
  Result := TRendererLevelPrecalc.Create;
end;

end.
