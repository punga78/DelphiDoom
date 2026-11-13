{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info and script tables - the old parameter list    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The code of Base\sc_params.pas as it was before issue #185 (commit 63a151cc), copied line by
// line (renamed TLegacyParamList and Legacy_EvalString). Only the world around it is replaced:
// N_Random is Legacy_NRandomSource, and the functions that read the map, the world and the custom
// parameters, which the old code never reached, are stubs.
unit DelphiDoom.Tests.InfoTables.LegacyParams;
interface

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Scanner.ContextEvaluator.Intf;

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;

type
  fixed_t = integer;
  TLegacyRandomSource = reference to function: integer;
  Pmobjcustomparam_t = ^mobjcustomparam_t;
  mobjcustomparam_t = record
    value: integer;
  end;
  Pmobj_t = ^mobj_t;
  mobj_t = record
    target: Pmobj_t;
    master: Pmobj_t;
    tracer: Pmobj_t;
  end;

// The random numbers of the old N_Random, given by the test
var
  Legacy_NRandomSource: TLegacyRandomSource;

function Legacy_NRandom: integer;
function FloatToFixed(const f: float): fixed_t;

const
  GLBF_MAP_STRING = 1;
  GLBF_MAP_INTEGER = 2;
  GLBF_MAP_FLOAT = 3;
  GLBF_WORLD_STRING = 4;
  GLBF_WORLD_INTEGER = 5;
  GLBF_WORLD_FLOAT = 6;
  GLBF_MOBJ_CUSTOMPARM = 7;
  GLBF_MOBJ_TARGETCUSTOMPARM = 8;
  GLBF_RANDOM = 9;
  GLBF_FRANDOM = 10;
  GLBF_EVALUATE = 11;
  GLBF_MOBJ_MASTERCUSTOMPARM = 12;
  GLBF_MOBJ_TRACERCUSTOMPARM = 13;
  GLBF_FORCE_EVALUATE = 14;

const
  CPFLG_FLOATSTRING = 1;

type
  customparam_t = record
    s_param: string[255];
    i_param: integer;
    i_parm1, i_parm2: integer;
    f_param: single;
    f_parm1, f_parm2: single;
    fx_param: fixed_t;
    globalidx: integer;
    computed: boolean;
    flags: integer;
  end;
  customparam_tArray = array[0..$FFF] of customparam_t;
  Pcustomparam_tArray = ^customparam_tArray;

  TLegacyParamList = class
  private
    fList: Pcustomparam_tArray;
    fNumItems: integer;
    fActor: pointer;
    fdeclaration: string;
    fEvaluator: IContextExpressionEvaluator;
    function Evaluator: IContextExpressionEvaluator;
  protected
    function GetIsComputed(index: integer): boolean; virtual;
    function GetInteger(index: integer): integer; virtual;
    procedure PutInteger(index: integer; const value: integer); virtual;
    function GetFloat(index: integer): single; virtual;
    procedure PutFloat(index: integer; const value: single); virtual;
    function GetFixed(index: integer): fixed_t; virtual;
    function GetMBF21Fixed(index: integer): fixed_t; virtual;
    function GetBool(index: integer): boolean; virtual;
    function GetString(index: integer): string; virtual;
    function GetEvaluateString(index: integer): string; virtual;
  public
    /// <summary>
    ///   AEvaluator reads the expressions of the parameters (the one that the composition root
    ///   gives to the DEHACKED applier); it may be nil only for a list of numbers, that never
    ///   asks it (P_CheckStateArgs)
    /// </summary>
    constructor Create(const tx: string; const AEvaluator: IContextExpressionEvaluator); virtual;
    destructor Destroy; override;
    procedure AddParam(const parmtype: integer; const value: string); virtual;
    property Count: integer read fNumItems;
    property IsComputed[index: integer]: boolean read GetIsComputed;
    property IntVal[index: integer]: integer read GetInteger write PutInteger;
    property FloatVal[index: integer]: single read GetFloat write PutFloat;
    property FixedVal[index: integer]: fixed_t read GetFixed;
    property MBF21FixedVal[index: integer]: fixed_t read GetMBF21Fixed;
    property BoolVal[index: integer]: boolean read GetBool;
    property StrVal[index: integer]: string read GetString;
    property EvaluateStrVal[index: integer]: string read GetEvaluateString;
    property Declaration: string read fdeclaration;
    property Actor: pointer read fActor write fActor;
  end;

//==============================================================================
//
// Legacy_EvalString
//
//==============================================================================
function Legacy_EvalString(const token: string): string;

implementation

uses
  DelphiDoom.Scanner.Text;

function Legacy_NRandom: integer;
begin
  result := Legacy_NRandomSource();
end;

function FloatToFixed(const f: float): fixed_t;
begin
  result := Round(f * FRACUNIT);
end;

// The old code read the map and world variables and the custom parameters of the actor for the
// kinds GLBF_MAP_* and so on, that it never stored: they are not reachable, stubs for the compiler
function PS_GetMapStr(const x: string): string;
begin
  result := '';
end;

function PS_GetMapInt(const x: string): integer;
begin
  result := 0;
end;

function PS_GetMapFloat(const x: string): float;
begin
  result := 0.0;
end;

function PS_GetWorldStr(const x: string): string;
begin
  result := '';
end;

function PS_GetWorldInt(const x: string): integer;
begin
  result := 0;
end;

function PS_GetWorldFloat(const x: string): float;
begin
  result := 0.0;
end;

function P_GetMobjCustomParam(const actor1: pointer; const name1: string): Pmobjcustomparam_t;
begin
  result := nil;
end;

//==============================================================================
//
// TLegacyParamList.Evaluator
//
//==============================================================================
function TLegacyParamList.Evaluator: IContextExpressionEvaluator;
begin
  if fEvaluator = nil then
    raise Exception.Create('no evaluator');
  result := fEvaluator;
end;

//==============================================================================
//
// TLegacyParamList.Create
//
//==============================================================================
constructor TLegacyParamList.Create(const tx: string; const AEvaluator: IContextExpressionEvaluator);
var
  i, j: integer;
  ok: boolean;
  token: string;
  utoken: string;
  lst: TArray<string>;
  lstparam: TDStringList;
begin
  fList := nil;
  fNumItems := 0;
  fActor := nil;
  fdeclaration := tx;
  fEvaluator := AEvaluator;

  lst := TScannerText.ParamsToList(tx);

  for i := 0 to High(lst) do
  begin
    if StrIsInteger(lst[i]) then
    begin
      AddParam(0, lst[i])
    end
    else if StrIsFloat(lst[i]) then
    begin
      AddParam(0, lst[i])
    end
    else if TScannerText.IsStringInQuotes(lst[i]) then
    begin
      AddParam(0, Copy(lst[i], 2, length(lst[i]) - 2));
    end
    else
    begin
      lstparam := wordstolist(lst[i], [' ', #13, #10, #9, #7, '(', ',', ')', '[', ']']);

      if lstparam.Count > 0 then
      begin
        token := strupper(lstparam[0]);
        utoken := strupper(token);
        if utoken = 'RANDOM' then
        begin
          if lstparam.Count <= 3 then
          begin
            ok := true;
            for j := 1 to lstparam.Count - 1 do
              ok := ok and StrIsInteger(lstparam[j]);
            if ok then
              AddParam(GLBF_RANDOM, 'RANDOM ' + lstparam[1] + ' ' + lstparam[2])
            else
              AddParam(GLBF_EVALUATE, lst[i]);
          end
          else
            AddParam(GLBF_EVALUATE, lst[i]);
        end
        else if (utoken = 'FRANDOM') or (utoken = 'FLOATRANDOM') then
        begin
          if lstparam.Count <= 3 then
          begin
            ok := true;
            for j := 1 to lstparam.Count - 1 do
              ok := ok and StrIsFloat(lstparam[j]);
            if ok then
              AddParam(GLBF_FRANDOM, 'FRANDOM ' + lstparam[1] + ' ' + lstparam[2])
            else
              AddParam(GLBF_EVALUATE, lst[i]);
          end
          else
            AddParam(GLBF_EVALUATE, lst[i]);
        end
        else if utoken = 'EVAL' then
          AddParam(GLBF_FORCE_EVALUATE, lst[i])
        else if (utoken = 'MAPSTR') or
                (utoken = 'WORLDSTR') or
                (utoken = 'MAPINT') or
                (utoken = 'WORLDINT') or
                (utoken = 'MAPFLOAT') or
                (utoken = 'WORLDFLOAT') or
                (utoken = 'CUSTOMPARAM') or
                (utoken = 'TARGETCUSTOMPARAM') or
                (utoken = 'MASTERCUSTOMPARAM') or
                (utoken = 'TRACERCUSTOMPARAM') then
        begin
          ok := false;
          if lstparam.Count = 2 then
            if TScannerText.IsStringInQuotes(lstparam[1]) then
              ok := true;
          if ok then
          begin
            if utoken = 'MAPSTR' then
              AddParam(GLBF_MAP_STRING, 'MAPSTR ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'WORLDSTR' then
              AddParam(GLBF_WORLD_STRING, 'WORLDSTR ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'MAPINT' then
              AddParam(GLBF_MAP_INTEGER, 'MAPINT ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'WORLDINT' then
              AddParam(GLBF_WORLD_INTEGER, 'WORLDINT ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'MAPFLOAT' then
              AddParam(GLBF_MAP_FLOAT, 'MAPFLOAT ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'WORLDFLOAT' then
              AddParam(GLBF_WORLD_FLOAT, 'WORLDFLOAT ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'CUSTOMPARAM' then
              AddParam(GLBF_MOBJ_CUSTOMPARM, 'CUSTOMPARAM ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'TARGETCUSTOMPARAM' then
              AddParam(GLBF_MOBJ_TARGETCUSTOMPARM, 'TARGETCUSTOMPARAM ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'MASTERCUSTOMPARAM' then
              AddParam(GLBF_MOBJ_MASTERCUSTOMPARM, 'MASTERCUSTOMPARAM ' + RemoveQuotesFromString(lstparam[1]))
            else if utoken = 'TRACERCUSTOMPARAM' then
              AddParam(GLBF_MOBJ_TRACERCUSTOMPARM, 'TRACERCUSTOMPARAM ' + RemoveQuotesFromString(lstparam[1]))
          end
          else
          begin
            AddParam(GLBF_EVALUATE, lst[i]);
          end;
        end
        else
        begin
          if (lstparam.Count = 1) and not Evaluator.IsSingleToken(lstparam[0]) then
            AddParam(0, lstparam[0])
          else
            AddParam(GLBF_EVALUATE, lst[i]);
        end;

      end;

      lstparam.Free;
    end;
  end;

end;

//==============================================================================
//
// TLegacyParamList.Destroy
//
//==============================================================================
destructor TLegacyParamList.Destroy;
begin
  if fNumItems > 0 then
    realloc(pointer(fList), fNumItems * SizeOf(customparam_t), 0);
end;

//==============================================================================
//
// TLegacyParamList.AddParam
//
//==============================================================================
procedure TLegacyParamList.AddParam(const parmtype: integer; const value: string);
var
  ival: integer;
  fval: single;
  token, token1, token2: string;
  utoken: string;
begin
  realloc(pointer(fList), fNumItems * SizeOf(customparam_t), (fNumItems + 1) * SizeOf(customparam_t));
  fList[fNumItems].flags := 0;
  splitstring_ch(value, token1, token);
  utoken := strupper(token1);
  if (utoken = 'RANDOM') and (parmtype = GLBF_RANDOM) then
  begin
    fList[fNumItems].globalidx := GLBF_RANDOM;
    fList[fNumItems].s_param := ShortString('');
    fList[fNumItems].computed := false;
    if token = '' then
    begin
      fList[fNumItems].i_parm1 := 0;
      fList[fNumItems].i_parm2 := 255;
    end
    else
    begin
      splitstring_ch(token, token1, token2);
      if token2 = '' then
      begin
        fList[fNumItems].i_parm1 := 0;
        fList[fNumItems].i_parm2 := atoi(token1, 255);
      end
      else
      begin
        fList[fNumItems].i_parm1 := atoi(token1, 0);
        fList[fNumItems].i_parm2 := atoi(token2, 255);
      end;
    end;
  end
  else if ((utoken = 'FRANDOM') or (utoken = 'FLOATRANDOM')) and (parmtype = GLBF_FRANDOM) then
  begin
    fList[fNumItems].globalidx := GLBF_FRANDOM;
    fList[fNumItems].s_param := ShortString('');
    fList[fNumItems].computed := false;
    if token = '' then
    begin
      fList[fNumItems].f_parm1 := 0;
      fList[fNumItems].f_parm2 := 255;
    end
    else
    begin
      splitstring_ch(token, token1, token2);
      if token2 = '' then
      begin
        fList[fNumItems].f_parm1 := 0;
        fList[fNumItems].f_parm2 := atof(token1, 255);
      end
      else
      begin
        fList[fNumItems].f_parm1 := atof(token1, 0);
        fList[fNumItems].f_parm2 := atof(token2, 255);
      end;
    end;
  end
  else if (utoken = 'EVAL') and (parmtype = GLBF_FORCE_EVALUATE) then
  begin
    fList[fNumItems].globalidx := GLBF_FORCE_EVALUATE;
    fList[fNumItems].computed := false;
    fList[fNumItems].s_param := ShortString(value);
  end
  else
  begin
    if (utoken = 'MAPSTR') and (parmtype = GLBF_MAP_STRING) then
    begin
      fList[fNumItems].globalidx := GLBF_MAP_STRING;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'WORLDSTR') and (parmtype = GLBF_WORLD_STRING) then
    begin
      fList[fNumItems].globalidx := GLBF_WORLD_STRING;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'MAPINT') and (parmtype = GLBF_MAP_INTEGER) then
    begin
      fList[fNumItems].globalidx := GLBF_MAP_INTEGER;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'WORLDINT') and (parmtype = GLBF_WORLD_INTEGER) then
    begin
      fList[fNumItems].globalidx := GLBF_WORLD_INTEGER;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'MAPFLOAT') and (parmtype = GLBF_MAP_FLOAT) then
    begin
      fList[fNumItems].globalidx := GLBF_MAP_FLOAT;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'WORLDFLOAT') and (parmtype = GLBF_WORLD_FLOAT) then
    begin
      fList[fNumItems].globalidx := GLBF_WORLD_FLOAT;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'CUSTOMPARAM') and (parmtype = GLBF_MOBJ_CUSTOMPARM) then
    begin
      fList[fNumItems].globalidx := GLBF_MOBJ_CUSTOMPARM;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'TARGETCUSTOMPARAM') and (parmtype = GLBF_MOBJ_TARGETCUSTOMPARM) then
    begin
      fList[fNumItems].globalidx := GLBF_MOBJ_TARGETCUSTOMPARM;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'MASTERCUSTOMPARAM') and (parmtype = GLBF_MOBJ_MASTERCUSTOMPARM) then
    begin
      fList[fNumItems].globalidx := GLBF_MOBJ_MASTERCUSTOMPARM;
      fList[fNumItems].s_param := ShortString(token);
    end
    else if (utoken = 'TRACERCUSTOMPARAM') and (parmtype = GLBF_MOBJ_TRACERCUSTOMPARM) then
    begin
      fList[fNumItems].globalidx := GLBF_MOBJ_TRACERCUSTOMPARM;
      fList[fNumItems].s_param := ShortString(token);
    end
    else
    begin
      fList[fNumItems].globalidx := parmtype;
      fList[fNumItems].s_param := ShortString(value);
      if StrIsFloat(value) then
        if not StrIsInteger(value) then
          fList[fNumItems].flags := fList[fNumItems].flags or CPFLG_FLOATSTRING;
    end;
    if parmtype = 0 then
    begin
      fList[fNumItems].globalidx := 0;
      ival := atoi(value);
      fList[fNumItems].i_param := ival;
      fList[fNumItems].computed := itoa(ival) = value;
      if fList[fNumItems].computed then
      begin
        fList[fNumItems].f_param := ival;
        fList[fNumItems].fx_param := ival * FRACUNIT;
      end
      else
      begin
        fval := atof(value);
        fList[fNumItems].f_param := fval;
        fList[fNumItems].fx_param := round(fval * FRACUNIT);
        fList[fNumItems].computed := ftoa(ival) = value;
      end;
    end
    else
    begin
      fList[fNumItems].globalidx := GLBF_EVALUATE;
      fList[fNumItems].computed := false;
      fList[fNumItems].s_param := ShortString(value);
    end;
  end;

  inc(fNumItems);
end;

//==============================================================================
//
// TLegacyParamList.GetIsComputed
//
//==============================================================================
function TLegacyParamList.GetIsComputed(index: integer): boolean;
begin
  result := fList[index].computed;
end;

//==============================================================================
//
// TLegacyParamList.GetInteger
//
//==============================================================================
function TLegacyParamList.GetInteger(index: integer): integer;
var
  parm: Pmobjcustomparam_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    case fList[index].globalidx of
      GLBF_RANDOM:
        result := fList[index].i_parm1 + (Legacy_NRandom * (fList[index].i_parm2 - fList[index].i_parm1 + 1)) div 256;
      GLBF_FRANDOM:
        result := round(fList[index].f_parm1 + (Legacy_NRandom * (fList[index].f_parm2 - fList[index].f_parm1 + 1)) / 256);
      GLBF_EVALUATE,
      GLBF_FORCE_EVALUATE:
        result := round(atof(Evaluator.Evaluate(fActor, string(fList[index].s_param))));
      GLBF_MAP_STRING:
        result := atoi(PS_GetMapStr(string(fList[index].s_param)), 0);
      GLBF_MAP_INTEGER:
        result := PS_GetMapInt(string(fList[index].s_param));
      GLBF_MAP_FLOAT:
        result := round(PS_GetMapFloat(string(fList[index].s_param)));
      GLBF_WORLD_STRING:
        result := atoi(PS_GetWorldStr(string(fList[index].s_param)), 0);
      GLBF_WORLD_INTEGER:
        result := PS_GetWorldInt(string(fList[index].s_param));
      GLBF_WORLD_FLOAT:
        result := round(PS_GetWorldFloat(string(fList[index].s_param)));
      GLBF_MOBJ_CUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
          begin
            parm := P_GetMobjCustomParam(fActor, string(fList[index].s_param));
            if parm <> nil then
              result := parm.value;
          end;
        end;
      GLBF_MOBJ_TARGETCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).target <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).target, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
      GLBF_MOBJ_MASTERCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).master <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).master, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
      GLBF_MOBJ_TRACERCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).tracer <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).tracer, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
    else
      result := fList[index].i_param;
    end;
  end
  else
    result := 0;
