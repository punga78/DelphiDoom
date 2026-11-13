{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info and script tables - the fakes                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.InfoTables.Fakes;

interface

uses
  System.Classes,
  DelphiDoom.ActorDef.ParamList.Intf,
  DelphiDoom.Scanner.ContextEvaluator.Intf;

type
  /// <summary>A random source that repeats from a seed and counts its draws</summary>
  TFakeParamRandom = class(TInterfacedObject, IActorDefParamRandom)
  strict private
    FState: Cardinal;
    FDraws: Integer;
  public
    constructor Create(const ASeed: Cardinal);
    function Next: Integer;
    property Draws: Integer read FDraws;
  end;

  /// <summary>
  ///   An evaluator that gives a number or a boolean from the text it is asked for and writes
  ///   every request in a log; "foo" and "bar" are the names of functions without arguments
  /// </summary>
  TFakeEvaluator = class(TInterfacedObject, IContextExpressionEvaluator)
  strict private
    FLog: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Evaluate(AContext: Pointer; const AExpression: string): string;
    function IsSingleToken(const AToken: string): Boolean;
    property Log: TStringList read FLog;
  end;

implementation

uses
  System.SysUtils;

{ TFakeParamRandom }

constructor TFakeParamRandom.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

function TFakeParamRandom.Next: Integer;
begin
  FState := FState * 1103515245 + 12345;
  Inc(FDraws);
  Result := (FState shr 16) and 255;
end;

{ TFakeEvaluator }

constructor TFakeEvaluator.Create;
begin
  inherited Create;
  FLog := TStringList.Create;
end;

destructor TFakeEvaluator.Destroy;
begin
  FLog.Free;
  inherited Destroy;
end;

function TFakeEvaluator.Evaluate(AContext: Pointer; const AExpression: string): string;
var
  LSettings: TFormatSettings;
begin
  FLog.Add(IntToStr(NativeInt(AContext)) + '|' + AExpression);
  LSettings := TFormatSettings.Invariant;
  case Length(AExpression) mod 4 of
    0: Result := FloatToStr(Length(AExpression) * 1.25, LSettings);
    1: Result := '"true"';
    2: Result := IntToStr(Length(AExpression) * 3);
  else
    Result := '"abc"';
  end;
end;

function TFakeEvaluator.IsSingleToken(const AToken: string): Boolean;
begin
  FLog.Add('single|' + AToken);
  Result := SameText(AToken, 'foo') or SameText(AToken, 'bar');
end;

end.
