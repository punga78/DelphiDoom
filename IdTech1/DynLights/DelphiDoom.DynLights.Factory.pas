{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the factory: the composition root     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.DynLights.Intf;

type
  /// <summary>The only place that knows the classes behind the dynamic lights contracts</summary>
  TDynLightFactory = class
  public
    class function CreateRegistry: IDynLightRegistry; static;
    class function CreateAnimator(const ARegistry: IDynLightRegistry;
      const ARandom: IDynLightRandom): IDynLightAnimator; static;
    class function CreateBinder(const AStates: IDynLightStateTable): IDynLightBinder; static;
    /// <param name="ALog">May be nil</param>
    /// <param name="AMapCoefficient">1 for the software renderer, 128 for OpenGL</param>
    class function CreateParser(const AServices: TDynLightParserServices; const ALog: ILog;
      AMapCoefficient: Double): IDynLightParser; static;
    /// <param name="AFilter">May be nil</param>
    class function CreateLoader(const ASource: IDynLightTextSource;
      const AFilter: IDynLightTextFilter; const AParser: IDynLightParser): IDynLightLoader; static;
    /// <summary>The records that the renderers read, over the lights of the registry</summary>
    class function CreateRenderCache(const ALoader: IDynLightLoader;
      const ARegistry: IDynLightRegistry; const AAnimator: IDynLightAnimator): IDynLightRenderCache; static;
  end;

implementation

uses
  DelphiDoom.DynLights.Registry, DelphiDoom.DynLights.Animator, DelphiDoom.DynLights.StateBinder,
  DelphiDoom.DynLights.Parser, DelphiDoom.DynLights.Loader, DelphiDoom.DynLights.RenderCache;

{ TDynLightFactory }

class function TDynLightFactory.CreateRegistry: IDynLightRegistry;
begin
  Result := TDynLightRegistry.Create;
end;

class function TDynLightFactory.CreateAnimator(const ARegistry: IDynLightRegistry;
  const ARandom: IDynLightRandom): IDynLightAnimator;
begin
  Result := TDynLightAnimator.Create(ARegistry, ARandom);
end;

class function TDynLightFactory.CreateBinder(const AStates: IDynLightStateTable): IDynLightBinder;
begin
  Result := TDynLightStateBinder.Create(AStates);
end;

class function TDynLightFactory.CreateParser(const AServices: TDynLightParserServices;
  const ALog: ILog; AMapCoefficient: Double): IDynLightParser;
begin
  Result := TDynLightParser.Create(AServices, ALog, AMapCoefficient);
end;

class function TDynLightFactory.CreateLoader(const ASource: IDynLightTextSource;
  const AFilter: IDynLightTextFilter; const AParser: IDynLightParser): IDynLightLoader;
begin
  Result := TDynLightLoader.Create(ASource, AFilter, AParser);
end;

class function TDynLightFactory.CreateRenderCache(const ALoader: IDynLightLoader;
  const ARegistry: IDynLightRegistry; const AAnimator: IDynLightAnimator): IDynLightRenderCache;
begin
  Result := TDynLightRenderCache.Create(ALoader, ARegistry, AAnimator);
end;

end.