end;

//==============================================================================
//
// TLegacyParamList.PutInteger
//
//==============================================================================
procedure TLegacyParamList.PutInteger(index: integer; const value: integer);
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    fList[index].i_param := value;
    { -----------------------------
     old code:
    fList[index].computed := true;
    fList[index].israndom := false;
    -------------------------------}
    if fList[index].globalidx = 0 then
      fList[index].computed := true;
  end;
end;

//==============================================================================
//
// TLegacyParamList.GetFloat
//
//==============================================================================
function TLegacyParamList.GetFloat(index: integer): single;
var
  parm: Pmobjcustomparam_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    case fList[index].globalidx of
      GLBF_RANDOM:
        result := (fList[index].i_parm1 * FRACUNIT + Legacy_NRandom * (fList[index].i_parm2 - fList[index].i_parm1 + 1) * 256) / FRACUNIT;
      GLBF_FRANDOM:
        result := (fList[index].f_parm1 * FRACUNIT + Legacy_NRandom * (fList[index].f_parm2 - fList[index].f_parm1 + 1) * 256) / FRACUNIT;
      GLBF_EVALUATE,
      GLBF_FORCE_EVALUATE:
        result := atof(Evaluator.Evaluate(fActor, string(fList[index].s_param)));
      GLBF_MAP_STRING:
        result := atof(PS_GetMapStr(string(fList[index].s_param)), 0.0);
      GLBF_MAP_INTEGER:
        result := PS_GetMapInt(string(fList[index].s_param));
      GLBF_MAP_FLOAT:
        result := PS_GetMapFloat(string(fList[index].s_param));
      GLBF_WORLD_STRING:
        result := atof(PS_GetWorldStr(string(fList[index].s_param)), 0.0);
      GLBF_WORLD_INTEGER:
        result := PS_GetWorldInt(string(fList[index].s_param));
      GLBF_WORLD_FLOAT:
        result := PS_GetWorldFloat(string(fList[index].s_param));
      GLBF_MOBJ_CUSTOMPARM:
        begin
          result := 0.0;
          if fActor <> nil then
          begin
            parm := P_GetMobjCustomParam(fActor, string(fList[index].s_param));
            if parm <> nil then
              result := parm.value;
          end;
        end;
      GLBF_MOBJ_TARGETCUSTOMPARM:
        begin
          result := 0.0;
          if fActor <> nil then
            if Pmobj_t(fActor).target <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).target, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
      GLBF_MOBJ_MASTERCUSTOMPARM:
        begin
          result := 0.0;
          if fActor <> nil then
            if Pmobj_t(fActor).master <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).master, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
      GLBF_MOBJ_TRACERCUSTOMPARM:
        begin
          result := 0.0;
          if fActor <> nil then
            if Pmobj_t(fActor).tracer <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).tracer, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value;
            end;
        end;
    else
      result := fList[index].f_param;
    end;
  end
  else
    result := 0.0;
