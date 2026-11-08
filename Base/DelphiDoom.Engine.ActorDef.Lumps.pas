{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the ACTORDEF, DECORATE and SNDINFO lumps                }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.ActorDef.Lumps;

interface

uses
  System.SysUtils,
  DelphiDoom.ActorDef.Intf,
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.ActorDef.Intf;

type
  /// <summary>
  ///   Finds the texts of ACTORDEF, DECORATE and SNDINFO in the WAD and in the PAKs and gives
  ///   them to the parser of Libs\ActorDef and to the reader of SNDINFO. It reads the lumps
  ///   of the engine (w_wad, w_pak) and the option decorate_as_actordef of sc_states
  /// </summary>
  TEngineActorDefLumps = class(TInterfacedObject, IEngineActorDefLumps)
  strict private
    FParser: IActorDefParser;
    FParseSoundInfo: TProc<string>;
    FPreprocessor: IScriptTextPreprocessor;
    FLumps: IEngineLumps;
    procedure ParsePakTexts(const AFileName: string);
  public
    /// <param name="AParser">The parser of ACTORDEF, with the sinks of the engine</param>
    /// <param name="AParseSoundInfo">Reads the whole text of SNDINFO into the sound aliases</param>
    /// <param name="APreprocessor">The script preprocessor, for the SNDINFO files of the PAKs</param>
    /// <param name="ALumps">The lumps of the loaded WADs</param>
    constructor Create(const AParser: IActorDefParser; const AParseSoundInfo: TProc<string>;
      const APreprocessor: IScriptTextPreprocessor; const ALumps: IEngineLumps);
    procedure Initialize;
    procedure ShutDown;
    procedure ParseSoundInfoLumps;
    procedure ParseActorDefLumps;
    procedure ParseText(const AText: string);
  end;

implementation

uses
  d_delphi,
  c_cmds,
  deh_base,
{$IFNDEF FPC}
  i_startup,
{$ENDIF}
  sc_consts,
  sc_states,
  w_pak;

const
  ACTORDEF_LUMP_NAME = 'ACTORDEF';
  DECORATE_LUMP_NAME = 'DECORATE';
  SNDINFO_LUMP_NAME = 'SNDINFO';

  SParserMissing = 'TEngineActorDefLumps: the parser is nil';
  SSoundInfoMissing = 'TEngineActorDefLumps: the reader of SNDINFO is nil';
  SPreprocessorMissing = 'TEngineActorDefLumps: the preprocessor is nil';

var
  // PAK_StringIterator takes a plain procedure: what it gives is kept here until it returns
  GCollectedTexts: TArray<string>;

procedure CollectText(const AText: string);
begin
  SetLength(GCollectedTexts, Length(GCollectedTexts) + 1);
  GCollectedTexts[High(GCollectedTexts)] := AText;
end;

function PakTexts(const AFileName: string): TArray<string>;
begin
  GCollectedTexts := nil;
  PAK_StringIterator(AFileName, @CollectText);
  Result := GCollectedTexts;
  GCollectedTexts := nil;
end;

{ TEngineActorDefLumps }

constructor TEngineActorDefLumps.Create(const AParser: IActorDefParser;
  const AParseSoundInfo: TProc<string>; const APreprocessor: IScriptTextPreprocessor;
  const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create(SParserMissing);
  if not Assigned(AParseSoundInfo) then
    raise EArgumentNilException.Create(SSoundInfoMissing);
  if not Assigned(APreprocessor) then
    raise EArgumentNilException.Create(SPreprocessorMissing);
  FParser := AParser;
  FParseSoundInfo := AParseSoundInfo;
  FPreprocessor := APreprocessor;
end;

procedure TEngineActorDefLumps.Initialize;
begin
  SC_InitConsts;
  C_AddCmd('DEH_PrintActordef, PrintActordef', @DEH_PrintActordef);
  C_AddCmd('DEH_SaveActordef, SaveActordef', @DEH_SaveActordef);
  C_AddCmd('DEH_PrintWeapondef, PrintWeapondef', @DEH_PrintWeapondef);
  C_AddCmd('DEH_SaveWeapondef, SaveWeapondef', @DEH_SaveWeapondef);
  C_AddCmd('DEH_PrintStateOwners, PrintStateOwners', @DEH_PrintStateOwners);
  C_AddCmd('DEH_SaveStateOwners, SaveStateOwners', @DEH_SaveStateOwners);
end;

procedure TEngineActorDefLumps.ShutDown;
begin
  statenames.Free;
  SC_ShutDownConsts;
  // the parser stays: an I_Error while a text is parsed comes here (I_Destroy, D_ShutDown)
  // with the parser still on the stack
end;

procedure TEngineActorDefLumps.ParseText(const AText: string);
begin
  FParser.Parse(AText);
end;

procedure TEngineActorDefLumps.ParsePakTexts(const AFileName: string);
var
  LText: string;
begin
  for LText in PakTexts(AFileName) do
    ParseText(LText);
end;

procedure TEngineActorDefLumps.ParseSoundInfoLumps;
var
  LIndex: Integer;
  LText: string;
  LPakText: string;
begin
  // every SNDINFO lump, then the files of the PAKs (preprocessed), make one text
  LText := '';
  for LIndex := 0 to FLumps.Count - 1 do
    if FLumps.NameOf(LIndex) = SNDINFO_LUMP_NAME then
    begin
      if LText = '' then
        LText := FLumps.TextOf(LIndex)
      else
        LText := LText + #13#10 + FLumps.TextOf(LIndex);
    end;

  for LPakText in PakTexts(SNDINFO_LUMP_NAME) + PakTexts(SNDINFO_LUMP_NAME + '.txt') do
  begin
    if LText = '' then
      LText := FPreprocessor.Preprocess(LPakText, False)
    else
      LText := LText + #13#10 + FPreprocessor.Preprocess(LPakText, False);
  end;

  FParseSoundInfo(LText);
end;

procedure TEngineActorDefLumps.ParseActorDefLumps;
var
  LIndex: Integer;
  LLumps: TDNumberList;
begin
  SC_ParseStatedefLump;

{$IFNDEF FPC}
  SUC_Disable;
{$ENDIF}

  LLumps := TDNumberList.Create;
  try
    for LIndex := 0 to FLumps.Count - 1 do
      if FLumps.NameOf(LIndex) = ACTORDEF_LUMP_NAME then
        LLumps.Add(LIndex);

    if decorate_as_actordef then
      for LIndex := 0 to FLumps.Count - 1 do
        if FLumps.NameOf(LIndex) = DECORATE_LUMP_NAME then
          LLumps.Add(LIndex);

{$IFNDEF FPC}
    SUC_SecondaryProgressInit(LLumps.Count);
{$ENDIF}

    for LIndex := 0 to LLumps.Count - 1 do
    begin
{$IFNDEF FPC}
      SUC_SecondaryProgress(LIndex);
{$ENDIF}
      ParseText(FLumps.TextOf(LLumps[LIndex]));
    end;

{$IFNDEF FPC}
    SUC_SecondaryProgressDone;
{$ENDIF}
    ParsePakTexts(ACTORDEF_LUMP_NAME);
    ParsePakTexts(ACTORDEF_LUMP_NAME + '.txt');

    if decorate_as_actordef then
    begin
      ParsePakTexts(DECORATE_LUMP_NAME);
      ParsePakTexts(DECORATE_LUMP_NAME + '.txt');
    end;
  finally
    LLumps.Free;
  end;

{$IFNDEF FPC}
  SUC_Enable;
{$ENDIF}
end;

end.
