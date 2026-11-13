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
  DelphiDoom.Models.Q3Player.Intf;

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
  DelphiDoom.Models.Q3Player.PlayerAssembler;

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

end.
