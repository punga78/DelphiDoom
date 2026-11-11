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
  System.Diagnostics,
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
  p_setup,
  doomdef,
  d_net,
  i_system,
  v_data,
  v_video,
  {$IFNDEF OPENGL}
  r_hires,
  {$ENDIF}
  psi_overlay;

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

  /// a member (property or method) of a class that scripts see (Actors, Lines, MapStrings...), as the compiler has it
  TVshMember = record
    ClassName: string;
    Name: string;
    IsProperty: Boolean;
    Writable: Boolean;
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
  GMembers: TList<TVshMember> = nil;
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

// the properties and methods of the classes of the scripts (the ones with a "!" in the name), read inside the OnUses
// callback: the compiler frees its tables after Compile
procedure CaptureClasses(ACompiler: TPSPascalCompiler);
var
  LType: Integer;
  LItem: Integer;
  LParam: Integer;
  LClassType: TPSClassType;
  LClassItem: TPSDelphiClassItem;
  LMember: TVshMember;
begin
  if (GMembers = nil) or (GMembers.Count > 0) then
    Exit;
  for LType := 0 to ACompiler.GetTypeCount - 1 do
  begin
    if not (ACompiler.GetType(LType) is TPSClassType) then
      Continue;
    LClassType := TPSClassType(ACompiler.GetType(LType));
    if (LClassType.Cl = nil) or (Copy(string(LClassType.Cl.RTLClassName), 1, 1) <> '!') then
      Continue;
    for LItem := 0 to LClassType.Cl.Count - 1 do
    begin
      LClassItem := LClassType.Cl.Items[LItem];
      if not ((LClassItem is TPSDelphiClassItemProperty) or (LClassItem is TPSDelphiClassItemMethod)) then
        Continue;
      if LClassItem.Decl = nil then
        Continue;
      LMember.ClassName := UpperCase(string(LClassType.Cl.RTLClassName));
      LMember.Name := string(LClassItem.OrgName);
      LMember.IsProperty := LClassItem is TPSDelphiClassItemProperty;
      LMember.Writable := LMember.IsProperty and (TPSDelphiClassItemProperty(LClassItem).AccessType in [iptRW, iptW]);
      SetLength(LMember.Parameters, LClassItem.Decl.ParamCount);
      for LParam := 0 to LClassItem.Decl.ParamCount - 1 do
        LMember.Parameters[LParam] := ParameterOf(LClassItem.Decl, LParam);
      LMember.HasResult := LClassItem.Decl.Result <> nil;
      LMember.ResultTypeName := '';
      LMember.ResultBase := 0;
      LMember.ResultElement := 0;
      if LMember.HasResult then
      begin
        LMember.ResultTypeName := string(LClassItem.Decl.Result.Name);
        LMember.ResultBase := Byte(LClassItem.Decl.Result.BaseType);
        if LClassItem.Decl.Result is TPSArrayType then
          if TPSArrayType(LClassItem.Decl.Result).ArrayTypeNo <> nil then
            LMember.ResultElement := Byte(TPSArrayType(LClassItem.Decl.Result).ArrayTypeNo.BaseType);
      end;
      GMembers.Add(LMember);
    end;
  end;
end;

function CaptureOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  LFrom: Integer;
  LIndex: Integer;
begin
  LFrom := Sender.GetRegProcCount;
  Result := PS_ScriptOnUses(Sender, Name);
  if (string(Name) = 'SYSTEM') and (GCaptureUnit = 'SYSTEM') then
    CaptureClasses(Sender);
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

// ---- the properties of the classes of the scripts (fetta 2g) --------------------------------------------
// one script for every property and method: it reads the property, writes it back (changed, when that is safe) and reads
// it again; the result and the FNV-1a of the state are written for each

