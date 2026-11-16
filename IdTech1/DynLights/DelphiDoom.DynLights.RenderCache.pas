{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the lights as the renderers read them   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.RenderCache;

interface

uses
  DelphiDoom.DynLights.Types, DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   Keeps one record for each light of the registry and fills it from the animator the first
  ///   time it is asked in a tic. It was R_InitDynamicLights, R_DynamicLightsDone and
  ///   R_GetDynamicLight of r_dynlights.pas
  /// </summary>
  TDynLightRenderCache = class(TInterfacedObject, IDynLightRenderCache)
  private
    FLoader: IDynLightLoader;
    FRegistry: IDynLightRegistry;
    FAnimator: IDynLightAnimator;
    FRenders: TArray<TDynLightRender>;
    FHasRender: TArray<Boolean>;
    FRenderTime: TArray<Integer>;
  public
    /// <summary>Raises EArgumentNilException if one of them is nil</summary>
    constructor Create(const ALoader: IDynLightLoader; const ARegistry: IDynLightRegistry;
      const AAnimator: IDynLightAnimator);
    function Load(AGldefsAsLightDef: Boolean): Boolean;
    procedure Clear;
    function Count: Integer;
    function GetLight(AIndex, ALevelTime: Integer): PDynLightRender;
  end;

implementation

uses
  System.SysUtils;

const
  SLoaderIsNil = 'TDynLightRenderCache: the loader is nil';
  SRegistryIsNil = 'TDynLightRenderCache: the registry is nil';
  SAnimatorIsNil = 'TDynLightRenderCache: the animator is nil';

{ TDynLightRenderCache }

constructor TDynLightRenderCache.Create(const ALoader: IDynLightLoader;
  const ARegistry: IDynLightRegistry; const AAnimator: IDynLightAnimator);
begin
  inherited Create;
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create(SLoaderIsNil);
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create(SRegistryIsNil);
  if not Assigned(AAnimator) then
    raise EArgumentNilException.Create(SAnimatorIsNil);
  FLoader := ALoader;
  FRegistry := ARegistry;
  FAnimator := AAnimator;
end;

function TDynLightRenderCache.Load(AGldefsAsLightDef: Boolean): Boolean;
var
  LCount: Integer;
begin
  FRegistry.Clear;
  FAnimator.Reset;
  Result := FLoader.Load(AGldefsAsLightDef);

  LCount := FRegistry.Count;
  // new arrays: every record starts at zero and is calculated the first time it is asked
  FRenders := nil;
  FHasRender := nil;
  FRenderTime := nil;
  SetLength(FRenders, LCount);
  SetLength(FHasRender, LCount);
  SetLength(FRenderTime, LCount);
end;

procedure TDynLightRenderCache.Clear;
begin
  FRegistry.Clear;
  FAnimator.Reset;
  FRenders := nil;
  FHasRender := nil;
  FRenderTime := nil;
end;

function TDynLightRenderCache.Count: Integer;
begin
  Result := Length(FRenders);
end;

function TDynLightRenderCache.GetLight(AIndex, ALevelTime: Integer): PDynLightRender;
var
  LRender: TDynLightRender;
begin
  Result := @FRenders[AIndex];
  Result.Shadow := False;

  // the animation of a light is the same during one tic
  if FHasRender[AIndex] and (FRenderTime[AIndex] = ALevelTime) then
    Exit;

  LRender := FAnimator.GetRender(AIndex, ALevelTime);
  Result.R := LRender.R;
  Result.G := LRender.G;
  Result.B := LRender.B;
  Result.Radius := LRender.Radius;
  Result.X := LRender.X;
  Result.Y := LRender.Y;
  Result.Z := LRender.Z;
  FHasRender[AIndex] := True;
  FRenderTime[AIndex] := ALevelTime;
end;

end.
