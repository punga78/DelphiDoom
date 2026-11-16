{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.Speed.Intf, DelphiDoom.Speed.CarSpriteBuilder, DelphiDoom.Speed.SkyTextures, DelphiDoom.GameData.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TSpeedFactory = class
  public
    /// <summary>Opens the container SPEEDH.JCL; ESpeedException when it is not a JCL container</summary>
    class function OpenContainer(const APath: string): ISpeedContainer; static;
    /// <summary>A container held in memory</summary>
    class function OpenContainerBytes(const ABytes: TBytes): ISpeedContainer; static;
    class function CreatePaletteBuilder: ISpeedPaletteBuilder; static;
    class function CreateBitmapDecoder: ISpeedBitmapDecoder; static;
    class function CreateMapBitmapBuilder: ISpeedMapBitmapBuilder; static;
    class function CreateCircuitReader(const ALog: ILog): ISpeedCircuitReader; static;
    class function CreateLevelBuilder(const ALog: ILog): ISpeedLevelBuilder; static;
    /// <summary>The translator of the whole game, with the patch options of Speed</summary>
    class function CreateTranslator(const ALog: ILog): ISpeedTranslator; static;
    /// <summary>The builder of the sprites of the cars (the models drawn from five sides), with the axes of the models of the game</summary>
    class function CreateCarSpriteBuilder: TSpeedCarSpriteBuilder; static;
    /// <summary>Adds the sky textures of the circuits (the clouds and the mountains as one picture) to a WAD</summary>
    class function AppendSkyTextures(const AWad: IGameWadComposer): TArray<TSpeedSkyEntry>; static;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Palette.Intf, DelphiDoom.Palette.Factory, DelphiDoom.GameData.Types,
  DelphiDoom.GameData.Factory,
  DelphiDoom.Speed.Container, DelphiDoom.Speed.PaletteBuilder, DelphiDoom.Speed.Is2Decoder,
  DelphiDoom.Speed.MapBitmapBuilder, DelphiDoom.Speed.CircuitReader, DelphiDoom.Speed.LevelBuilder,
  DelphiDoom.Speed.FontBuilder, DelphiDoom.Speed.Translator, DelphiDoom.Models.I3d.Intf,
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Speed.CarSpriteRenderer;

{ TSpeedFactory }

class function TSpeedFactory.OpenContainer(const APath: string): ISpeedContainer;
begin
  Result := TSpeedContainer.Create(TFileStream.Create(APath, fmOpenRead or fmShareDenyNone), True);
end;

class function TSpeedFactory.OpenContainerBytes(const ABytes: TBytes): ISpeedContainer;
begin
  Result := TSpeedContainer.Create(TBytesStream.Create(ABytes), True);
end;

class function TSpeedFactory.CreatePaletteBuilder: ISpeedPaletteBuilder;
begin
  Result := TSpeedPaletteBuilder.Create(TPaletteFactory.CreateColorMatcher);
end;

class function TSpeedFactory.CreateBitmapDecoder: ISpeedBitmapDecoder;
begin
  Result := TSpeedIs2Decoder.Create;
end;

class function TSpeedFactory.CreateMapBitmapBuilder: ISpeedMapBitmapBuilder;
begin
  Result := TSpeedMapBitmapBuilder.Create;
end;

class function TSpeedFactory.CreateCircuitReader(const ALog: ILog): ISpeedCircuitReader;
begin
  Result := TSpeedCircuitReader.Create(ALog);
end;

class function TSpeedFactory.CreateLevelBuilder(const ALog: ILog): ISpeedLevelBuilder;
begin
  Result := TSpeedLevelBuilder.Create(ALog);
end;

class function TSpeedFactory.CreateTranslator(const ALog: ILog): ISpeedTranslator;
var
  LMatcher: IColorMatcher;
  LPatches: IGamePatchBuilder;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
  LPatches := TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed, LMatcher);
  Result := TSpeedTranslator.Create(ALog, LMatcher, LPatches, TSpeedPaletteBuilder.Create(LMatcher),
    TSpeedIs2Decoder.Create, TSpeedCircuitReader.Create(ALog), TSpeedLevelBuilder.Create(ALog),
    TSpeedFontBuilder.Create(LPatches, LMatcher), TSpeedMapBitmapBuilder.Create);
end;

class function TSpeedFactory.AppendSkyTextures(const AWad: IGameWadComposer): TArray<TSpeedSkyEntry>;
begin
  Result := TSpeedSkyTextures.Append(AWad,
    TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed, TPaletteFactory.CreateColorMatcher),
    TGamePatchOptions.Speed.TransparentIndex);
end;

class function TSpeedFactory.CreateCarSpriteBuilder: TSpeedCarSpriteBuilder;
const
  // the cars in a model of the game: the front is +Z, the left +X and the top +Y (read on the extents of the models)
  CAR_LENGTH_PIXELS = 112;
  CAR_EYE_DEGREES = 15;
var
  LAxes: TSpeedModelAxes;
begin
  LAxes.ForwardAxis := 2;
  LAxes.ForwardSign := 1;
  LAxes.LeftAxis := 0;
  LAxes.LeftSign := 1;
  LAxes.UpAxis := 1;
  LAxes.UpSign := 1;
  Result := TSpeedCarSpriteBuilder.Create(TI3dFactory.CreateParser, TI3dFactory.CreateRenderer,
    function: II3dMeshBuilder
    begin
      Result := TI3dFactory.CreateMeshBuilder;
    end,
    TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Speed, TPaletteFactory.CreateColorMatcher), LAxes,
    CAR_LENGTH_PIXELS, CAR_EYE_DEGREES, TGamePatchOptions.Speed.TransparentIndex);
end;

end.