end;

//==============================================================================
//
// TLegacyParamList.PutFloat
//
//==============================================================================
procedure TLegacyParamList.PutFloat(index: integer; const value: float);
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    fList[index].f_param := value;
    fList[index].fx_param := round(value * FRACUNIT);
    {----------------------------
    old code:
    fList[index].computed := true;
    fList[index].israndom := false;
    -------------------------------}
    if fList[index].globalidx = 0 then
      fList[index].computed := true;
  end;
end;

//==============================================================================
//
// TLegacyParamList.GetFixed
//
//==============================================================================
function TLegacyParamList.GetFixed(index: integer): fixed_t;
var
  parm: Pmobjcustomparam_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    case fList[index].globalidx of
      GLBF_RANDOM:
        result := fList[index].i_parm1 * FRACUNIT + Legacy_NRandom * (fList[index].i_parm2 - fList[index].i_parm1 + 1) * 256;
      GLBF_FRANDOM:
        result := round(fList[index].f_parm1 * FRACUNIT + Legacy_NRandom * (fList[index].f_parm2 - fList[index].f_parm1 + 1) * 256);
      GLBF_EVALUATE,
      GLBF_FORCE_EVALUATE:
        result := round(atof(Evaluator.Evaluate(fActor, string(fList[index].s_param))) * FRACUNIT);
      GLBF_MAP_STRING:
        result := round(atof(PS_GetMapStr(string(fList[index].s_param)), 0.0) * FRACUNIT);
      GLBF_MAP_INTEGER:
        result := PS_GetMapInt(string(fList[index].s_param)) * FRACUNIT;
      GLBF_MAP_FLOAT:
        result := round(PS_GetMapFloat(string(fList[index].s_param)) * FRACUNIT);
      GLBF_WORLD_STRING:
        result := round(atof(PS_GetWorldStr(string(fList[index].s_param)), 0.0) * FRACUNIT);
      GLBF_WORLD_INTEGER:
        result := PS_GetWorldInt(string(fList[index].s_param)) * FRACUNIT;
      GLBF_WORLD_FLOAT:
        result := round(PS_GetWorldFloat(string(fList[index].s_param)) * FRACUNIT);
      GLBF_MOBJ_CUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
          begin
            parm := P_GetMobjCustomParam(fActor, string(fList[index].s_param));
            if parm <> nil then
              result := parm.value * FRACUNIT;
          end;
        end;
      GLBF_MOBJ_TARGETCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).target <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).target, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value * FRACUNIT;
            end;
        end;
      GLBF_MOBJ_MASTERCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).master <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).master, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value * FRACUNIT;
            end;
        end;
      GLBF_MOBJ_TRACERCUSTOMPARM:
        begin
          result := 0;
          if fActor <> nil then
            if Pmobj_t(fActor).tracer <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).tracer, string(fList[index].s_param));
              if parm <> nil then
                result := parm.value * FRACUNIT;
            end;
        end;
    else
      result := fList[index].fx_param;
    end;
  end
  else
    result := 0;
