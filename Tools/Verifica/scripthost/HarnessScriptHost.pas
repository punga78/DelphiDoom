{******************************************************************************}
{                                                                              }
{  TEMPORARY HARNESS of issue #173 (never part of the engine projects).        }
{  The same unit is compiled in the old tree (919a19ef) and in the new one,    }
{  with the same hooks (hook-scripthost.patch), so that what it writes can     }
{  be compared line by line (Confronta.ps1).                                   }
{                                                                              }
{    VSH_AfterPSInit  at the end of PS_Init (ps_main): gets the compiler and   }
{                     the importer of the script manager                       }
{    VSH_AfterLevel   at the end of TLevelLoader.SetupLevel                    }
{                                                                              }
{  Command line:                                                               }
{    -vsh l2     level L2: after the first level a battery of scripts, one     }
{                for every host function that scripts can call (the list is    }
{                read from the compiler itself), each with fixed safe          }
{                arguments; after every function a FNV-1a of the state of the  }
{                level; then Halt(0). Files (current directory):               }
{                  verify_scripthost_L2.txt          one line per function     }
{                  verify_scripthost_L2_scripts.txt  the generated scripts     }
{                  verify_scripthost_L2_progress.txt the function being run    }
{                                                    (where a crash happened)  }
{    -vsh save   adds to the scripts of the maps a script with global          }
{                variables and events (mapvars, worldvars, state of the        }
{                script): the savegames then contain the state of the scripts  }
{    -vshskip a,b   functions to skip (in addition to the default list)        }
{    -vshfrom N     starts from the N-th function (0 based)                    }
{    -vshonly <text>  only the functions whose name contains the text          }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
{$Q-}
{$R-}
unit HarnessScriptHost;

interface

uses
  p_mobj_h,
  ps_compiler,
  ps_runtime;

procedure VSH_AfterPSInit(ACompiler: TPSPascalCompiler; AImporter: TPSRuntimeClassImporter);

procedure VSH_AfterLevel(const AMapName: string);

// at the end of every PS_EventTick: -vsh demo writes the last state of the first player (verify_scripthost_demo.txt)
procedure VSH_AfterTick(ATick: Integer);

type
  /// runs the script with the name for the actor, the way A_RunScript does (psmanager.RunScript); false if there is no such script
  TVshScriptRunner = reference to function(const AActor: Pmobj_t; const AName: string): Boolean;

// given by the hook of ps_main (the routines are not in its interface)
procedure VSH_SetScriptRunner(const ARunner: TVshScriptRunner);

implementation

uses
  SysUtils,
  Classes,
  Generics.Collections,
  StrUtils,
  ps_defs,
  ps_utils,
  d_think,
  ps_import,
  ps_main,
  psi_game,
  psi_globals,
  r_defs,
  r_data,
  w_wad,
  g_game,
  d_player,
  p_mobj,
  p_mobjlist,
  p_tick,
  p_setup;

type
  TVshParameter = record
    Name: string;
    TypeName: string;
    Mode: TPSParameterMode;
    BaseType: Byte;
    ElementBase: Byte;
  end;

  TVshFunction = record
    UnitName: string;
    Name: string;
    Parameters: TArray<TVshParameter>;
    HasResult: Boolean;
    ResultTypeName: string;
    ResultBase: Byte;
    ResultElement: Byte;
  end;

const
  /// a step of the plan that does not repeat the function for the values of "typ"
  NO_TYPE_VALUE = -2147483647;
  // functions that would end the level or the game, or need names that depend on the game
  DEFAULT_SKIP = ',G_EXITLEVEL,G_SECRETEXITLEVEL,CONSOLECOMMAND,PLAYSOUND,ACTORPLAYSOUND,SECTORPLAYSOUND,' +
    'SPAWNACTORNAME,';

var
  GRunner: TVshScriptRunner = nil;
  GMode: string = '';
  GSkip: string = DEFAULT_SKIP;
  GFrom: Integer = 0;
  GOnly: string = '';
  // -vshtypes 0,1,2,-1: the values of the parameter "typ" (mobj types) that the functions of mobjinfo are called with
  GTypeValues: TList<Integer> = nil;
  GTypeArg: Integer = 1;
  GCompiler: TPSPascalCompiler = nil;
  GImporter: TPSRuntimeClassImporter = nil;
  GFnv: Cardinal;
  GFunctions: TList<TVshFunction> = nil;
  GCaptureUnit: string;
  GCaptureFrom: Integer;
  GKeys: array[0..2] of LongWord;
  GTextureName: string = 'STARTAN1';
  GFlatName: string = 'FLOOR0_1';

// the implicit actor of the functions that take the key 0 (the old tree has a variable, the new one a context)
procedure SetContext(const AActor: Pmobj_t);
begin
{$IF DECLARED(PS_ActorContext)}
  if AActor <> nil then
    PS_ActorContext.Enter(AActor)
  else
    PS_ActorContext.Leave;
{$ELSE}
  ps_currentactor := AActor;
{$IFEND}
end;

// ---- FNV-1a ------------------------------------------------------------------------------------

procedure FnvReset;
begin
  GFnv := $811C9DC5;
end;

procedure FnvByte(AValue: Byte);
begin
  GFnv := (GFnv xor AValue) * 16777619;
end;

procedure FnvInt(AValue: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    FnvByte(Byte((AValue shr (8 * LIndex)) and $FF));
end;

// ---- the state of the level, after every function --------------------------------------------

function StateFingerprint: Cardinal;
var
  LIndex: Integer;
  LThinker: Pthinker_t;
  LMobj: Pmobj_t;
begin
  FnvReset;
  for LIndex := 0 to numsectors - 1 do
  begin
    FnvInt(sectors[LIndex].floorheight);
    FnvInt(sectors[LIndex].ceilingheight);
    FnvInt(sectors[LIndex].floorpic);
    FnvInt(sectors[LIndex].ceilingpic);
    FnvInt(sectors[LIndex].lightlevel);
    FnvInt(sectors[LIndex].special);
    FnvInt(sectors[LIndex].tag);
  end;
  for LIndex := 0 to numlines - 1 do
  begin
    FnvInt(lines[LIndex].flags);
    FnvInt(lines[LIndex].special);
{$IFDEF HEXEN}
    FnvInt(lines[LIndex].arg1);
    FnvInt(lines[LIndex].arg2);
{$ELSE}
    FnvInt(lines[LIndex].tag);
{$ENDIF}
  end;
  for LIndex := 0 to numsides - 1 do
  begin
    FnvInt(sides[LIndex].textureoffset);
    FnvInt(sides[LIndex].rowoffset);
    FnvInt(sides[LIndex].toptexture);
    FnvInt(sides[LIndex].bottomtexture);
    FnvInt(sides[LIndex].midtexture);
  end;
  LThinker := thinkercap.next;
  LIndex := 0;
  while (LThinker <> nil) and (LThinker <> @thinkercap) and (LIndex < 100000) do
  begin
    if @LThinker._function.acp1 = @P_MobjThinker then
    begin
      LMobj := Pmobj_t(LThinker);
      FnvInt(Integer(LMobj.key));
      FnvInt(LMobj.x);
      FnvInt(LMobj.y);
      FnvInt(LMobj.z);
      FnvInt(Integer(LMobj.angle));
      FnvInt(LMobj.momx);
      FnvInt(LMobj.momy);
      FnvInt(LMobj.momz);
      FnvInt(LMobj.health);
      FnvInt(Integer(LMobj.flags));
    end;
    LThinker := LThinker.next;
    Inc(LIndex);
  end;
  FnvInt(LIndex);
  FnvInt(players[0].health);
  FnvInt(Ord(players[0].playerstate));
  Result := GFnv;
end;

// the keys of the first three mobjs (the first is the player)
procedure FindKeys;
var
  LThinker: Pthinker_t;
  LCount: Integer;
  LGuard: Integer;
begin
  LCount := 0;
  LGuard := 0;
  LThinker := thinkercap.next;
  while (LThinker <> nil) and (LThinker <> @thinkercap) and (LCount < 3) and (LGuard < 100000) do
  begin
    if @LThinker._function.acp1 = @P_MobjThinker then
    begin
      GKeys[LCount] := Pmobj_t(LThinker).key;
      Inc(LCount);
    end;
    LThinker := LThinker.next;
    Inc(LGuard);
  end;
  while LCount < 3 do
  begin
    GKeys[LCount] := GKeys[0];
    Inc(LCount);
  end;
end;

// names that exist in the level that was loaded (the ones of the game of the build)
procedure FindNames;
var
  LIndex: Integer;
  LNumber: Integer;
begin
  for LIndex := 0 to numsides - 1 do
  begin
    LNumber := sides[LIndex].midtexture;
    if LNumber <= 0 then
      LNumber := sides[LIndex].toptexture;
    if LNumber <= 0 then
      LNumber := sides[LIndex].bottomtexture;
    if LNumber > 0 then
    begin
      GTextureName := char8tostring(R_NameForSideTexture(SmallInt(LNumber)));
      Break;
    end;
  end;
  if numsectors > 0 then
    GFlatName := char8tostring(W_GetNameForNum(R_GetLumpForFlat(sectors[0].floorpic)));
end;

// ---- the list of the host functions, read from the compiler -----------------------------------

function ParameterOf(ADecl: TPSParametersDecl; AIndex: Integer): TVshParameter;
var
  LType: TPSType;
begin
  Result.Name := string(ADecl.Params[AIndex].OrgName);
  Result.Mode := ADecl.Params[AIndex].Mode;
  LType := ADecl.Params[AIndex].aType;
  Result.TypeName := string(LType.Name);
  Result.BaseType := Byte(LType.BaseType);
  Result.ElementBase := 0;
  if LType is TPSArrayType then
    if TPSArrayType(LType).ArrayTypeNo <> nil then
      Result.ElementBase := Byte(TPSArrayType(LType).ArrayTypeNo.BaseType);
end;

procedure CaptureProcedures(ACompiler: TPSPascalCompiler; AFrom: Integer; const AUnit: string);
var
  LIndex: Integer;
  LParam: Integer;
  LProc: TPSRegProc;
  LFunction: TVshFunction;
begin
  for LIndex := AFrom to ACompiler.GetRegProcCount - 1 do
  begin
    LProc := ACompiler.GetRegProc(LIndex);
    LFunction.UnitName := AUnit;
    LFunction.Name := string(LProc.OrgName);
    SetLength(LFunction.Parameters, LProc.Decl.ParamCount);
    for LParam := 0 to LProc.Decl.ParamCount - 1 do
      LFunction.Parameters[LParam] := ParameterOf(LProc.Decl, LParam);
    LFunction.HasResult := LProc.Decl.Result <> nil;
    LFunction.ResultTypeName := '';
    LFunction.ResultBase := 0;
    LFunction.ResultElement := 0;
    if LFunction.HasResult then
    begin
      LFunction.ResultTypeName := string(LProc.Decl.Result.Name);
      LFunction.ResultBase := Byte(LProc.Decl.Result.BaseType);
      if LProc.Decl.Result is TPSArrayType then
        if TPSArrayType(LProc.Decl.Result).ArrayTypeNo <> nil then
          LFunction.ResultElement := Byte(TPSArrayType(LProc.Decl.Result).ArrayTypeNo.BaseType);
    end;
    GFunctions.Add(LFunction);
  end;
end;

function CaptureOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  LFrom: Integer;
  LIndex: Integer;
begin
  LFrom := Sender.GetRegProcCount;
  Result := PS_ScriptOnUses(Sender, Name);
  if string(Name) = 'SYSTEM' then
  begin
    // the host functions of SYSTEM follow the ones of the Pascal Script library and of its
    // date and time unit: they start at OutputDebugString
    LFrom := -1;
    for LIndex := 0 to Sender.GetRegProcCount - 1 do
      if SameText(string(Sender.GetRegProc(LIndex).OrgName), 'OutputDebugString') then
      begin
        LFrom := LIndex;
        Break;
      end;
    if LFrom < 0 then
      LFrom := Sender.GetRegProcCount;
    GCaptureFrom := LFrom;
  end
  else
    GCaptureFrom := LFrom;
  // the implicit SYSTEM of every compilation belongs to the capture of SYSTEM only
  if (string(Name) <> 'SYSTEM') or (GCaptureUnit = 'SYSTEM') then
    CaptureProcedures(Sender, GCaptureFrom, GCaptureUnit);
end;

procedure CaptureUnit(const AUnit: string; const ACaptured: string);
var
  LPCode: TbtString;
begin
  GCaptureUnit := ACaptured;
  GCompiler.OnUses := CaptureOnUses;
  try
    // SYSTEM is always implicit: a "uses SYSTEM" would register it twice
    if AUnit = '' then
      (GCompiler as TDoomCompiler).CompileDoomScript(TbtString('begin' + #13#10 + 'end.'#13#10), LPCode)
    else
      (GCompiler as TDoomCompiler).CompileDoomScript(TbtString('uses ' + AnsiString(AUnit) + ';' + #13#10 + 'begin' + #13#10 + 'end.'#13#10), LPCode);
  finally
    GCompiler.OnUses := PS_ScriptOnUses;
  end;
end;

// ---- the script of a function -------------------------------------------------------------------

function IsStringBase(ABase: Byte): Boolean;
begin
  Result := (ABase = btString) or (ABase = btUnicodeString) or (ABase = btWideString);
end;

function IsIntegerBase(ABase: Byte): Boolean;
begin
  Result := ABase in [btU8, btS8, btU16, btS16, btU32, btS32, btS64];
end;

function IsFloatBase(ABase: Byte): Boolean;
begin
  Result := ABase in [btSingle, btDouble, btExtended];
end;

// the literal of an argument, or '' if the function cannot be called with a literal
function ArgumentLiteral(const AParameter: TVshParameter): string;
var
  LName: string;
begin
  LName := LowerCase(AParameter.Name);
  Result := '';
  if IsIntegerBase(AParameter.BaseType) then
  begin
    if AParameter.BaseType = btU32 then
    begin
      if LName = 'key' then
        Exit(IntToStr(GKeys[1]));
      if (LName = 'targ') or (LName = 'target') or (LName = 'tracer') or (LName = 'master') or
         (LName = 'killer') or (LName = 'source') then
        Exit(IntToStr(GKeys[2]));
      Exit('1');
    end;
    if LName = 'typ' then
      Exit(IntToStr(GTypeArg));
    if StartsText('pl', LName) then
      Exit('0');
    if AParameter.BaseType = btS32 then
    begin
      // fixed point values are integers: 1.0 in 16.16
      if (LName = 'x') or (LName = 'y') or (LName = 'z') or (LName = 'h') or (LName = 'speed') then
        Exit('65536');
    end;
    Exit('1');
  end;
  if IsFloatBase(AParameter.BaseType) then
    Exit('1.5');
  if IsStringBase(AParameter.BaseType) then
  begin
    if ContainsText(LName, 'tex') then
      Exit('''' + GTextureName + '''');
    if ContainsText(LName, 'pic') then
      Exit('''' + GFlatName + '''');
    Exit('''vsh''');
  end;
  if AParameter.TypeName = 'BOOLEAN' then
    Exit('True');
  if AParameter.BaseType = btEnum then
    Exit('0');
  if (AParameter.BaseType = btArray) and (AParameter.ElementBase = btVariant) then
    Exit('[]');
end;

function ResultExpression(const AFunction: TVshFunction): string;
begin
  if AFunction.ResultTypeName = 'BOOLEAN' then
    Exit('IFS(vshr, ''T'', ''F'')');
  if IsIntegerBase(AFunction.ResultBase) then
    Exit('IntToStr(vshr)');
  if IsFloatBase(AFunction.ResultBase) then
    Exit('FloatToStr(vshr)');
  if IsStringBase(AFunction.ResultBase) then
    Exit('vshr');
  if AFunction.ResultBase = btEnum then
    Exit('IntToStr(vshr)');
  if AFunction.ResultBase = btArray then
    Exit('IntToStr(GetArrayLength(vshr))');
  Result := '';
end;

// '' if no script can be made for the function
function BuildScript(const AFunction: TVshFunction): string;
var
  LIndex: Integer;
  LLiteral: string;
  LArguments: string;
  LDeclarations: string;
  LPreparation: string;
  LCall: string;
  LResult: string;
begin
  Result := '';
  LArguments := '';
  LDeclarations := '';
  LPreparation := '';
  for LIndex := 0 to Length(AFunction.Parameters) - 1 do
  begin
    if AFunction.Parameters[LIndex].Mode <> pmIn then
    begin
      LDeclarations := LDeclarations + Format('  vshp%d: %s;'#13#10, [LIndex, AFunction.Parameters[LIndex].TypeName]);
      LLiteral := Format('vshp%d', [LIndex]);
    end
    else if (AFunction.Parameters[LIndex].BaseType = btArray) and (AFunction.Parameters[LIndex].ElementBase <> btVariant) then
    begin
      LDeclarations := LDeclarations + Format('  vshp%d: %s;'#13#10, [LIndex, AFunction.Parameters[LIndex].TypeName]);
      LPreparation := LPreparation + Format('  SetArrayLength(vshp%d, 2);'#13#10, [LIndex]);
      LLiteral := Format('vshp%d', [LIndex]);
    end
    else
    begin
      LLiteral := ArgumentLiteral(AFunction.Parameters[LIndex]);
      if LLiteral = '' then
        Exit;
    end;
    if LIndex > 0 then
      LArguments := LArguments + ', ';
    LArguments := LArguments + LLiteral;
  end;
  if LArguments <> '' then
    LCall := AFunction.Name + '(' + LArguments + ')'
  else
    LCall := AFunction.Name;
  if AFunction.HasResult then
  begin
    LResult := ResultExpression(AFunction);
    if LResult = '' then
      Exit;
    LDeclarations := LDeclarations + Format('  vshr: %s;'#13#10, [AFunction.ResultTypeName]);
    LCall := '  vshr := ' + LCall + ';'#13#10 + '  SetMapString(''vsh_result'', ' + LResult + ');'#13#10;
  end
  else
    LCall := '  ' + LCall + ';'#13#10 + '  SetMapString(''vsh_result'', ''void'');'#13#10;
  Result := 'uses ' + AFunction.UnitName + ';'#13#10;
  if LDeclarations <> '' then
    Result := Result + 'var'#13#10 + LDeclarations;
  Result := Result + 'begin'#13#10 + LPreparation + LCall + 'end.'#13#10;
end;

function IsSkipped(const AFunction: TVshFunction): Boolean;
begin
  Result := ContainsText(GSkip, ',' + AFunction.Name + ',');
  // the Polyobj family ends the game (I_Error of po_man) for a polyobj that the level does not have
  if StartsText('Polyobj_', AFunction.Name) then
    Result := True;
  if (GOnly <> '') and not ContainsText(AFunction.Name, GOnly) then
    Result := True;
end;

function HasTypeParameter(const AFunction: TVshFunction): Boolean;
var
  LParameter: TVshParameter;
begin
  Result := False;
  for LParameter in AFunction.Parameters do
    if SameText(LParameter.Name, 'typ') then
      Exit(True);
end;

procedure WriteProgress(const AText: string);
var
  LFile: TextFile;
begin
  AssignFile(LFile, 'verify_scripthost_L2_progress.txt');
  Rewrite(LFile);
  Writeln(LFile, AText);
  CloseFile(LFile);
end;

procedure RunBattery;
var
  LResults: TStringList;
  LScripts: TStringList;
  LIndex: Integer;
  LFunction: TVshFunction;
  LScript: string;
  LPCode: TbtString;
  LExec: TDoomExec;
  LText: string;
  LOk: Boolean;
  LPlan: TList<TPair<Integer, Integer>>;
  LStep: Integer;
  LValue: Integer;
  LSuffix: string;
begin
  LResults := TStringList.Create;
  LScripts := TStringList.Create;
  try
    FindKeys;
    FindNames;
    GFunctions := TList<TVshFunction>.Create;
    // the same units as the compiler gives: SYSTEM first, then the others in the order of the names
    CaptureUnit('', 'SYSTEM');
    CaptureUnit('PS_FIXED', 'PS_FIXED');
    CaptureUnit('PS_GAME', 'PS_GAME');
    CaptureUnit('PS_OVERLAY', 'PS_OVERLAY');
    LResults.Add(Format('# functions=%d keys=%d,%d,%d texture=%s flat=%s', [GFunctions.Count, GKeys[0], GKeys[1],
      GKeys[2], GTextureName, GFlatName]));
    LResults.Add(Format('# initial state=%.8x', [StateFingerprint]));
    // one step for each function; with -vshtypes a function that has a parameter "typ" has one step for each value
    LPlan := TList<TPair<Integer, Integer>>.Create;
    for LIndex := 0 to GFunctions.Count - 1 do
      if (GTypeValues.Count > 0) and HasTypeParameter(GFunctions[LIndex]) and not IsSkipped(GFunctions[LIndex]) then
        for LValue in GTypeValues do
          LPlan.Add(TPair<Integer, Integer>.Create(LIndex, LValue))
      else
        LPlan.Add(TPair<Integer, Integer>.Create(LIndex, NO_TYPE_VALUE));
    for LStep := 0 to LPlan.Count - 1 do
    begin
      LIndex := LPlan[LStep].Key;
      GTypeArg := 1;
      LSuffix := '';
      if LPlan[LStep].Value <> NO_TYPE_VALUE then
      begin
        GTypeArg := LPlan[LStep].Value;
        LSuffix := Format('[typ=%d]', [GTypeArg]);
      end;
      LFunction := GFunctions[LIndex];
      if LIndex < GFrom then
        Continue;
      if IsSkipped(LFunction) then
      begin
        LResults.Add(Format('%d %s.%s SKIPPED', [LIndex, LFunction.UnitName, LFunction.Name]));
        Continue;
      end;
      LScript := BuildScript(LFunction);
      if LScript = '' then
      begin
        LResults.Add(Format('%d %s.%s NOSCRIPT', [LIndex, LFunction.UnitName, LFunction.Name]));
        Continue;
      end;
      LScripts.Add(Format('// ---- %d %s.%s', [LIndex, LFunction.UnitName, LFunction.Name]));
      LScripts.Add(LScript);
      WriteProgress(Format('%d %s.%s', [LIndex, LFunction.UnitName, LFunction.Name]));
      PS_SetMapStr('vsh_result', '');
      LText := '';
      LOk := False;
      LExec := nil;
      LPCode := '';
      try
        LOk := (GCompiler as TDoomCompiler).CompileDoomScript(TbtString(LScript), LPCode);
        if not LOk then
          LText := 'COMPILE: ' + string(GCompiler.Msg[0].MessageToString);
      except
        on E: Exception do
          LText := 'COMPILE-EXC: ' + E.ClassName;
      end;
      if LOk then
      begin
        try
          LExec := TDoomExec.CreateDoomExec(GImporter);
          try
            SetContext(players[0].mo);
            if LExec.LoadData(LPCode) then
            begin
              if LExec.RunScript then
                LText := 'result=' + PS_GetMapStr('vsh_result')
              else
                LText := 'RUNTIME: ' + string(TIFErrorToString(LExec.ExceptionCode, LExec.ExceptionString));
            end
            else
              LText := 'LOAD-FAILED';
          finally
            SetContext(nil);
            LExec.Free;
          end;
        except
          on E: Exception do
            LText := 'EXCEPTION: ' + E.ClassName;
        end;
      end;
      LResults.Add(Format('%d %s.%s%s %s state=%.8x', [LIndex, LFunction.UnitName, LFunction.Name, LSuffix, LText,
        StateFingerprint]));
    end;
    LResults.SaveToFile('verify_scripthost_L2.txt');
    LScripts.SaveToFile('verify_scripthost_L2_scripts.txt');
  finally
    LScripts.Free;
    LResults.Free;
  end;
end;

// ---- the implicit actor: the two ways that scripts get it ---------------------------------------
// PS_Event* (an event script of the map: the actor of the event is the current actor) and
// PS_DoRunScript (what A_RunScript calls: the actor of the state); both set the implicit actor of
// the functions that take the key 0 and of Actor, and give it back at the end

const
  CTX_EVENTS =
    'uses all;'#13#10 +
    'event OnPlayerEnter(const playerNO: integer);'#13#10 +
    'begin'#13#10 +
    '  SetMapString(''ctx_enter'', IntToStr(Actor) + '','' + IntToStr(GetActorX(0)) + '','' + IntToStr(GetActorY(Actor)) +'#13#10 +
    '    '','' + IntToStr(GetActorHealth(0)) + '','' + IntToStr(playerNO) + '','' + IntToStr(GetActorPlayer(0)));'#13#10 +
    '  SetActorMOMX(0, 1234);'#13#10 +
    '  SetActorX(0, GetActorX(0) + 65536);'#13#10 +
    'end;'#13#10 +
    'event OnActorDied(const actorKEY: LongWord; const killer: LongWord);'#13#10 +
    'begin'#13#10 +
    '  SetMapString(''ctx_died'', IntToStr(Actor) + '','' + IntToStr(actorKEY) + '','' + IntToStr(GetActorHealth(0)) +'#13#10 +
    '    '','' + IntToStr(killer) + '','' + IntToStr(GetActorMobjType(0)));'#13#10 +
    '  SetActorMOMZ(0, 4321);'#13#10 +
    'end;'#13#10 +
    'event OnUseLine(const actorKEY: LongWord; const lineNO: Integer; const side: Integer);'#13#10 +
    'begin'#13#10 +
    '  SetMapString(''ctx_use'', IntToStr(Actor) + '','' + IntToStr(actorKEY) + '','' + IntToStr(lineNO) + '','' + IntToStr(side));'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.'#13#10;

  CTX_RUN =
    'uses all;'#13#10 +
    'var a: LongWord;'#13#10 +
    'begin'#13#10 +
    '  a := Actor;'#13#10 +
    '  SetMapString(''ctx_run'', IntToStr(a) + '','' + IntToStr(GetActorX(0)) + '','' + IntToStr(GetActorZ(a)) +'#13#10 +
    '    '','' + IntToStr(GetActorMobjType(0)) + '','' + IntToStr(GetActorSpawnHealth(0)));'#13#10 +
    '  SetActorMOMY(0, 777);'#13#10 +
    '  SetActorFlag(0, 3);'#13#10 +
    'end.'#13#10;

procedure RunContext;
var
  LResults: TStringList;
  LFirst: Pmobj_t;
  LSecond: Pmobj_t;

  procedure Add(const AName: string);
  begin
    LResults.Add(Format('%s=%s state=%.8x', [AName, PS_GetMapStr(AName), StateFingerprint]));
  end;

begin
  LResults := TStringList.Create;
  try
    FindKeys;
    LFirst := players[0].mo;
    LSecond := mobjlist.FindMobjFromKey(GKeys[1]);
    LResults.Add(Format('# first=%d second=%d initial state=%.8x', [GKeys[0], GKeys[1], StateFingerprint]));
    // the events path
    PS_SetMapStr('ctx_enter', '');
    PS_EventPlayerEnter(0);
    Add('ctx_enter');
    PS_SetMapStr('ctx_died', '');
    PS_EventActorDied(LSecond, LFirst);
    Add('ctx_died');
    PS_SetMapStr('ctx_use', '');
    PS_EventUseLine(LSecond, 0, 1);
    Add('ctx_use');
    // the path of A_RunScript, for two actors
    PS_SetMapStr('ctx_run', '');
    LResults.Add(Format('# run first=%d', [Ord(GRunner(LFirst, 'VSHRUN'))]));
    Add('ctx_run');
    PS_SetMapStr('ctx_run', '');
    LResults.Add(Format('# run second=%d', [Ord(GRunner(LSecond, 'VSHRUN'))]));
    Add('ctx_run');
    // outside of both paths there is no implicit actor
    PS_SetMapStr('ctx_run', '');
    LResults.Add(Format('# run nil=%d', [Ord(GRunner(nil, 'VSHRUN'))]));
    Add('ctx_run');
    LResults.SaveToFile('verify_scripthost_L2_context.txt');
  finally
    LResults.Free;
  end;
end;

// ---- -vsh demo: the state of the first player at the last tick (a -timedemo run) -----------------------

var
  GPadding: Pointer = nil;
  GExitFile: TextFile;
  GDemoLine: string = '';

procedure WriteDemoLine;
var
  LFile: TextFile;
begin
  AssignFile(LFile, 'verify_scripthost_demo.txt');
  Rewrite(LFile);
  Writeln(LFile, GDemoLine);
  CloseFile(LFile);
end;

// one line every 35 tics: the tick and the FNV-1a of the state of the level (to find where two runs part)
procedure WriteTrace(ATick: Integer);
var
  LFile: TextFile;
begin
  AssignFile(LFile, 'verify_scripthost_demo_trace.txt');
  if ATick <= 35 then
    Rewrite(LFile)
  else
    Append(LFile);
  Writeln(LFile, Format('%d %.8x x=%d y=%d z=%d momx=%d momy=%d angle=%d health=%d state=%d cons=%d gt=%d', [ATick, StateFingerprint, players[0].mo.x, players[0].mo.y, players[0].mo.z, players[0].mo.momx, players[0].mo.momy, Integer(players[0].mo.angle), players[0].health, Ord(players[0].playerstate), consoleplayer, gametic]));
  CloseFile(LFile);
end;

procedure VSH_AfterTick(ATick: Integer);
var
  LMobj: Pmobj_t;
begin
  if GMode <> 'demo' then
    Exit;
  LMobj := players[0].mo;
  if LMobj = nil then
    Exit;
  GDemoLine := Format('gametic=%d leveltime=%d x=%d y=%d z=%d angle=%d momx=%d momy=%d health=%d',
    [gametic, leveltime, LMobj.x, LMobj.y, LMobj.z, Integer(LMobj.angle), LMobj.momx, LMobj.momy,
    players[0].health]);
{$IFDEF DOOM}
  GDemoLine := GDemoLine + Format(' kills=%d items=%d secrets=%d', [players[0].killcount,
    players[0].itemcount, players[0].secretcount]);
{$ENDIF}
  if (ATick mod 35 = 0) or (ATick >= 4255) then
    WriteTrace(ATick);
  if ATick mod 700 = 0 then
    WriteDemoLine;
end;

// ---- hooks ----------------------------------------------------------------------------------------

const
  SAVE_SCRIPT =
    'uses all;'#13#10 +
    'var'#13#10 +
    '  gtick: integer;'#13#10 +
    '  gtext: string;'#13#10 +
    '  gsingle: single;'#13#10 +
    '  gdouble: double;'#13#10 +
    '  gext: extended;'#13#10 +
    '  gspawn: LongWord;'#13#10 +
    'event OnMapStart;'#13#10 +
    'begin'#13#10 +
    '  SetMapInteger(''vsh_mi'', 7);'#13#10 +
    '  SetMapString(''vsh_ms'', ''hello'');'#13#10 +
    '  SetMapFloat(''vsh_mf'', 1.5);'#13#10 +
    '  SetWorldInteger(''vsh_wi'', 42);'#13#10 +
    '  SetWorldString(''vsh_ws'', ''world'');'#13#10 +
    '  SetWorldFloat(''vsh_wf'', 2.25);'#13#10 +
    '  gtext := ''start'';'#13#10 +
    '  gsingle := 0.5;'#13#10 +
    '  gdouble := 3.5;'#13#10 +
    '  gext := 1.25;'#13#10 +
    '  // an actor made by the script: it is in the savegame with the others'#13#10 +
    '  gspawn := SpawnActorType(GetActorX(GetPlayerActor(0)) + 4194304, GetActorY(GetPlayerActor(0)), GetActorZ(GetPlayerActor(0)), GetActorMobjType(GetPlayerActor(0)));'#13#10 +
    '  SetActorMOMX(gspawn, 65536);'#13#10 +
    'end;'#13#10 +
    'event OnTick(const tick: Integer);'#13#10 +
    'begin'#13#10 +
    '  gtick := gtick + 1;'#13#10 +
    '  SetMapInteger(''vsh_tick'', gtick);'#13#10 +
    '  if (gtick mod 35) = 0 then'#13#10 +
    '    SetWorldInteger(''vsh_wi'', GetWorldInteger(''vsh_wi'') + 1);'#13#10 +
    'end;'#13#10 +
    'begin'#13#10 +
    'end.'#13#10;

procedure VSH_SetScriptRunner(const ARunner: TVshScriptRunner);
begin
  GRunner := ARunner;
end;

procedure VSH_AfterPSInit(ACompiler: TPSPascalCompiler; AImporter: TPSRuntimeClassImporter);
var
  LName: string;
begin
  GCompiler := ACompiler;
  GImporter := AImporter;
  if GMode = 'save' then
    // the maps that the runs of the savegame comparison load (E1M1, E1M2, MAP01, MAP02)
    for LName in ['E1M1', 'E1M2', 'MAP01', 'MAP02'] do
      PS_AddSourceScript(LName, SAVE_SCRIPT, pst_normal);
  if GMode = 'l2' then
  begin
    // the event script of the map (for PS_Event*) and a normal script (for PS_DoRunScript): see RunContext
    for LName in ['E1M1', 'E1M2', 'MAP01', 'MAP02'] do
      PS_AddSourceScript(LName, CTX_EVENTS, pst_normal);
    PS_AddSourceScript('VSHRUN', CTX_RUN, pst_normal);
  end;
end;

procedure VSH_AfterLevel(const AMapName: string);
begin
  if GMode <> 'l2' then
    Exit;
  RunContext;
  RunBattery;
  Halt(0);
end;

type
  PVshExceptionRecord = ^TVshExceptionRecord;
  TVshExceptionRecord = record
    ExceptionCode: Cardinal;
    ExceptionFlags: Cardinal;
    ExceptionRecord: Pointer;
    ExceptionAddress: Pointer;
    NumberParameters: Cardinal;
    ExceptionInformation: array[0..14] of NativeUInt;
  end;
  PVshExceptionPointers = ^TVshExceptionPointers;
  TVshExceptionPointers = record
    ExceptionRecord: PVshExceptionRecord;
    ContextRecord: Pointer;
  end;

type
  TVshMemoryInfo = record
    BaseAddress: Pointer;
    AllocationBase: Pointer;
    AllocationProtect: Cardinal;
    RegionSize: NativeUInt;
    State: Cardinal;
    Protect: Cardinal;
    MemType: Cardinal;
  end;

function VirtualQuery(AAddress: Pointer; var ABuffer: TVshMemoryInfo; ALength: NativeUInt): NativeUInt; stdcall; external 'kernel32.dll';

function AddVectoredExceptionHandler(AFirst: Cardinal; AHandler: Pointer): Pointer; stdcall; external 'kernel32.dll';

// -vsh demo: every exception that is raised (Delphi or not) goes to a file with its class and message
function VshExceptionHandler(AInfo: PVshExceptionPointers): LongInt; stdcall;
var
  LFile: TextFile;
  LObject: TObject;
  LText: string;
  LMemory: TVshMemoryInfo;
begin
  Result := 0;
  try
    LText := Format('code=%.8x address=%p', [AInfo.ExceptionRecord.ExceptionCode, AInfo.ExceptionRecord.ExceptionAddress]);
    if AInfo.ExceptionRecord.ExceptionCode = $C0000005 then
      LText := LText + Format(' write=%d data=%.8x', [AInfo.ExceptionRecord.ExceptionInformation[0], AInfo.ExceptionRecord.ExceptionInformation[1]]);
    if AInfo.ExceptionRecord.ExceptionCode = $C0000005 then
    begin
      FillChar(LMemory, SizeOf(LMemory), 0);
      VirtualQuery(Pointer(AInfo.ExceptionRecord.ExceptionInformation[1] - 1), LMemory, SizeOf(LMemory));
      LText := LText + Format(' below: base=%p allocbase=%p size=%d state=%.8x type=%.8x', [LMemory.BaseAddress, LMemory.AllocationBase, LMemory.RegionSize, LMemory.State, LMemory.MemType]);
      FillChar(LMemory, SizeOf(LMemory), 0);
      VirtualQuery(Pointer(AInfo.ExceptionRecord.ExceptionInformation[1]), LMemory, SizeOf(LMemory));
      LText := LText + Format(' at: base=%p state=%.8x', [LMemory.BaseAddress, LMemory.State]);
    end;
    if AInfo.ExceptionRecord.ExceptionCode = $0EEDFADE then
    begin
      LObject := TObject(AInfo.ExceptionRecord.ExceptionInformation[1]);
      LText := LText + ' ' + LObject.ClassName;
      if LObject is Exception then
        LText := LText + ': ' + Exception(LObject).Message;
    end;
    AssignFile(LFile, 'verify_scripthost_demo_exceptions.txt');
    if FileExists('verify_scripthost_demo_exceptions.txt') then
      Append(LFile)
    else
      Rewrite(LFile);
    Writeln(LFile, LText);
    CloseFile(LFile);
  except
  end;
end;

procedure Initialize;
var
  LIndex: Integer;
  LValue: string;
begin
  GTypeValues := TList<Integer>.Create;
  for LIndex := 1 to ParamCount do
  begin
    if SameText(ParamStr(LIndex), '-vsh') and (LIndex < ParamCount) then
      GMode := LowerCase(ParamStr(LIndex + 1))
    else if SameText(ParamStr(LIndex), '-vshskip') and (LIndex < ParamCount) then
      GSkip := GSkip + UpperCase(ParamStr(LIndex + 1)) + ','
    else if SameText(ParamStr(LIndex), '-vshfrom') and (LIndex < ParamCount) then
      GFrom := StrToIntDef(ParamStr(LIndex + 1), 0)
    else if SameText(ParamStr(LIndex), '-vshtypes') and (LIndex < ParamCount) then
    begin
      for LValue in ParamStr(LIndex + 1).Split([',']) do
        GTypeValues.Add(StrToIntDef(LValue, 0));
    end
    else if SameText(ParamStr(LIndex), '-vshonly') and (LIndex < ParamCount) then
      GOnly := ParamStr(LIndex + 1)
    else if SameText(ParamStr(LIndex), '-vshpad') and (LIndex < ParamCount) then
    begin
      // -vshpad N: N KB of memory taken at the start (it moves what is allocated after it: for the runs of -vsh demo,
      // where a read past the end of a block of the renderer depends on the layout of the memory)
      GetMem(GPadding, StrToIntDef(ParamStr(LIndex + 1), 0) * 1024);
    end;
  end;
  if GMode = 'demo' then
    AddVectoredExceptionHandler(1, @VshExceptionHandler);
end;

initialization
  Initialize;

finalization
  if GMode = 'demo' then
  begin
    AssignFile(GExitFile, 'verify_scripthost_demo_exit.txt');
    Rewrite(GExitFile);
    Writeln(GExitFile, 'ExitCode=' + IntToStr(ExitCode));
    if ExceptObject <> nil then
      Writeln(GExitFile, TObject(ExceptObject).ClassName);
    CloseFile(GExitFile);
  end;
  if (GMode = 'demo') and (GDemoLine <> '') then
    WriteDemoLine;

end.