function InstanceOf(const AClassName: string): string;
begin
  if AClassName = '!TACTOR' then
    Result := 'Actors[' + IntToStr(GKeys[0]) + ']'
  else if AClassName = '!TVERTEX' then
    Result := 'Vertexes[1]'
  else if AClassName = '!TSIDE' then
    Result := 'Sides[1]'
  else if AClassName = '!TLINE' then
    Result := 'Lines[1]'
  else if AClassName = '!TSECTOR' then
    Result := 'Sectors[1]'
  else if AClassName = '!TMOBJINFOITEM' then
    Result := 'MobjInfo[3]'
  else if AClassName = '!TOVERLAY' then
    Result := 'Overlay'
  else if (AClassName = '!TACTORS') or (AClassName = '!TVERTEXES') or (AClassName = '!TSIDES') or
    (AClassName = '!TLINES') or (AClassName = '!TSECTORS') or (AClassName = '!TMOBJINFO') or
    (AClassName = '!TMAPSTRINGS') or (AClassName = '!TWORLDSTRINGS') or (AClassName = '!TMAPINTEGERS') or
    (AClassName = '!TWORLDINTEGERS') or (AClassName = '!TMAPFLOATS') or (AClassName = '!TWORLDFLOATS') then
  begin
    // the variable of the script that has the class: Actors, Vertexes, ..., MapStrings...
    Result := Copy(AClassName, 3, MaxInt);
    if AClassName = '!TVERTEXES' then Result := 'Vertexes';
    if AClassName = '!TSIDES' then Result := 'Sides';
    if AClassName = '!TLINES' then Result := 'Lines';
    if AClassName = '!TSECTORS' then Result := 'Sectors';
    if AClassName = '!TMOBJINFO' then Result := 'MobjInfo';
    if AClassName = '!TACTORS' then Result := 'Actors';
  end
  else
    Result := '';
end;

function IsVariableClass(const AClassName: string): Boolean;
begin
  Result := (AClassName = '!TMAPSTRINGS') or (AClassName = '!TWORLDSTRINGS') or (AClassName = '!TMAPINTEGERS') or
    (AClassName = '!TWORLDINTEGERS') or (AClassName = '!TMAPFLOATS') or (AClassName = '!TWORLDFLOATS');
end;

// '' if no script can be made for the member
function BuildMemberScript(const AMember: TVshMember): string;
var
  LInstance: string;
  LTarget: string;
  LArguments: string;
  LLiteral: string;
  LIndex: Integer;
  LRead: string;
  LStringOf: string;
  LNewValue: string;
  LDeclared: string;
  LIsClass: Boolean;
  LIdName: string;