end;

//==============================================================================
//
// TLegacyParamList.GetMBF21Fixed
//
//==============================================================================
function TLegacyParamList.GetMBF21Fixed(index: integer): fixed_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    if fList[index].flags and CPFLG_FLOATSTRING <> 0 then
      result := FloatToFixed(atof(string(fList[index].s_param)))
    else
      result := GetInteger(index);
  end
  else
    result := 0;
end;

//==============================================================================
//
// TLegacyParamList.GetBool
//
//==============================================================================
function TLegacyParamList.GetBool(index: integer): boolean;
var
  ret: string;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    ret := Evaluator.Evaluate(fActor, string(fList[index].s_param));
    result := strupper(RemoveQuotesFromString(ret)) = 'TRUE';
  end
  else
    result := false;
end;

//==============================================================================
//
// TLegacyParamList.GetString
//
//==============================================================================
function TLegacyParamList.GetString(index: integer): string;
var
  parm: Pmobjcustomparam_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    case fList[index].globalidx of
      GLBF_FORCE_EVALUATE:
        result := RemoveQuotesFromString(Evaluator.Evaluate(fActor, string(fList[index].s_param)));
      GLBF_MAP_STRING:
        result := PS_GetMapStr(string(fList[index].s_param));
      GLBF_MAP_INTEGER:
        result := itoa(PS_GetMapInt(string(fList[index].s_param)));
      GLBF_MAP_FLOAT:
        result := ftoa(PS_GetMapFloat(string(fList[index].s_param)));
      GLBF_WORLD_STRING:
        result := PS_GetWorldStr(string(fList[index].s_param));
      GLBF_WORLD_INTEGER:
        result := itoa(PS_GetWorldInt(string(fList[index].s_param)));
      GLBF_WORLD_FLOAT:
        result := ftoa(PS_GetWorldFloat(string(fList[index].s_param)));
      GLBF_MOBJ_CUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
          begin
            parm := P_GetMobjCustomParam(fActor, string(fList[index].s_param));
            if parm <> nil then
              result := itoa(parm.value);
          end;
        end;
      GLBF_MOBJ_TARGETCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).target <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).target, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      GLBF_MOBJ_MASTERCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).master <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).master, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      GLBF_MOBJ_TRACERCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).tracer <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).tracer, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      else
        result := RemoveQuotesFromString(string(fList[index].s_param));
    end;
  end
  else
    result := '';
