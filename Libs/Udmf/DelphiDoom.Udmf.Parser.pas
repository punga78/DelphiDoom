{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the parser                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Parser;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.Map, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Reads the text of a map: the namespace and the blocks thing, linedef, sidedef, vertex and
  ///   sector. What a key means is asked to the formats of the game. A key that nobody knows is
  ///   left out; its value is read as the next key, as the old code did
  /// </summary>
  TUdmfParser = class
  private
    FProfile: IUdmfProfile;
    FLog: ILog;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const AProfile: IUdmfProfile; const ALog: ILog);
    /// <summary>The caller frees the map</summary>
    function Parse(const AText: string): TUdmfMap;
  end;

implementation

uses
  DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Preprocessor, DelphiDoom.Udmf.ValueReader;

{ TUdmfParser }

constructor TUdmfParser.Create(const AProfile: IUdmfProfile; const ALog: ILog);
begin
  inherited Create;
  FProfile := AProfile;
  FLog := ALog;
end;

function TUdmfParser.Parse(const AText: string): TUdmfMap;
var
  LReader: TUdmfValueReader;
  LValues: IUdmfValueReader; // keeps the reader alive
  LGame: string;

  procedure Warn(const AFormat: string; const AArguments: array of const);
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(AFormat, AArguments));
  end;

  // the block of an entity: its key and value pairs up to the closing brace
  procedure ReadBlock(const AKind: string; const AApply: TProc<string>);
  begin
    LReader.Advance; // _BEGINBLOCK
    if LReader.Token <> '_BEGINBLOCK' then
      Warn('TUDMFManager.LoadFromString(): Unexpected token "%s" in %s definition'#13#10,
        [LReader.Token, AKind]);
    while LReader.Token <> '_ENDBLOCK' do
    begin
      if not LReader.Advance then
        Break;
      AApply(LReader.Token);
    end;
  end;

  procedure LoadThing;
  var
    LThing: TUdmfThing;
  begin
    FProfile.Things.Reset(LThing);
    ReadBlock('thing',
      procedure(AKey: string)
      begin
        FProfile.Things.Apply(AKey, LValues, LThing);
      end);
    Result.Things.Add(LThing);
  end;

  procedure LoadLine;
  var
    LLine: TUdmfLine;
  begin
    FProfile.Lines.Reset(LLine);
    ReadBlock('linedef',
      procedure(AKey: string)
      begin
        FProfile.Lines.Apply(AKey, LValues, LLine);
      end);
    Result.Lines.Add(LLine);
  end;

  procedure LoadSide;
  var
    LSide: TUdmfSide;
  begin
    FProfile.Sides.Reset(LSide);
    ReadBlock('sidedef',
      procedure(AKey: string)
      begin
        FProfile.Sides.Apply(AKey, LValues, LSide);
      end);
    Result.Sides.Add(LSide);
  end;

  procedure LoadVertex;
  var
    LVertex: TUdmfVertex;
  begin
    FProfile.Vertexes.Reset(LVertex);
    ReadBlock('vertex',
      procedure(AKey: string)
      begin
        FProfile.Vertexes.Apply(AKey, LValues, LVertex);
      end);
    Result.Vertexes.Add(LVertex);
  end;

  procedure LoadSector;
  var
    LSector: TUdmfSector;
  begin
    FProfile.Sectors.Reset(LSector);
    ReadBlock('sector',
      procedure(AKey: string)
      begin
        FProfile.Sectors.Apply(AKey, LValues, LSector);
      end);
    Result.Sectors.Add(LSector);
  end;

  procedure ReadNamespace;
  var
    LNamespace: string;
    LTranslate: Boolean;
  begin
    LReader.Advance;
    LNamespace := LReader.Token;
    LTranslate := (LNamespace <> LGame) and (LNamespace <> 'ZDOOMTRANSLATED');
    Result.Namespace := LNamespace;
    Result.LineTranslate := LTranslate;
    LReader.LineTranslate := LTranslate;
    if (LNamespace <> LGame) and (LNamespace <> 'DELPHI' + LGame) and
      (LNamespace <> 'ZDOOMTRANSLATED') then
      Warn('TUDMFManager.LoadFromString(): Unknown namespace "%s"'#13#10, [LReader.Raw]);
  end;

begin
  Result := TUdmfMap.Create;
  LGame := FProfile.GameName;
  LReader := TUdmfValueReader.Create(TUdmfPreprocessor.Process(AText), FLog);
  LValues := LReader;
  while LReader.Advance do
  begin
    if LReader.Token = 'NAMESPACE' then
      ReadNamespace;

    if LReader.Token = 'THING' then
      LoadThing
    else if LReader.Token = 'LINEDEF' then
      LoadLine
    else if LReader.Token = 'SIDEDEF' then
      LoadSide
    else if LReader.Token = 'VERTEX' then
      LoadVertex
    else if LReader.Token = 'SECTOR' then
      LoadSector;
  end;
end;

end.