begin
  Result := '';
  LInstance := InstanceOf(AMember.ClassName);
  if LInstance = '' then
    Exit;
  LArguments := '';
  for LIndex := 0 to Length(AMember.Parameters) - 1 do
  begin
    LLiteral := ArgumentLiteral(AMember.Parameters[LIndex]);
    if LLiteral = '' then
      Exit;
    if LIndex > 0 then
      LArguments := LArguments + ', ';
    LArguments := LArguments + LLiteral;
  end;
  if AMember.IsProperty then
  begin
    LTarget := LInstance + '.' + AMember.Name;
    if LArguments <> '' then
      LTarget := LTarget + '[' + LArguments + ']';
  end
  else
  begin
    LTarget := LInstance + '.' + AMember.Name;
    if LArguments <> '' then
      LTarget := LTarget + '(' + LArguments + ')';
  end;
  LIsClass := AMember.ResultBase = btClass;
  LIdName := 'ID';
  if AMember.ResultTypeName = '!TACTOR' then
    LIdName := 'key';
  LDeclared := AMember.ResultTypeName;
  if (LDeclared <> '') and (LDeclared[1] = '!') then
    LDeclared := Copy(LDeclared, 2, MaxInt);
  if not AMember.HasResult then
  begin
    Result := 'uses all;'#13#10'begin'#13#10'  ' + LTarget + ';'#13#10'  SetMapString(''vsh_result'', ''void'');'#13#10'end.'#13#10;
    Exit;
  end;
  if LIsClass then
  begin
    // the classes of the scripts have a name with ! : a script cannot declare a variable of the type, it chains
    Result := 'uses all;'#13#10'var'#13#10'  vshs: string;'#13#10'begin'#13#10'  vshs := IntToStr(' + LTarget + '.' + LIdName +
      ');'#13#10'  SetMapString(''vsh_result'', vshs);'#13#10'end.'#13#10;
    Exit;
  end;
  if AMember.ResultTypeName = 'BOOLEAN' then
    LStringOf := 'IFS(vshr, ''T'', ''F'')'
  else if IsIntegerBase(AMember.ResultBase) or (AMember.ResultBase = btEnum) then
    LStringOf := 'IntToStr(vshr)'
  else if IsFloatBase(AMember.ResultBase) then
    LStringOf := 'FloatToStr(vshr)'
  else if IsStringBase(AMember.ResultBase) then
    LStringOf := 'vshr'
  else if AMember.ResultBase = btArray then
    LStringOf := 'IntToStr(GetArrayLength(vshr))'
  else
    Exit;
  LRead := '  vshr := ' + LTarget + ';'#13#10'  vshs := ' + LStringOf + ';'#13#10;
  if AMember.IsProperty and AMember.Writable and not LIsClass and (AMember.ResultBase <> btArray) and
     (UpperCase(AMember.Name) <> 'STATE') then
  begin
    if AMember.ResultTypeName = 'BOOLEAN' then
      LNewValue := 'not vshr'
    else if IsIntegerBase(AMember.ResultBase) then
      LNewValue := 'vshr + 1'
    else if IsFloatBase(AMember.ResultBase) then
      LNewValue := 'vshr + 1.5'
    else if IsVariableClass(AMember.ClassName) then
      LNewValue := 'vshr + ''x'''
    else
      // a name of a texture or a flat that does not exist is an error of the engine: the same text is written back
      LNewValue := 'vshr';
    LRead := LRead + '  ' + LTarget + ' := ' + LNewValue + ';'#13#10'  vshr := ' + LTarget + ';'#13#10 +
      '  vshs := vshs + '','' + ' + LStringOf + ';'#13#10;
  end;
  Result := 'uses all;'#13#10'var'#13#10'  vshr: ' + LDeclared + ';'#13#10'  vshs: string;'#13#10'begin'#13#10 + LRead +
    '  SetMapString(''vsh_result'', vshs);'#13#10'end.'#13#10;
end;

procedure RunProperties(AResults, AScripts: TStringList);
var
  LIndex: Integer;
  LMember: TVshMember;
  LName: string;
  LScript: string;
  LPCode: TbtString;
  LExec: TDoomExec;
  LText: string;
  LOk: Boolean;
begin
  AResults.Add(Format('# members=%d', [GMembers.Count]));
  for LIndex := 0 to GMembers.Count - 1 do
  begin
    LMember := GMembers[LIndex];
    LName := Copy(LMember.ClassName, 2, MaxInt) + '_' + LMember.Name;
    if ContainsText(GSkip, ',' + LName + ',') or ContainsText(GSkip, ',' + LMember.Name + ',') then
    begin
      AResults.Add(Format('%d PROP.%s SKIPPED', [LIndex, LName]));
      Continue;
    end;
    if (GOnly <> '') and not ContainsText(LName, GOnly) then
      Continue;
    // PlaySound makes noise and Remove takes the actor out of the level: the others do not
    if SameText(LMember.Name, 'PlaySound') or SameText(LMember.Name, 'Remove') or SameText(LMember.Name, 'Free') or
       SameText(LMember.Name, 'Create') then
    begin
      AResults.Add(Format('%d PROP.%s SKIPPED', [LIndex, LName]));
      Continue;
    end;
    LScript := BuildMemberScript(LMember);
    if LScript = '' then
    begin
      AResults.Add(Format('%d PROP.%s NOSCRIPT', [LIndex, LName]));
      Continue;
    end;
    AScripts.Add(Format('// ---- %d PROP.%s', [LIndex, LName]));
    AScripts.Add(LScript);
    WriteProgress(Format('%d PROP.%s', [LIndex, LName]));
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
    AResults.Add(Format('%d PROP.%s %s state=%.8x', [LIndex, LName, LText, StateFingerprint]));
  end;
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
  LPropResults: TStringList;
  LPropScripts: TStringList;