end;

//==============================================================================
//
// TLegacyParamList.GetEvaluateString
//
//==============================================================================
function TLegacyParamList.GetEvaluateString(index: integer): string;
var
  parm: Pmobjcustomparam_t;
begin
  if (index >= 0) and (index < fNumItems) then
  begin
    case fList[index].globalidx of
      GLBF_EVALUATE,
      GLBF_FORCE_EVALUATE:
        result := RemoveQuotesFromString(Evaluator.Evaluate(fActor, string(fList[index].s_param)));
      GLBF_MAP_STRING:
        result := PS_GetMapStr(string(fList[index].s_param));
      GLBF_MAP_INTEGER:
        result := itoa(PS_GetMapInt(string(fList[index].s_param)));
      GLBF_MAP_FLOAT:
        result := ftoa(PS_GetMapFloat(string(fList[index].s_param)));
      GLBF_WORLD_STRING:
        result := PS_GetWorldStr(string(fList[index].s_param));
      GLBF_WORLD_INTEGER:
        result := itoa(PS_GetWorldInt(string(fList[index].s_param)));
      GLBF_WORLD_FLOAT:
        result := ftoa(PS_GetWorldFloat(string(fList[index].s_param)));
      GLBF_MOBJ_CUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
          begin
            parm := P_GetMobjCustomParam(fActor, string(fList[index].s_param));
            if parm <> nil then
              result := itoa(parm.value);
          end;
        end;
      GLBF_MOBJ_TARGETCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).target <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).target, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      GLBF_MOBJ_MASTERCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).master <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).master, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      GLBF_MOBJ_TRACERCUSTOMPARM:
        begin
          result := '';
          if fActor <> nil then
            if Pmobj_t(fActor).tracer <> nil then
            begin
              parm := P_GetMobjCustomParam(Pmobj_t(fActor).tracer, string(fList[index].s_param));
              if parm <> nil then
                result := itoa(parm.value);
            end;
        end;
      else
        result := RemoveQuotesFromString(string(fList[index].s_param));
    end;
  end
  else
    result := '';
