{******************************************************************************}
{                                                                              }
{  TEMPORARY HARNESS of issue #173 (never part of the engine projects):        }
{  writes, as text, everything that a script can see of the host: the          }
{  declarations of every unit (verbatim), and the "compile surface" of a       }
{  compiler (registered functions with their parameters, types, the members    }
{  of every class, constants).                                                 }
{                                                                              }
{  It compiles in the old tree (919a19ef) and in the new one: the verbatim     }
{  declarations come from PS_ImportUnits/TProcedureList in the old code and    }
{  from PS_ScriptRegistry in the new one (IF DECLARED).                        }
{  Used by VshDump_<Game> (a console program, no game is started) which        }
{  produces Tests\Data\ScriptHost\<Game>.registration.golden.txt.              }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
{$Q-}
{$R-}
unit ScriptHostDump;

interface

uses
  Classes,
  ps_compiler,
  ps_import;

/// Writes the registration dump of the game of the build to AFileName
procedure VSH_WriteRegistrationDump(const AFileName: string);

implementation

uses
  SysUtils,
{$IF NOT DECLARED(PS_ScriptRegistry)}
  ps_proclist,
{$IFEND}
  ps_defs,
  ps_utils;

const
  UNIT_ORDER: array[0..2] of string = ('PS_FIXED', 'PS_GAME', 'PS_OVERLAY');

function ModeName(AMode: TPSParameterMode): string;
begin
  case AMode of
    pmIn: Result := 'in';
    pmOut: Result := 'out';
    pmInOut: Result := 'var';
  else
    Result := '?';
  end;
end;

function TypeName(AType: TPSType): string;
begin
  if AType = nil then
    Result := '-'
  else
    Result := string(AType.Name);
end;

function ParamsText(ADecl: TPSParametersDecl): string;
var
  LIndex: Integer;
begin
  Result := '';
  if ADecl = nil then
    Exit;
  for LIndex := 0 to ADecl.ParamCount - 1 do
  begin
    if LIndex > 0 then
      Result := Result + '; ';
    Result := Result + ModeName(ADecl.Params[LIndex].Mode) + ' ' + string(ADecl.Params[LIndex].Name) +
      ': ' + TypeName(ADecl.Params[LIndex].aType);
  end;
  Result := '(' + Result + ') -> ' + TypeName(ADecl.Result);
end;

function HexOf(const AText: TbtString): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    Result := Result + IntToHex(Ord(AText[LIndex]), 2);
end;

function ConstantText(AConstant: TPSConstant): string;
var
  LValue: PIfRVariant;
begin
  LValue := AConstant.Value;
  if (LValue = nil) or (LValue.FType = nil) then
    Exit('nil');
  case LValue.FType.BaseType of
    btU8: Result := IntToStr(LValue.tu8);
    btS8: Result := IntToStr(LValue.ts8);
    btU16: Result := IntToStr(LValue.tu16);
    btS16: Result := IntToStr(LValue.ts16);
    btU32: Result := IntToStr(LValue.tu32);
    btS32: Result := IntToStr(LValue.ts32);
    btS64: Result := IntToStr(LValue.ts64);
    btSingle: Result := SysUtils.FloatToStr(LValue.tsingle, TFormatSettings.Invariant);
    btDouble: Result := SysUtils.FloatToStr(LValue.tdouble, TFormatSettings.Invariant);
    btExtended: Result := SysUtils.FloatToStr(LValue.textended, TFormatSettings.Invariant);
    btString: Result := '''' + string(TbtString(LValue.tstring)) + '''';
    btChar: Result := '#' + IntToStr(Ord(LValue.tchar));
  else
    Result := '<base ' + IntToStr(Ord(LValue.FType.BaseType)) + '>';
  end;
end;

procedure DumpClass(ALines: TStrings; AType: TPSClassType);
var
  LIndex: Integer;
  LItem: TPSDelphiClassItem;
  LKind: string;
begin
  if AType.Cl = nil then
    Exit;
  for LIndex := 0 to AType.Cl.Count - 1 do
  begin
    LItem := AType.Cl.Items[LIndex];
    if LItem is TPSDelphiClassItemConstructor then
      LKind := 'ctor'
    else if LItem is TPSDelphiClassItemMethod then
      LKind := 'method'
    else if LItem is TPSDelphiClassItemProperty then
    begin
      case TPSDelphiClassItemProperty(LItem).AccessType of
        iptRW: LKind := 'property rw';
        iptR: LKind := 'property r';
        iptW: LKind := 'property w';
      else
        LKind := 'property ?';
      end;
    end
    else
      LKind := 'item';
    ALines.Add(Format('    member %s.%s [%s] %s decl="%s"', [string(AType.Cl.RTLClassName), string(LItem.OrgName),
      LKind, ParamsText(LItem.Decl), string(LItem.RTLDeclaration)]));
  end;
end;

procedure DumpTypes(ALines: TStrings; ACompiler: TPSPascalCompiler; AFrom: Integer);
var
  LIndex: Integer;
  LType: TPSType;
  LRecord: Integer;
  LText: string;
begin
  ALines.Add(Format('  types total=%d new=%d', [ACompiler.GetTypeCount, ACompiler.GetTypeCount - AFrom]));
  for LIndex := AFrom to ACompiler.GetTypeCount - 1 do
  begin
    LType := ACompiler.GetType(LIndex);
    LText := Format('  type %d %s base=%d', [LIndex, string(LType.Name), Ord(LType.BaseType)]);
    if LType is TPSArrayType then
      LText := LText + ' of ' + TypeName(TPSArrayType(LType).ArrayTypeNo);
    if LType is TPSProceduralType then
      LText := LText + ' ' + ParamsText(TPSProceduralType(LType).ProcDef);
    ALines.Add(LText);
    if LType is TPSRecordType then
      for LRecord := 0 to TPSRecordType(LType).RecValCount - 1 do
        ALines.Add(Format('    field %s: %s', [string(TPSRecordType(LType).RecVal(LRecord).FieldOrgName),
          TypeName(TPSRecordType(LType).RecVal(LRecord).aType)]));
    if LType is TPSClassType then
      DumpClass(ALines, TPSClassType(LType));
  end;
end;

procedure DumpProcedures(ALines: TStrings; ACompiler: TPSPascalCompiler; AFrom: Integer);
var
  LIndex: Integer;
  LProc: TPSRegProc;
begin
  ALines.Add(Format('  functions total=%d new=%d', [ACompiler.GetRegProcCount, ACompiler.GetRegProcCount - AFrom]));
  for LIndex := AFrom to ACompiler.GetRegProcCount - 1 do
  begin
    LProc := ACompiler.GetRegProc(LIndex);
    ALines.Add(Format('  function %d %s %s import=%s', [LIndex, string(LProc.OrgName), ParamsText(LProc.Decl),
      HexOf(LProc.ImportDecl)]));
  end;
end;

procedure DumpConstants(ALines: TStrings; ACompiler: TPSPascalCompiler; AFrom: Integer);
var
  LIndex: Integer;
  LConstant: TPSConstant;
begin
  ALines.Add(Format('  constants total=%d new=%d', [ACompiler.GetConstCount, ACompiler.GetConstCount - AFrom]));
  for LIndex := AFrom to ACompiler.GetConstCount - 1 do
  begin
    LConstant := ACompiler.GetConst(LIndex);
    ALines.Add(Format('  const %d %s = %s', [LIndex, string(LConstant.OrgName), ConstantText(LConstant)]));
  end;
end;

procedure DumpVariables(ALines: TStrings; ACompiler: TPSPascalCompiler; AFrom: Integer);
var
  LIndex: Integer;
begin
  ALines.Add(Format('  variables total=%d new=%d', [ACompiler.GetVarCount, ACompiler.GetVarCount - AFrom]));
  for LIndex := AFrom to ACompiler.GetVarCount - 1 do
    ALines.Add(Format('  var %d %s: %s', [LIndex, string(ACompiler.GetVar(LIndex).OrgName),
      TypeName(ACompiler.GetVar(LIndex).aType)]));
end;

var
  GSurfaceLines: TStrings = nil;
  GSeenProcedures: Integer = 0;
  GSeenTypes: Integer = 0;
  GSeenConstants: Integer = 0;
  GSeenVariables: Integer = 0;
  GQuiet: Boolean = False;

// The tables of the compiler can be read only inside OnUses (afterwards the compiler frees them):
// this wrapper calls the real OnUses of the engine and dumps what that call has added
function DumpOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := PS_ScriptOnUses(Sender, Name);
  // the part of SYSTEM is the same in every surface: it is written once, in the surface of "all"
  if not (GQuiet and (Name = 'SYSTEM')) then
  begin
    GSurfaceLines.Add('onuses ' + string(Name) + ' result=' + BoolToStr(Result, True));
    DumpProcedures(GSurfaceLines, Sender, GSeenProcedures);
    DumpTypes(GSurfaceLines, Sender, GSeenTypes);
    DumpConstants(GSurfaceLines, Sender, GSeenConstants);
    DumpVariables(GSurfaceLines, Sender, GSeenVariables);
  end;
  GSeenProcedures := Sender.GetRegProcCount;
  GSeenTypes := Sender.GetTypeCount;
  GSeenConstants := Sender.GetConstCount;
  GSeenVariables := Sender.GetVarCount;
end;

// compiles "uses <unit>; begin end." and dumps what each OnUses call registered
procedure DumpSurface(ALines: TStrings; const AUnit: string; AQuiet: Boolean);
var
  LCompiler: TDoomCompiler;
  LPCode: TbtString;
begin
  GSurfaceLines := ALines;
  GQuiet := AQuiet;
  GSeenProcedures := 0;
  GSeenTypes := 0;
  GSeenConstants := 0;
  GSeenVariables := 0;
  LCompiler := TDoomCompiler.CreateDoomCompiler;
  try
    LCompiler.OnUses := DumpOnUses;
    if not LCompiler.CompileDoomScript(TbtString('uses ' + AnsiString(AUnit) + ';' + #13#10 + 'begin' + #13#10 + 'end.'#13#10), LPCode) then
    begin
      ALines.Add('COMPILE ERROR for unit ' + AUnit + ': ' + IntToStr(LCompiler.MsgCount) + ' messages');
      if LCompiler.MsgCount > 0 then
        ALines.Add('  ' + string(LCompiler.Msg[0].MessageToString));
      Exit;
    end;
    ALines.Add('units used=' + StringReplace(Trim(LCompiler.unitnames.Text), #13#10, ',', [rfReplaceAll]));
  finally
    LCompiler.Free;
    GSurfaceLines := nil;
  end;
end;

procedure DumpDeclarations(ALines: TStrings);
{$IF DECLARED(PS_ScriptRegistry)}
var
  LNames: TArray<string>;
  LName: string;
begin
  LNames := PS_ScriptRegistry.UnitNames;
  ALines.Add('declaration units=' + IntToStr(Length(LNames)));
  for LName in LNames do
  begin
    ALines.Add('unit ' + LName);
    ALines.Add(PS_ScriptRegistry.Declarations(LName));
  end;
end;
{$ELSE}
var
  LUnits: TStringList;
  LIndex: Integer;
begin
  LUnits := PS_ImportUnits as TStringList;
  ALines.Add('declaration units=' + IntToStr(LUnits.Count));
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    ALines.Add('unit ' + LUnits[LIndex]);
    ALines.Add((LUnits.Objects[LIndex] as TProcedureList).GetDeclarations);
  end;
end;
{$IFEND}

procedure VSH_WriteRegistrationDump(const AFileName: string);
var
  LLines: TStringList;
  LUnit: string;
begin
  LLines := TStringList.Create;
  try
    LLines.WriteBOM := False;
    LLines.Add('# ScriptHost registration dump (issue 173)');
    LLines.Add('[declarations]');
    DumpDeclarations(LLines);
    LLines.Add('[surface all]');
    DumpSurface(LLines, 'all', False);
    for LUnit in UNIT_ORDER do
    begin
      LLines.Add('[surface ' + LUnit + ']');
      DumpSurface(LLines, LUnit, True);
    end;
    LLines.SaveToFile(AFileName, TEncoding.ASCII);
  finally
    LLines.Free;
  end;
end;

end.
