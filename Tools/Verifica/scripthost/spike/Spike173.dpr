program Spike173;
// Spike #173: RegisterDelphiMethod vs RegisterDelphiFunction (cdRegister).
// Strings crossing the Pascal Script boundary are string (string).

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime;

type
  TLongWordArray = array of LongWord;

  TTest = class
  strict private
    FBase: Integer;
    FPrefix: string;
  public
    constructor Create(ABase: Integer; const APrefix: string);
    function Echo(const S: string): string;
    function Fmt(const AFormat: string; const Args: array of const): string;
    function MakeArr(N: Integer): TLongWordArray;
    function ExtMul(X: Extended): Extended;
    function DblMul(X: Double): Double;
    function SngMul(X: Single): Single;
    function GetBase: Integer;
  end;

var
  GBase: Integer = 100;
  GPrefix: string = 'pre';
  GPass: Integer = 0;
  GFail: Integer = 0;
  GLabel: string;

constructor TTest.Create(ABase: Integer; const APrefix: string);
begin
  inherited Create;
  FBase := ABase;
  FPrefix := APrefix;
end;

function TTest.Echo(const S: string): string;
begin
  Result := S + '!' + FPrefix;
end;

function TTest.Fmt(const AFormat: string; const Args: array of const): string;
begin
  Result := string(Format(AFormat, Args));
end;

function TTest.MakeArr(N: Integer): TLongWordArray;
var
  I: Integer;
begin
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := LongWord(FBase + I);
end;

function TTest.ExtMul(X: Extended): Extended;
begin
  Result := X * 2;
end;

function TTest.DblMul(X: Double): Double;
begin
  Result := X * 2;
end;

function TTest.SngMul(X: Single): Single;
begin
  Result := X * 2;
end;

function TTest.GetBase: Integer;
begin
  Result := FBase;
end;

// Procedural twins (same bodies, globals instead of fields)

function EchoP(const S: string): string;
begin
  Result := S + '!' + GPrefix;
end;

function FmtP(const AFormat: string; const Args: array of const): string;
begin
  Result := string(Format(AFormat, Args));
end;

function MakeArrP(N: Integer): TLongWordArray;
var
  I: Integer;
begin
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := LongWord(GBase + I);
end;

function ExtMulP(X: Extended): Extended;
begin
  Result := X * 2;
end;

function DblMulP(X: Double): Double;
begin
  Result := X * 2;
end;

function SngMulP(X: Single): Single;
begin
  Result := X * 2;
end;

function GetBaseP: Integer;
begin
  Result := GBase;
end;

procedure Check(const AName: string; AOk: Boolean);
begin
  if AOk then
  begin
    Inc(GPass);
    Writeln('  PASS  ', GLabel, ' ', AName);
  end
  else
  begin
    Inc(GFail);
    Writeln('  FAIL  ', GLabel, ' ', AName);
  end;
end;

const
  SCRIPT_TEXT =
    'var a: TLongWordArray;'#13#10 +
    'begin'#13#10 +
    '  Check(''1 string result + const string'', Echo(''x'') = ''x!pre'');'#13#10 +
    '  Check(''2 array of const (Format)'', Fmt(''%d-%s-%.1f'', [7, ''ab'', 2.5]) = ''7-ab-2.5'');'#13#10 +
    '  a := MakeArr(3);'#13#10 +
    '  Check(''3a dynarray length'', Length(a) = 3);'#13#10 +
    '  Check(''3b dynarray content'', (a[0] = 100) and (a[1] = 101) and (a[2] = 102));'#13#10 +
    '  Check(''4a Extended'', ExtMul(1.5) = 3.0);'#13#10 +
    '  Check(''4b Double'', DblMul(1.5) = 3.0);'#13#10 +
    '  Check(''4c Single'', SngMul(1.5) = 3.0);'#13#10 +
    '  Check(''5 integer from field/Self'', GetBase = 100);'#13#10 +
    'end.';