end;

//==============================================================================
//
// Legacy_EvalString
//
//==============================================================================
function Legacy_EvalString(const token: string): string;
var
  sl: TDStringList;
  r1, r2: integer;
begin
  if token = '' then
  begin
    Result := '';
    Exit;
  end;

  if toupper(token[1]) = 'R' then // Speedup Hack :)
  begin
    sl := wordstolist(token, ['(', ')', ' ', ',', '[', ']']);
    if sl.Count > 1 then
    begin
      if strupper(sl.strings[0]) = 'RANDOMPICK' then
      begin
        sl.Delete(0);
        Result := RemoveQuotesFromString(sl.Strings[Legacy_NRandom mod sl.Count]);
        sl.Free;
        Exit;
      end
      else if strupper(sl.strings[0]) = 'RANDOM' then
      begin
        if sl.Count > 2 then
        begin
          r1 := atoi(sl.strings[1]);
          r2 := atoi(sl.strings[2]);
        end
        else if sl.count = 2 then
        begin
          r1 := 0;
          r2 := atoi(sl.strings[1]);
        end
        else
        begin
          r1 := 0;
          r2 := 255;
        end;
        Result := itoa(r1 + (Legacy_NRandom * (r2 - r1 + 1)) div 256);
        sl.Free;
        Exit;
      end;
    end;
    sl.Free;
  end;

  Result := RemoveQuotesFromString(token);
end;

end.