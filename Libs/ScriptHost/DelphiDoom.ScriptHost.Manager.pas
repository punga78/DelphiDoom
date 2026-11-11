{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the scripts of the game: sources, compiled code   }
{  and interpreters                                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is TPSExecManager of ps_main.pas, with its services given by the         }
{  constructor.                                                                }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.ScriptHost.Manager;

interface

uses
  System.SysUtils,
  d_delphi,
  p_mobj_h,
  ps_compiler,
  ps_import,
  DelphiDoom.Engine.Script.ActorContext.Intf,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ScriptHost.Events.Intf,
  DelphiDoom.ScriptHost.Services.Intf;

type
  /// <summary>The kind of a script that is added: a normal one, the global one (its parts are merged) or none</summary>
  TScriptKind = (skNormal, skGlobal, skNone);

  /// <summary>
  ///   The scripts of the game: the sources, the compiled code, one interpreter for each, and the
  ///   interpreter that the events of the map run in. It was TPSExecManager of ps_main.pas
  /// </summary>
  TScriptManager = class
  private
    type
      TScriptItem = record
        exec: TDoomExec;
        id: TString;
        source: TString;
        data: TString;
        kind: TScriptKind;
        valid: Boolean;
      end;
      PScriptItem = ^TScriptItem;
      TScriptItemArray = array[0..$FFF] of TScriptItem;
      PScriptItemArray = ^TScriptItemArray;
  private
    fList: PScriptItemArray;
    fNumItems: integer;
    compiler: TDoomCompiler;
    importer: TPSDoomRuntimeClassImporter;
    globalexec: TDoomExec;
    feventsexec: TDoomExec;
    fevents: IScriptEvents;
    globalindex: integer;
    fGlobalInterface: string;
    fGlobalImplementation: string;
    fGlobalInitialization: string;
    FServices: IScriptHostServices;
    FActorContext: IEngineScriptActorContext;
    FLog: ILog;
    FVerbose: TFunc<Boolean>;
  public
    /// <summary>AVerbose says if the sources are printed after they compile (-devparm); it may be nil</summary>
    /// <exception cref="EArgumentNilException">If a service is nil</exception>
    constructor Create(const AServices: IScriptHostServices; const AActorContext: IEngineScriptActorContext;
      const ALog: ILog; const AOnExportCheck: TPSOnExportCheck; const AVerbose: TFunc<Boolean>);
    destructor Destroy; override;
    function IndexOf(const id: string): integer;
    function AddNormalSourceFile(const id: string; const value: string): integer;
    function AddGlobalSourceFile(const id: string; const value: string): integer;
    function AddSourceFile(const id: string; const value: string; const typ: TScriptKind): integer;
    function AddCompiledFile(const id: string; const value: string): integer;
    procedure CompileScript(const id: Integer);
    procedure CompileAllScripts;
    function RunScript(actor: Pmobj_t; const scid: integer): boolean;
    procedure LinkScriptEvents(const mapname: string);
    property Count: integer read fNumItems;
    property Events: IScriptEvents read fevents;
    property EventsExec: TDoomExec read feventsexec;
    property DoomCompiler: TDoomCompiler read compiler;
    property DoomImporter: TPSDoomRuntimeClassImporter read importer;
  end;

implementation

uses
  ps_defs,
  ps_runtime,
  ps_utils,
  i_system,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Serializer.Intf,
  DelphiDoom.ScriptHost.Events.Table;
//==============================================================================
//
// TScriptManager.Create
//
//==============================================================================
constructor TScriptManager.Create(const AServices: IScriptHostServices;
  const AActorContext: IEngineScriptActorContext; const ALog: ILog; const AOnExportCheck: TPSOnExportCheck;
  const AVerbose: TFunc<Boolean>);
begin
  inherited Create;
  if not Assigned(AServices) then
    raise EArgumentNilException.Create('AServices');
  if not Assigned(AActorContext) then
    raise EArgumentNilException.Create('AActorContext');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FServices := AServices;
  FActorContext := AActorContext;
  FLog := ALog;
  FVerbose := AVerbose;
  fList := nil;
  fNumItems := 0;
  globalindex := -1;
  fGlobalInterface := '';
  fGlobalImplementation := '';
  fGlobalInitialization := '';
  compiler := TDoomCompiler.CreateDoomCompiler(FServices);
  compiler.OnExportCheck := AOnExportCheck;
  importer := TPSDoomRuntimeClassImporter.CreateDoomImporter(FServices);
  globalexec := nil;
  feventsexec := TDoomExec.CreateDoomExec(importer, FServices);
  fevents := TScriptHostFactory.CreateEvents(feventsexec, FLog);
  AddNormalSourceFile('GLOBAL', '');
end;

