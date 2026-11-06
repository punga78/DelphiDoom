{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what a definition of ACTORDEF does to the game         }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.ActorDef.Hooks;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The scripts, the patches, the thinkers and the preprocessor that a definition reaches for:
  ///   PascalScript and DEH of the engine, the PAK file system and the script preprocessor.
  ///   One class for four small interfaces
  /// </summary>
  TEngineActorDefHooks = class(TInterfacedObject, IActorDefThinkerSink, IActorDefScriptSink,
    IActorDefDehConsumer, IActorDefTextPreprocessor)
  private
    FLog: ILog;
    FParseText: TProc<string>;
  public
    /// <param name="AParseText">Reads a text of ACTORDEF: a thinker is an actor written as text</param>
    constructor Create(const ALog: ILog; const AParseText: TProc<string>);
    procedure SubmitThinker(const AThinker: TActorDefThinker);
    procedure AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
    procedure AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
    procedure AddCompiledScript(const AName, AFileName: string);
    procedure ParseDehFile(const AFileName: string);
    procedure ParseAllDehFiles(const AFileName: string);
    procedure ParseText(const AText: string);
    function Process(const AText: string): string;
  end;

implementation

uses
  d_delphi,
  deh_base,
  ps_main,
  sc_utils,
  w_pak;

{ TEngineActorDefHooks }

constructor TEngineActorDefHooks.Create(const ALog: ILog; const AParseText: TProc<string>);
begin
  inherited Create;
  FLog := ALog;
  FParseText := AParseText;
end;

procedure TEngineActorDefHooks.SubmitThinker(const AThinker: TActorDefThinker);
var
  LText: string;
  LIndex: Integer;

  procedure AddLine(const ALine: string);
  begin
    LText := LText + #13#10 + ALine;
  end;

begin
  if AThinker.RepeatCount < 0 then
  begin
    FLog.Warning(Format('SC_SubmitThinker(): Thinker %s has negative repeat count=%d'#13#10,
      [AThinker.Name, AThinker.RepeatCount]));
    Exit;
  end;
  if AThinker.Interval < 1 then
  begin
    FLog.Warning(Format('SC_SubmitThinker(): Thinker %s has invalid interval=%d'#13#10,
      [AThinker.Name, AThinker.Interval]));
    Exit;
  end;

  LText := '';
  AddLine('actor ' + AThinker.Name + ' ' + IntToStr(AThinker.Dn));
  AddLine('{');
  AddLine('    Health 10000');
  AddLine('    Radius 128');
  AddLine('    Height 128');
  AddLine('    Speed 0');
  AddLine('    Mass 1000');
  AddLine('    DONTDRAW');
  AddLine('    States');
  AddLine('    {');
  AddLine('    Spawn:');
  if AThinker.RepeatCount = 0 then
  begin
    AddLine('        NULL A ' + IntToStr(AThinker.Interval) + ' A_RunScript(' + AThinker.Script + ')');
    AddLine('        Loop');
  end
  else
  begin
    for LIndex := 0 to AThinker.RepeatCount - 1 do
      AddLine('        NULL A ' + IntToStr(AThinker.Interval) + ' A_RunScript(' + AThinker.Script + ')');
    AddLine('        Stop');
  end;
  AddLine('    }');
  FParseText(LText);
end;

function ScriptTypeOf(AType: TActorDefScriptType): psscripttype_t;
begin
  if AType = TActorDefScriptType.Global then
    Result := pst_global
  else
    Result := pst_normal;
end;

procedure TEngineActorDefHooks.AddSourceScript(const AName, ASource: string; AType: TActorDefScriptType);
begin
  PS_AddSourceScript(AName, ASource, ScriptTypeOf(AType));
end;

procedure TEngineActorDefHooks.AddExternalScript(const AName, AFileName: string; AType: TActorDefScriptType);
begin
  PS_AddSourceScript(AName, PAK_ReadFileAsString(AFileName), ScriptTypeOf(AType));
end;

procedure TEngineActorDefHooks.AddCompiledScript(const AName, AFileName: string);
begin
  PS_AddCompiledScript(AName, AFileName);
end;

procedure TEngineActorDefHooks.ParseDehFile(const AFileName: string);
begin
  DEH_ParseText(PAK_ReadFileAsString(AFileName));
end;

procedure TEngineActorDefHooks.ParseAllDehFiles(const AFileName: string);
begin
  DEH_ParseText(PAK_ReadAllFilesAsString(AFileName));
end;

procedure TEngineActorDefHooks.ParseText(const AText: string);
begin
  DEH_ParseText(AText);
end;

function TEngineActorDefHooks.Process(const AText: string): string;
begin
  Result := SC_Preprocess(AText, False);
end;

end.