begin
  LResults := TStringList.Create;
  LScripts := TStringList.Create;
  try
    FindKeys;
    FindNames;
    GFunctions := TList<TVshFunction>.Create;
    GMembers := TList<TVshMember>.Create;
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
    // the properties of the classes of the scripts: before the result file of the functions is written, so that a run
    // that dies in one of them has no result file (Confronta.ps1 then skips it and runs again)
    LPropResults := TStringList.Create;
    LPropScripts := TStringList.Create;
    try
      RunProperties(LPropResults, LPropScripts);
      LPropResults.SaveToFile('verify_scripthost_L2_props.txt');
      LPropScripts.SaveToFile('verify_scripthost_L2_props_scripts.txt');
    finally
      LPropScripts.Free;
      LPropResults.Free;
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
  if GMode = 'shot' then
  begin
    // -vsh shot: a screenshot at tic 70 (taken by the next G_Ticker), then the end
    if ATick = 70 then
      G_ScreenShot;
    if ATick = 80 then
      Halt(0);
    Exit;
  end;
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
    '  // drawers of the overlay that stay alive: they are in the savegame too (fetta 2i)'#13#10 +
    '  OverlayDrawText(100000, ''Overlay in the savegame'', 0, 10, 10);'#13#10 +
    '  OverlayDrawRect(100000, 255, 0, 0, 20, 40, 60, 60);'#13#10 +
    '  OverlayDrawLine(100000, 0, 255, 0, 10, 80, 200, 120);'#13#10 +
    '  OverlayDrawPixel(100000, 0, 0, 255, 100, 100);'#13#10 +
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

function OvrPatchName: string; forward;

// -vsh shot: the script that draws on the overlay (text, rectangle, line, pixel, patches) for the screenshot
function ShotScript: string;
var
  LPatch: string;
