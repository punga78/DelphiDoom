{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the parser of ACTORDEF and DECORATE          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Parser;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The parser of the text of an ACTORDEF or DECORATE lump (the old SC_ParseActordefLump).
  ///   Each call reads its text with a reader of its own: the parser keeps nothing between
  ///   two texts, and one can be called while another is being read
  /// </summary>
  TActorDefParser = class(TInterfacedObject, IActorDefParser)
  private
    FProfile: TActorDefProfile;
    FLog: ILog;
    FFlags: IActorDefFlagCatalog;
    FNames: IActorDefNameCatalog;
    FActors: IActorDefActorCatalog;
    FDefinitions: IActorDefDefinitionSink;
    FThinkers: IActorDefThinkerSink;
    FScripts: IActorDefScriptSink;
    FPreprocessor: IActorDefTextPreprocessor;
  public
    /// <param name="ALog">May be nil</param>
    /// <param name="APreprocessor">Prepares the text first; may be nil (the text is read as it is)</param>
    constructor Create(const AProfile: TActorDefProfile; const ALog: ILog;
      const AFlags: IActorDefFlagCatalog; const ANames: IActorDefNameCatalog;
      const AActors: IActorDefActorCatalog; const ADefinitions: IActorDefDefinitionSink;
      const AThinkers: IActorDefThinkerSink; const AScripts: IActorDefScriptSink;
      const APreprocessor: IActorDefTextPreprocessor);
    procedure Parse(const AText: string);
  end;

implementation

uses
  DelphiDoom.ActorDef.DocumentReader;

{ TActorDefParser }

constructor TActorDefParser.Create(const AProfile: TActorDefProfile; const ALog: ILog;
  const AFlags: IActorDefFlagCatalog; const ANames: IActorDefNameCatalog;
  const AActors: IActorDefActorCatalog; const ADefinitions: IActorDefDefinitionSink;
  const AThinkers: IActorDefThinkerSink; const AScripts: IActorDefScriptSink;
  const APreprocessor: IActorDefTextPreprocessor);
begin
  inherited Create;
  FProfile := AProfile;
  FLog := ALog;
  FFlags := AFlags;
  FNames := ANames;
  FActors := AActors;
  FDefinitions := ADefinitions;
  FThinkers := AThinkers;
  FScripts := AScripts;
  FPreprocessor := APreprocessor;
end;

procedure TActorDefParser.Parse(const AText: string);
var
  LText: string;
  LReader: TActorDefDocumentReader;
begin
  if Assigned(FPreprocessor) then
    LText := FPreprocessor.Process(AText)
  else
    LText := AText;
  LReader := TActorDefDocumentReader.Create(LText, FLog, FProfile, FFlags, FNames, FActors,
    FDefinitions, FThinkers, FScripts);
  try
    LReader.Run;
  finally
    LReader.Free;
  end;
end;

end.
