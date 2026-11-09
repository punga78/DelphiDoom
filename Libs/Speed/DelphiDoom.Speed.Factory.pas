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
  DelphiDoom.Logging.Intf, DelphiDoom.Speed.Intf;

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
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Palette.Intf, DelphiDoom.Palette.Factory, DelphiDoom.GameData.Types,
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory,
  DelphiDoom.Speed.Container, DelphiDoom.Speed.PaletteBuilder, DelphiDoom.Speed.Is2Decoder,
  DelphiDoom.Speed.MapBitmapBuilder, DelphiDoom.Speed.CircuitReader, DelphiDoom.Speed.LevelBuilder,
  DelphiDoom.Speed.FontBuilder, DelphiDoom.Speed.Translator;

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

end.