begin
  Result :=
    'uses all;'#13#10 +
    'event OnMapStart;'#13#10 +
    'begin'#13#10 +
    '  OverlayDrawText(100000, ''Overlay screenshot test 0123'', 0, 10, 10);'#13#10 +
    '  OverlayDrawCenterText(100000, ''centered text'', 160, 30);'#13#10 +
    '  OverlayDrawRightText(100000, ''right text'', 310, 50);'#13#10 +
    '  OverlayDrawRect(100000, 255, 0, 0, 20, 70, 60, 90);'#13#10 +
    '  OverlayDrawLine(100000, 0, 255, 0, 10, 100, 200, 140);'#13#10 +
    '  OverlayDrawPixel(100000, 0, 0, 255, 100, 100);'#13#10;
  LPatch := OvrPatchName;
  if LPatch <> '' then
    Result := Result +
      '  OverlayDrawPatch(100000, ''' + LPatch + ''', 200, 100);'#13#10 +
      '  OverlayDrawPatchStretched(100000, ''' + LPatch + ''', 240, 10, 300, 70);'#13#10;
  Result := Result + 'end;'#13#10 + 'begin'#13#10 + 'end.'#13#10;
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
  if GMode = 'shot' then
    for LName in ['E1M1', 'E1M2', 'MAP01', 'MAP02'] do
      PS_AddSourceScript(LName, ShotScript, pst_normal);
  if GMode = 'l2' then
  begin
    // the event script of the map (for PS_Event*) and a normal script (for PS_DoRunScript): see RunContext
    for LName in ['E1M1', 'E1M2', 'MAP01', 'MAP02'] do
      PS_AddSourceScript(LName, CTX_EVENTS, pst_normal);
    PS_AddSourceScript('VSHRUN', CTX_RUN, pst_normal);
  end;
end;

// ---- -vsh overlay (fetta 2i): the bytes of the overlay, of the record that a savegame stores and of the frame -----

var
  GOverlayLines: TStringList = nil;

procedure OvrLine(const AText: string);
begin
  GOverlayLines.Add(AText);
end;

procedure OvrHashBytes(const AName: string; const ABytes: PByte; ACount: Integer);
var
  LIndex: Integer;
begin
  FnvReset;
  for LIndex := 0 to ACount - 1 do
    FnvByte((ABytes + LIndex)^);
  OvrLine(Format('%s bytes=%d fnv=%.8x', [AName, ACount, GFnv]));
end;

// the fields of a drawer that its kind uses (the others were never written by the old class: garbage in memory)
procedure OvrHashSave(const AName: string);
var
  LBuffer: Pointer;
  LCursor: Pointer;
  LCount, LIndex, LKind, LPos: Integer;
  LRecord: PByte;
  LLength: Integer;
  function Int(AOffset: Integer): Integer;
  begin
    Result := PInteger(LRecord + AOffset)^;
  end;
begin
  GetMem(LBuffer, overlay.SaveSize);
  try
    LCursor := LBuffer;
    overlay.SaveToBuffer(LCursor);
    LCount := PInteger(LBuffer)^;
    FnvReset;
    FnvInt(LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      LRecord := PByte(LBuffer) + 4 + LIndex * 292;
      LKind := Int(0);
      FnvInt(LKind);
      FnvInt(Int(4));
      FnvInt(Int(264));
      FnvInt(Int(268));
      case LKind of
        1:
          begin
            LLength := LRecord[8];
            for LPos := 8 to 8 + LLength do
              FnvByte(LRecord[LPos]);
            FnvInt(Int(272));
          end;
        2, 6:
          begin
            LLength := LRecord[8];
            for LPos := 8 to 8 + LLength do
              FnvByte(LRecord[LPos]);
            FnvInt(Int(272));
            FnvInt(Int(284));
            FnvInt(Int(288));
          end;
        3:
          begin
            FnvInt(Int(272));
            FnvInt(Int(276));
            FnvInt(Int(280));
          end;
        4, 5:
          begin
            FnvInt(Int(272));
            FnvInt(Int(276));
            FnvInt(Int(280));
            FnvInt(Int(284));
            FnvInt(Int(288));
          end;
      end;
    end;
    OvrLine(Format('%s saved=%d (%d bytes) fnv=%.8x', [AName, LCount, overlay.SaveSize, GFnv]));
  finally
    FreeMem(LBuffer);
  end;
end;

procedure OvrFlash(const AName: string);
var
  LWidth, LHeight, LIndex: Integer;
  LThreaded: Integer;
  LOldThreads: Boolean;
{$IFNDEF OPENGL}
  LOldMode: videomode_t;
{$ENDIF}
  procedure Fill;
  var
    LPixel: Integer;
  begin
    for LPixel := 0 to LWidth * LHeight - 1 do
    begin
      screens[SCN_FG][LPixel] := Byte(LPixel * 7 + 3);
      screen32[LPixel] := LongWord(LPixel) * 2654435761 + 17;
    end;
  end;
begin
  LWidth := V_GetScreenWidth(SCN_FG);
  LHeight := V_GetScreenHeight(SCN_FG);
  LOldThreads := usemultithread;
  try
    for LThreaded := 0 to 1 do
    begin
      usemultithread := LThreaded = 1;
{$IFNDEF OPENGL}
      LOldMode := videomode;
      try
        videomode := vm8bit;
        Fill;
        OVR_Drawer;
        OvrHashBytes(Format('%s flash8 %dx%d threads=%d', [AName, LWidth, LHeight, LThreaded]),
          PByte(screens[SCN_FG]), LWidth * LHeight);
        videomode := vm32bit;
        Fill;
        OVR_Drawer;
        OvrHashBytes(Format('%s flash32 %dx%d threads=%d', [AName, LWidth, LHeight, LThreaded]),
          PByte(screen32), LWidth * LHeight * 4);
      finally
        videomode := LOldMode;
      end;
{$ELSE}
      Fill;
      OVR_Drawer;
      OvrHashBytes(Format('%s flash32 %dx%d threads=%d', [AName, LWidth, LHeight, LThreaded]),
        PByte(screen32), LWidth * LHeight * 4);
{$ENDIF}
    end;
  finally
    usemultithread := LOldThreads;
  end;
  LIndex := 0;
end;

procedure OvrStep(const AName: string);
begin
  overlay.DrawDrawers;
  OvrHashBytes(AName + ' screen', PByte(overlay.overlayscreen), 64000);
  OvrHashSave(AName);
  OvrFlash(AName);
end;

function OvrPatchName: string;
var
  LName: string;
  LLump: Integer;
begin
  Result := '';
  // the first sprite or patch with some pixels (the lumps of that type are the ones AddPatch finds)
  for LLump := 0 to W_NumLumps - 1 do
  begin
    LName := char8tostring(W_GetNameForNum(LLump));
    if (W_LumpLength(LLump) > 400) and (W_LumpLength(LLump) < 3000) and
       (W_CheckNumForName(LName, TYPE_PATCH or TYPE_SPRITE) = LLump) then
    begin
      Result := LName;
      Exit;
    end;
  end;
end;

// the time of the overlay per frame (verify_scripthost_overlay_bench.txt, in milliseconds for 300 repetitions): drawing
// the drawers into the buffer, and flashing it over the screen in 32 and 8 bits, with and without threads
procedure RunOverlayBench(const ALines: TStringList; const APatch: string);
const
  REPETITIONS = 300;
var
  LWatch: TStopwatch;
  LIndex: Integer;
  LThreaded: Integer;
  LOldThreads: Boolean;
{$IFNDEF OPENGL}
  LOldMode: videomode_t;
{$ENDIF}
begin
  overlay.Clear;
  for LIndex := 0 to 9 do
    overlay.AddText(100000, 'Benchmark text of the overlay 0123456789', 0, 4, 4 + LIndex * 18);
  overlay.AddRect(100000, 255, 0, 0, 20, 20, 300, 180);
  for LIndex := 0 to 4 do
    overlay.AddLine(100000, 0, 255, 0, 10, 10 + LIndex * 30, 300, 190 - LIndex * 20);
  if APatch <> '' then
  begin
    overlay.AddPatch(100000, APatch, 100, 100);
    overlay.AddPatchStretched(100000, APatch, 10, 10, 200, 150);
  end;
  firstinterpolation := True;
  LWatch := TStopwatch.StartNew;
  for LIndex := 1 to REPETITIONS do
    overlay.DrawDrawers;
  ALines.Add(Format('drawdrawers x%d: %d ms', [REPETITIONS, LWatch.ElapsedMilliseconds]));
  // the drawers are drawn: the frames only flash (the tic is not a new one)
  firstinterpolation := False;
  overlay.DrawDrawers;
  LOldThreads := usemultithread;
  try
    for LThreaded := 0 to 1 do
    begin
      usemultithread := LThreaded = 1;
{$IFNDEF OPENGL}
      LOldMode := videomode;
      try
        videomode := vm32bit;
        LWatch := TStopwatch.StartNew;
        for LIndex := 1 to REPETITIONS do
          OVR_Drawer;
        ALines.Add(Format('flash32 threads=%d x%d: %d ms', [LThreaded, REPETITIONS, LWatch.ElapsedMilliseconds]));
        videomode := vm8bit;
        LWatch := TStopwatch.StartNew;
        for LIndex := 1 to REPETITIONS do
          OVR_Drawer;
        ALines.Add(Format('flash8 threads=%d x%d: %d ms', [LThreaded, REPETITIONS, LWatch.ElapsedMilliseconds]));
      finally
        videomode := LOldMode;
      end;
{$ELSE}
      LWatch := TStopwatch.StartNew;
      for LIndex := 1 to REPETITIONS do
        OVR_Drawer;
      ALines.Add(Format('flash32 threads=%d x%d: %d ms', [LThreaded, REPETITIONS, LWatch.ElapsedMilliseconds]));
{$ENDIF}
    end;
  finally
    usemultithread := LOldThreads;
  end;
  overlay.Clear;
end;

procedure RunOverlay;
var
  LPatch: string;
  LBuffer: Pointer;
  LCursor: Pointer;
  LSaved: Integer;
begin
  GOverlayLines := TStringList.Create;
  try
    gamestate := GS_LEVEL;
    firstinterpolation := True;
    LPatch := OvrPatchName;
    OvrLine('screen ' + IntToStr(V_GetScreenWidth(SCN_FG)) + 'x' + IntToStr(V_GetScreenHeight(SCN_FG)) +
      ' patch=' + LPatch);
    overlay.Clear;
    OvrStep('empty');

    // 0 is OVR_ALIGN_LEFT (the constants moved from psi_overlay to the library in the new tree)
    overlay.AddText(1000, 'Hello World 123', 0, 10, 10);
    overlay.AddRightText(1000, 'right ~ text [x]', 310, 30);
    overlay.AddCenterText(1000, 'Centered', 160, 50);
    overlay.AddText(1000, 'lowercase and symbols !?:;', 0, 5, 70);
    OvrStep('text');

    if LPatch <> '' then
    begin
      overlay.AddPatch(1000, LPatch, 100, 100);
      overlay.AddPatch(1000, LPatch, -5, 190);
      overlay.AddPatch(1000, LPatch, 315, -10);
      OvrStep('patch');
      overlay.AddPatchStretched(1000, LPatch, 20, 20, 120, 90);
      overlay.AddPatchStretched(1000, LPatch, 200, 150, 150, 100);
      overlay.AddPatchStretched(1000, LPatch, 10, 150, 60, 190);
      OvrStep('stretched');
    end;

    overlay.AddPixel(1000, 255, 0, 0, 5, 5);
    overlay.AddPixel(1000, 0, 255, 0, 319, 199);
    overlay.AddPixel(1000, 0, 0, 255, 400, 10);
    overlay.AddPixel(1000, 255, 255, 255, -1, -1);
    OvrStep('pixel');
    overlay.AddRect(1000, 255, 0, 0, 10, 100, 60, 130);
    overlay.AddRect(1000, 0, 255, 0, -10, -10, 30, 20);
    overlay.AddRect(1000, 0, 0, 255, 300, 150, 250, 160);
    OvrStep('rect');
    overlay.AddLine(1000, 255, 255, 0, 10, 10, 200, 10);
    overlay.AddLine(1000, 255, 0, 255, 50, 20, 50, 190);
    overlay.AddLine(1000, 0, 255, 255, 10, 10, 250, 120);
    overlay.AddLine(1000, 200, 100, 50, 30, 190, 280, 40);
    overlay.AddLine(1000, 100, 200, 50, 100, 20, 120, 180);
    overlay.AddLine(1000, 50, 100, 200, 300, 100, 400, 150);
    overlay.AddLine(1000, 90, 90, 90, 200, 50, 20, 60);
    OvrStep('line');

    // short drawers that expire, a record round trip
    overlay.AddText(5, 'short', 0, 150, 150);
    overlay.AddRect(0, 255, 0, 0, 1, 1, 8, 8);
    OvrStep('short');
    GetMem(LBuffer, overlay.SaveSize);
    try
      LSaved := overlay.SaveSize;
      LCursor := LBuffer;
      overlay.SaveToBuffer(LCursor);
      OvrLine(Format('save consumed=%d', [PByte(LCursor) - PByte(LBuffer)]));
      overlay.Clear;
      OvrStep('cleared');
      LCursor := LBuffer;
      overlay.LoadFromBuffer(LCursor);
      OvrLine(Format('load consumed=%d size=%d', [PByte(LCursor) - PByte(LBuffer), LSaved]));
    finally
      FreeMem(LBuffer);
    end;
    OvrStep('loaded');
    // the drawers that are over disappear
    leveltime := leveltime + 6;
    OvrStep('expired');
    leveltime := leveltime + 2000;
    OvrStep('allexpired');
    GOverlayLines.SaveToFile('verify_scripthost_overlay.txt');
    GOverlayLines.Clear;
    RunOverlayBench(GOverlayLines, LPatch);
    GOverlayLines.SaveToFile('verify_scripthost_overlay_bench.txt');
  finally
    FreeAndNil(GOverlayLines);
  end;
end;

procedure VSH_AfterLevel(const AMapName: string);
begin
  if GMode = 'overlay' then
  begin
    RunOverlay;
    Halt(0);
  end;
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
