{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, composition        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Factory;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>The place that knows the classes of the player models (the composition root of the library)</summary>
  TQ3PlayerFactory = class
  public
    /// <summary>ALog may be nil: the warnings are then lost</summary>
    class function CreateParser(const ALog: ILog): IQ3AnimationParser; static;
    class function CreateLoader(const ASource: IQ3TextSource; const ALog: ILog): IQ3AnimationLoader; static;
    class function CreateLerpFrameRunner(const AConfig: IQ3AnimationConfig): IQ3LerpFrameRunner; static;
    class function CreateAnimator(const AConfig: IQ3AnimationConfig): IQ3PlayerAnimator; static;
    class function CreateAngles(const AConfig: IQ3AnimationConfig): IQ3PlayerAngles; static;
    class function CreateTagLerper: IQ3TagLerper; static;
    class function CreateTagPositioner: IQ3TagPositioner; static;
    class function CreateAssembler: IQ3PlayerAssembler; static;
    class function CreateSkinParser(const ALog: ILog): IQ3SkinParser; static;
    class function CreateSkinRegistry(const ASource: IQ3TextSource; const ALog: ILog): IQ3SkinRegistry; static;
    class function CreateFileFinder(const AProbe: IQ3FileProbe; const ALog: ILog): IQ3PlayerFileFinder; static;
    class function CreateModelSource(const ASource: IQ3TextSource; const ALog: ILog): IQ3ModelSource; static;
    class function CreateSkinShaderResolver: IQ3SkinShaderResolver; static;
    /// <summary>The loader of whole players: files from ASource, existence of files from AProbe, one skin registry</summary>
    class function CreateModelLoader(const ASource: IQ3TextSource; const AProbe: IQ3FileProbe;
      const ALog: ILog): IQ3PlayerModelLoader; static;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.AnimationParser,
  DelphiDoom.Models.Q3Player.AnimationLoader,
  DelphiDoom.Models.Q3Player.LerpFrameRunner,
  DelphiDoom.Models.Q3Player.PlayerAnimator,
  DelphiDoom.Models.Q3Player.PlayerAngles,
  DelphiDoom.Models.Q3Player.TagLerper,
  DelphiDoom.Models.Q3Player.TagPositioner,
  DelphiDoom.Models.Q3Player.PlayerAssembler,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Q3Player.Skin.Parser,
  DelphiDoom.Models.Q3Player.Skin.Registry,
  DelphiDoom.Models.Q3Player.Skin.ShaderResolver,
  DelphiDoom.Models.Q3Player.FileFinder,
  DelphiDoom.Models.Q3Player.Md3ModelSource,
  DelphiDoom.Models.Q3Player.ModelLoader;

class function TQ3PlayerFactory.CreateParser(const ALog: ILog): IQ3AnimationParser;
begin
  Result := TQ3AnimationParser.Create(ALog);
end;

class function TQ3PlayerFactory.CreateLoader(const ASource: IQ3TextSource; const ALog: ILog): IQ3AnimationLoader;
begin
  Result := TQ3AnimationLoader.Create(ASource, CreateParser(ALog));
end;

class function TQ3PlayerFactory.CreateLerpFrameRunner(const AConfig: IQ3AnimationConfig): IQ3LerpFrameRunner;
begin
  Result := TQ3LerpFrameRunner.Create(AConfig);
end;

class function TQ3PlayerFactory.CreateAnimator(const AConfig: IQ3AnimationConfig): IQ3PlayerAnimator;
begin
  Result := TQ3PlayerAnimator.Create(CreateLerpFrameRunner(AConfig));
end;

class function TQ3PlayerFactory.CreateAngles(const AConfig: IQ3AnimationConfig): IQ3PlayerAngles;
begin
  Result := TQ3PlayerAngles.Create(AConfig);
end;

class function TQ3PlayerFactory.CreateTagLerper: IQ3TagLerper;
begin
  Result := TQ3TagLerper.Create;
end;

class function TQ3PlayerFactory.CreateTagPositioner: IQ3TagPositioner;
begin
  Result := TQ3TagPositioner.Create(CreateTagLerper);
end;

class function TQ3PlayerFactory.CreateAssembler: IQ3PlayerAssembler;
begin
  Result := TQ3PlayerAssembler.Create(CreateTagPositioner);
end;

class function TQ3PlayerFactory.CreateSkinParser(const ALog: ILog): IQ3SkinParser;
begin
  Result := TQ3SkinParser.Create(ALog);
end;

class function TQ3PlayerFactory.CreateSkinRegistry(const ASource: IQ3TextSource; const ALog: ILog): IQ3SkinRegistry;
begin
  Result := TQ3SkinRegistry.Create(ASource, CreateSkinParser(ALog), ALog);
end;

class function TQ3PlayerFactory.CreateFileFinder(const AProbe: IQ3FileProbe; const ALog: ILog): IQ3PlayerFileFinder;
begin
  Result := TQ3PlayerFileFinder.Create(AProbe, ALog);
end;

class function TQ3PlayerFactory.CreateModelSource(const ASource: IQ3TextSource; const ALog: ILog): IQ3ModelSource;
begin
  Result := TQ3Md3ModelSource.Create(ASource, TStaticModelFactory.CreateMd3Reader, ALog);
end;

class function TQ3PlayerFactory.CreateSkinShaderResolver: IQ3SkinShaderResolver;
begin
  Result := TQ3SkinShaderResolver.Create;
end;

class function TQ3PlayerFactory.CreateModelLoader(const ASource: IQ3TextSource; const AProbe: IQ3FileProbe;
  const ALog: ILog): IQ3PlayerModelLoader;
begin
  Result := TQ3PlayerModelLoader.Create(CreateModelSource(ASource, ALog), CreateSkinRegistry(ASource, ALog),
    CreateFileFinder(AProbe, ALog), CreateLoader(ASource, ALog), ALog);
end;

end.