function OnUses(Sender: TPSPascalCompiler; const AName: TbtString): Boolean;
begin
  Result := True;
  if AName = 'SYSTEM' then
  begin
    Sender.AddTypeS('TLongWordArray', 'array of LongWord');
    Sender.AddDelphiFunction('procedure Check(const AName: string; AOk: Boolean);');
    Sender.AddDelphiFunction('function Echo(const S: string): string;');
    Sender.AddDelphiFunction('function Fmt(const F: string; const Args: array of const): string;');
    Sender.AddDelphiFunction('function MakeArr(N: Integer): TLongWordArray;');
    Sender.AddDelphiFunction('function ExtMul(X: Extended): Extended;');
    Sender.AddDelphiFunction('function DblMul(X: Double): Double;');
    Sender.AddDelphiFunction('function SngMul(X: Single): Single;');
    Sender.AddDelphiFunction('function GetBase: Integer;');
  end;
end;

procedure RunScript(const ALabel: string; AInstance: TTest);
var
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytecode: TbtString;
  LIndex: Integer;
begin
  GLabel := ALabel;
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    LCompiler.OnUses := OnUses;
    if not LCompiler.Compile(SCRIPT_TEXT) then
    begin
      for LIndex := 0 to LCompiler.MsgCount - 1 do
        Writeln('  COMPILE: ', string(LCompiler.Msg[LIndex].MessageToString));
      Exit;
    end;
    LCompiler.GetOutput(LBytecode);
  finally
    LCompiler.Free;
  end;

  LExec := TPSExec.Create;
  try
    LExec.RegisterDelphiFunction(@Check, 'CHECK', cdRegister);
    if Assigned(AInstance) then
    begin
      LExec.RegisterDelphiMethod(AInstance, @TTest.Echo, 'ECHO', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.Fmt, 'FMT', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.MakeArr, 'MAKEARR', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.ExtMul, 'EXTMUL', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.DblMul, 'DBLMUL', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.SngMul, 'SNGMUL', cdRegister);
      LExec.RegisterDelphiMethod(AInstance, @TTest.GetBase, 'GETBASE', cdRegister);
    end
    else
    begin
      LExec.RegisterDelphiFunction(@EchoP, 'ECHO', cdRegister);
      LExec.RegisterDelphiFunction(@FmtP, 'FMT', cdRegister);
      LExec.RegisterDelphiFunction(@MakeArrP, 'MAKEARR', cdRegister);
      LExec.RegisterDelphiFunction(@ExtMulP, 'EXTMUL', cdRegister);
      LExec.RegisterDelphiFunction(@DblMulP, 'DBLMUL', cdRegister);
      LExec.RegisterDelphiFunction(@SngMulP, 'SNGMUL', cdRegister);
      LExec.RegisterDelphiFunction(@GetBaseP, 'GETBASE', cdRegister);
    end;
    if not LExec.LoadData(LBytecode) then
    begin
      Writeln('  LOAD ERROR');
      Exit;
    end;
    try
      LExec.RunScript;
      if LExec.ExceptionCode <> erNoError then
        Writeln('  EXEC ERROR: ', string(LExec.ExceptionString));
    except
      on E: Exception do
        Writeln('  HOST EXCEPTION: ', E.ClassName, ': ', E.Message);
    end;
  finally
    LExec.Free;
  end;
end;

var
  LTest: TTest;
begin
  {$IFDEF CPUX64}
  Writeln('=== Win64 ===');
  {$ELSE}
  Writeln('=== Win32 ===');
  {$ENDIF}
  LTest := TTest.Create(100, 'pre');
  try
    Writeln('[procedural cdRegister]');
    RunScript('proc  ', nil);
    Writeln('[RegisterDelphiMethod cdRegister]');
    GBase := -1;
    GPrefix := 'bad';
    RunScript('method', LTest);
  finally
    LTest.Free;
  end;
  Writeln('PASS=', GPass, ' FAIL=', GFail);
end.
