{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TActorDefFactory = class
  public
    /// <summary>The parser of the texts of ACTORDEF and DECORATE of a game</summary>
    /// <param name="ALog">May be nil</param>
    /// <param name="APreprocessor">May be nil: the text is read as it is</param>
    class function CreateParser(const AProfile: TActorDefProfile; const ALog: ILog;
      const AFlags: IActorDefFlagCatalog; const ANames: IActorDefNameCatalog;
      const AActors: IActorDefActorCatalog; const ADefinitions: IActorDefDefinitionSink;
      const AThinkers: IActorDefThinkerSink; const AScripts: IActorDefScriptSink;
      const APreprocessor: IActorDefTextPreprocessor): IActorDefParser; static;
    /// <summary>
    ///   The sink that writes each definition as a patch for the engine (what the old parser
    ///   did): the actors and the weapons go to the consumer as text
    /// </summary>
    class function CreateDehSink(const AProfile: TActorDefProfile;
      const AActors: IActorDefActorCatalog; const AStates: IActorDefStateCatalog;
      const ASounds: IActorDefSoundResolver; const AConsumer: IActorDefDehConsumer;
      const ALog: ILog): IActorDefDefinitionSink; static;
    /// <summary>The aliases of the sounds, empty; SNDINFO fills them</summary>
    class function CreateSoundAliases(const ALog: ILog): IActorDefSoundAliasTable; static;
    /// <summary>Reads the text of SNDINFO into the aliases</summary>
    /// <param name="AListener">What the engine does with the lines for Hexen; may be nil</param>
    class procedure ParseSoundInfo(const AProfile: TActorDefProfile; const AText: string;
      const AAliases: IActorDefSoundAliasTable; const AListener: IActorDefSoundInfoListener); static;
  end;

implementation

uses
  DelphiDoom.ActorDef.Parser, DelphiDoom.ActorDef.DehSink, DelphiDoom.ActorDef.DehWriter,
  DelphiDoom.ActorDef.SoundAliases, DelphiDoom.ActorDef.SoundInfoParser;

{ TActorDefFactory }

class function TActorDefFactory.CreateParser(const AProfile: TActorDefProfile; const ALog: ILog;
  const AFlags: IActorDefFlagCatalog; const ANames: IActorDefNameCatalog;
  const AActors: IActorDefActorCatalog; const ADefinitions: IActorDefDefinitionSink;
  const AThinkers: IActorDefThinkerSink; const AScripts: IActorDefScriptSink;
  const APreprocessor: IActorDefTextPreprocessor): IActorDefParser;
begin
  Result := TActorDefParser.Create(AProfile, ALog, AFlags, ANames, AActors, ADefinitions,
    AThinkers, AScripts, APreprocessor);
end;

class function TActorDefFactory.CreateDehSink(const AProfile: TActorDefProfile;
  const AActors: IActorDefActorCatalog; const AStates: IActorDefStateCatalog;
  const ASounds: IActorDefSoundResolver; const AConsumer: IActorDefDehConsumer;
  const ALog: ILog): IActorDefDefinitionSink;
begin
  Result := TActorDefDehSink.Create(
    TActorDefDehWriter.Create(AProfile, AActors, AStates, ASounds, ALog), AConsumer);
end;

class function TActorDefFactory.CreateSoundAliases(const ALog: ILog): IActorDefSoundAliasTable;
begin
  Result := TActorDefSoundAliases.Create(ALog);
end;

class procedure TActorDefFactory.ParseSoundInfo(const AProfile: TActorDefProfile; const AText: string;
  const AAliases: IActorDefSoundAliasTable; const AListener: IActorDefSoundInfoListener);
var
  LParser: TActorDefSoundInfoParser;
begin
  LParser := TActorDefSoundInfoParser.Create(AProfile, AAliases, AListener);
  try
    LParser.Parse(AText);
  finally
    LParser.Free;
  end;
end;

end.