//==============================================================================
//
// TScriptManager.Destroy
//
//==============================================================================
destructor TScriptManager.Destroy;
var
  i: integer;
begin
  if fNumItems > 0 then
  begin
    for i := 0 to fNumItems - 1 do
    begin
      fList[i].source.Free;
      fList[i].data.Free;
      fList[i].id.Free;
      fList[i].exec.Free;
    end;
    memfree(pointer(fList), fNumItems * SizeOf(TScriptItem));
  end;
  compiler.Free;
  importer.Free;
  fevents := nil;
  feventsexec.Free;
end;

//==============================================================================
//
// TScriptManager.AddNormalSourceFile
//
//==============================================================================
function TScriptManager.AddNormalSourceFile(const id: string; const value: string): integer;
var
  uid: string;
begin
  uid := strupper(id);
  Result := IndexOf(uid);
  if Result <> - 1 then
  begin
    I_Warning('TScriptManager.AddNormalSourceFile(): Script id="' + uid + '" already exists.'#13#10);
    exit;
  end;

  realloc(pointer(fList), fNumItems * SizeOf(TScriptItem), (fNumItems + 1) * SizeOf(TScriptItem));
  fList[fNumItems].source := TString.Create(value);
  fList[fNumItems].exec := nil;
  fList[fNumItems].id := TString.Create(uid);
  fList[fNumItems].data := nil;
  fList[fNumItems].kind := skNormal;
  fList[fNumItems].valid := False;
  Result := fNumItems;

  inc(fNumItems);
end;

//==============================================================================
//
// TScriptManager.AddGlobalSourceFile
//
//==============================================================================
function TScriptManager.AddGlobalSourceFile(const id: string; const value: string): integer;
var
  slist: TDStringList;
  i: integer;
  section: integer;
  s, token: string;
begin
  slist := TDStringList.Create;
  slist.Text := value;

  // JVAL: Split the input source to sections
  fGlobalInterface :=
    fGlobalInterface +
      '// --- "' + id + '" Interface --- '#13#10;
  fGlobalImplementation :=
    fGlobalImplementation +
      '// --- "' + id + '" Implementation --- '#13#10;
  fGlobalInitialization :=
    fGlobalInitialization +
      '// --- "' + id + '" Initialization --- '#13#10;

  section := 0; // Means "interface"
  for i := 0 to slist.Count - 1 do
  begin
    s := slist.Strings[i];
    token := strupper(strtrim(s));
    if token = 'INTERFACE' then
      section := 0
    else if token = 'IMPLEMENTATION' then
      section := 1
    else if token = 'INITIALIZATION' then
      section := 2
    else
    begin
      case section of
        0:
          begin
            fGlobalInterface := fGlobalInterface + s + #13#10;
          end;
        1:
          begin
            fGlobalImplementation := fGlobalImplementation + s + #13#10;
          end;
        2:
          begin
            if strupper(strtrim(s)) <> 'END.' then
              fGlobalInitialization := fGlobalInitialization + s + #13#10;
          end;
      end;
    end;
  end;
  slist.Free;
  Result := IndexOf('GLOBAL');
end;

//==============================================================================
//
// TScriptManager.AddSourceFile
//
//==============================================================================
function TScriptManager.AddSourceFile(const id: string; const value: string;
      const typ: TScriptKind): integer;
begin
  if typ = skGlobal then
    result := AddGlobalSourceFile(id, value)
  else if typ = skNormal then
    result := AddNormalSourceFile(id, value)
  else
  begin
    I_Warning('TScriptManager.AddSourceFile(): Internal error! Unidentified script type.'#13#10);
    Result := -1;
  end;
end;

//==============================================================================
//
// TScriptManager.AddCompiledFile
//
//==============================================================================
function TScriptManager.AddCompiledFile(const id: string; const value: string): integer;
var
  uid: string;
begin
  uid := strupper(id);
  Result := IndexOf(uid);
  if Result <> - 1 then
  begin
    I_Warning('TScriptManager.AddCompiledFile(): Script id="' + uid + '" already exists.'#13#10);
    exit;
  end;

  realloc(pointer(fList), fNumItems * SizeOf(TScriptItem), (fNumItems + 1) * SizeOf(TScriptItem));
  fList[fNumItems].source := nil;
  fList[fNumItems].exec := nil;
  fList[fNumItems].id := TString.Create(uid);
  fList[fNumItems].data := TString.Create(value);
  fList[fNumItems].kind := skNormal;
  fList[fNumItems].valid := False;
  Result := fNumItems;

  inc(fNumItems);
end;

//==============================================================================
//
// PS_BytesToStr
// Compiled script bytecode is binary: keep a 1:1 mapping between byte values
// and character codes, independently of the system code page.
//
//==============================================================================
function PS_BytesToStr(const a: TbtString): string;
var
  i: integer;
begin
  SetLength(Result, Length(a));
  for i := 1 to Length(a) do
    Result[i] := Char(Ord(a[i]));
end;

//==============================================================================
//
// PS_StrToBytes
//
//==============================================================================
function PS_StrToBytes(const s: string): TbtString;
var
  i: integer;
begin
  SetLength(Result, Length(s));
  for i := 1 to Length(s) do
    Result[i] := TbtChar(Ord(s[i]));
end;

//==============================================================================
//
// TScriptManager.CompileScript
//
//==============================================================================
procedure TScriptManager.CompileScript(const id: Integer);
var
  clist: TDStringList;
  i: integer;
  data: TbtString;
  DE: TDoomExec;
begin
  if fList[id].valid then
    exit;

  if flist[id].source = nil then
  begin
    if fList[id].exec = nil then
      fList[id].exec := TDoomExec.CreateDoomExec(importer, FServices);
    DE := fList[id].exec;
    fList[id].valid := DE.LoadData(PS_StrToBytes(fList[id].data.str)); // Load the data from the Data string.
    if not fList[id].valid then
    begin
      { For some reason the script could not be loaded. This is usually the case when a
        library that has been used at compile time isn't registered at runtime. }
      // JVAL: This could happen if script was compiled with previous version of pscomp
      I_Warning('TScriptManager.Add(): Internal error! Can not load script assembly.'#13#10);
      I_Warning(string(TIFErrorToString(DE.ExceptionCode, DE.ExceptionString)) + #13#10);
    end;
    exit;
  end;

  if compiler.CompileDoomScript(TbtString(flist[id].source.str), data) then
  begin
    fList[id].data := TString.Create(PS_BytesToStr(data));
    if fList[id].exec = nil then
      fList[id].exec := TDoomExec.CreateDoomExec(importer, FServices);
    DE := fList[id].exec;
    fList[id].valid := DE.LoadData(data); // Load the data from the Data string.
    if not fList[id].valid then
    begin
      { For some reason the script could not be loaded. This is usually the case when a
        library that has been used at compile time isn't registered at runtime. }
      // JVAL: This could happen if script was compiled with previous version of pscomp
      I_Warning('TScriptManager.Add(): Internal error! Can not load script assembly.'#13#10);
      I_Warning(string(TIFErrorToString(DE.ExceptionCode, DE.ExceptionString)) + #13#10);
    end;
    if Assigned(FVerbose) and FVerbose() then
    begin
      clist := TDStringList.Create;
      clist.Text := flist[id].source.str;
      for i := 0 to clist.Count - 1 do
        printf(IntToStrZfill(6, i + 1) + ': ' + clist.Strings[i] + #13#10);
      clist.Free;
    end;
  end
  else
  begin
    I_Warning('TScriptManager.Add(): Can not compile script:'#13#10);
    clist := TDStringList.Create;
    clist.Text := flist[id].source.str;
    for i := 0 to clist.Count - 1 do
      I_Warning(IntToStrZfill(6, i + 1) + ': ' + clist.Strings[i] + #13#10);
    for i := 0 to compiler.MsgCount - 1 do
    begin
      I_Warning('//---------------------------------------------------------'#13#10);
      I_Warning(' Pos: ' + IntToStrZFill(6, compiler.Msg[i].Pos) +
                ' Compiler: ' + string(compiler.Msg[i].MessageToString) + #13#10);
      I_Warning(' <<' + Copy(flist[id].source.str, compiler.Msg[i].Pos, 80) + '>>'#13#10);
      I_Warning('//---------------------------------------------------------'#13#10);
    end;
    clist.Free;
  end;
end;

//==============================================================================
//
// TScriptManager.CompileAllScripts
//
//==============================================================================
procedure TScriptManager.CompileAllScripts;
var
  i: integer;
  globalsource: string;
begin
  globalindex := IndexOf('GLOBAL');
  if globalindex < 0 then // JVAL: Should not happen
    I_Warning('TScriptManager.CompileAllScripts(): GLOBAL Script not found.'#13#10)
  else
  begin
    globalsource :=
      'uses all;'#13#10 +
      fGlobalInterface +
      fGlobalImplementation +
      'begin'#13#10 +
      fGlobalInitialization +
      'end.'#13#10;
    fList[globalindex].source.str := globalsource;
    fList[globalindex].exec := globalexec;
    fList[globalindex].data := nil;
    fList[globalindex].kind := skGlobal;
    fList[globalindex].valid := False;
  end;

  for i := 0 to fNumItems - 1 do
  begin
    CompileScript(i);
    if fList[i].valid then
      printf(' "%s"...success'#13#10, [fList[i].id.str])
    else
    begin
      I_Warning(' "%s"...failed'#13#10, [fList[i].id.str]);
      I_Warning('//---------------------------------------------------------'#13#10);
      I_Warning(#13#10);
    end;
  end;

  globalexec := fList[globalindex].exec;
end;

//==============================================================================
//
// TScriptManager.RunScript
//
//==============================================================================
function TScriptManager.RunScript(actor: Pmobj_t; const scid: integer): boolean;
var
  DE: TDoomExec;
begin
  if scid > - 1 then
    if fList[scid].valid then
    begin
      FActorContext.Enter(actor);
      DE := fList[scid].exec;
      result := DE.RunScript;
      if DE.ExceptionCode <> erNoError then
        I_Warning('[Runtime Error] : ' +
          string(TIFErrorToString(DE.ExceptionCode, DE.ExceptionString)) +
          ' in ' +
          itoa(DE.ExceptionProcNo) +
          ' at ' +
          itoa(DE.ExceptionPos));
      FActorContext.Leave;
      exit;
    end;

  result := false;
end;

//==============================================================================
//
// TScriptManager.LinkScriptEvents
//
//==============================================================================
procedure TScriptManager.LinkScriptEvents(const mapname: string);
var
  idx: Integer;

  function ValidateVarType(aType: TPSTypeRec): string;
  var
    I: Integer;
  begin
    //Check against our set of allowed types
    if not (aType.BaseType in SCRIPT_SERIALIZABLE_TYPES) then
    begin
      sprintf(Result, 'TScriptManager.LinkScriptEvents(): Unsupported global variable type %d (%s)'#13#10,
        [aType.BaseType, aType.ExportName]);
      Exit;
    end;

    //Check elements of arrays/records are valid too
    case aType.BaseType of
      btArray,
      btStaticArray:
        Result := ValidateVarType(TPSTypeRec_Array(aType).ArrayType);
      btRecord:
        begin
          Result := '';
          for I := 0 to TPSTypeRec_Record(aType).FieldTypes.Count - 1 do
            Result := Result + ValidateVarType(TPSTypeRec_Record(aType).FieldTypes[I]);
        end;
    end;
  end;

var
  i, j: integer;
  V: PIFVariant;
  errstr: string;
  errlst: TDStringList;
  data: string;
  uS: string;
begin
  fevents.Clear;
  idx := IndexOf(mapname);
  if idx < 0 then
  begin
    data := FServices.Sources.ReadText(mapname + '.ddout');
    if data <> '' then
      idx := AddCompiledFile(mapname, data);
    if idx < 0 then
    begin
      data := FServices.Sources.ReadText(mapname + '.ddscript');
      if data <> '' then
        idx := AddNormalSourceFile(mapname, data);
      if idx < 0 then
      begin
        feventsexec.Clear;
        Exit;
      end;
      CompileScript(idx);
    end;
  end;

  if not fList[idx].valid then
    Exit;

  if not feventsexec.LoadData(PS_StrToBytes(fList[idx].data.str)) then
  begin
    I_Warning('TScriptManager.LinkScriptEvents(): Internal error! Can not load script assembly.'#13#10);
    I_Warning(string(TIFErrorToString(feventsexec.ExceptionCode, feventsexec.ExceptionString)) + #13#10);
    feventsexec.Clear;
    Exit;
  end;

  errstr := '';
  for i := 0 to feventsexec.GetVarCount - 1 do
  begin
    V := feventsexec.GetVarNo(I);
    uS := strupper(string(V.FType.ExportName));
    if (uS = '!TACTORS') or
       (uS = '!TMAPFLOATS') or
       (uS = '!TMAPINTEGERS') or
       (uS = '!TMAPSTRINGS') or
       (uS = '!TWORLDFLOATS') or
       (uS = '!TWORLDINTEGERS') or
       (uS = '!TWORLDSTRINGS') or
       (uS = '!TVERTEXES') or
       (uS = '!TSIDES') or
       (uS = '!TLINES') or
       (uS = '!TSECTORS') or
       (uS = '!TOVERLAY') or
       (uS = '!TMOBJINFO') then
      Continue;

    errstr := ValidateVarType(V.FType);
    if errstr <> '' then
    begin
      errlst := TDStringList.Create;
      errlst.Text := errstr;
      for j := 0 to errlst.Count - 1 do
        I_Warning(errlst.Strings[j]);
      errlst.Free;
      //Don't allow the script to run
      feventsexec.Clear;
      Exit;
    end;
  end;
  fevents.LinkEvents;
end;

//==============================================================================
//
// TScriptManager.IndexOf
//
//==============================================================================
function TScriptManager.IndexOf(const id: string): integer;
var
  check: string;
  i: integer;
begin
  check := strupper(id);
  for i := 0 to fNumItems - 1 do
    if flist[i].id.str = check then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;


end.
