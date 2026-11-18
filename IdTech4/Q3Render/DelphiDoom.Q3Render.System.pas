{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - the tables       }
{                                                                              }
{  Written for the repository (licence GPL v2 or later).                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.System;

interface

uses
  DelphiDoom.Q3Render.Intf;

type
  /// <summary>Holds the four tables so that they live as long as the one that uses them</summary>
  TQ3RenderSystem = class(TInterfacedObject, IQ3RenderSystem)
  strict private
    FImages: IQ3ImageCatalog;
    FShaders: IQ3ShaderRegistry;
    FModels: IQ3ModelRegistry;
    FWorldLoader: IQ3WorldLoader;
  public
    constructor Create(const AImages: IQ3ImageCatalog; const AShaders: IQ3ShaderRegistry;
      const AModels: IQ3ModelRegistry; const AWorldLoader: IQ3WorldLoader);
    function GetImages: IQ3ImageCatalog;
    function GetShaders: IQ3ShaderRegistry;
    function GetModels: IQ3ModelRegistry;
    function GetWorldLoader: IQ3WorldLoader;
  end;

implementation

constructor TQ3RenderSystem.Create(const AImages: IQ3ImageCatalog; const AShaders: IQ3ShaderRegistry;
  const AModels: IQ3ModelRegistry; const AWorldLoader: IQ3WorldLoader);
begin
  inherited Create;
  FImages := AImages;
  FShaders := AShaders;
  FModels := AModels;
  FWorldLoader := AWorldLoader;
end;

function TQ3RenderSystem.GetImages: IQ3ImageCatalog;
begin
  Result := FImages;
end;

function TQ3RenderSystem.GetShaders: IQ3ShaderRegistry;
begin
  Result := FShaders;
end;

function TQ3RenderSystem.GetModels: IQ3ModelRegistry;
begin
  Result := FModels;
end;

function TQ3RenderSystem.GetWorldLoader: IQ3WorldLoader;
begin
  Result := FWorldLoader;
end;

end.
