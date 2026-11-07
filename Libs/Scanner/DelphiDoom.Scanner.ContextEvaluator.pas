{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the expressions evaluated on a context         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.ContextEvaluator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.Scanner.Expression.Intf, DelphiDoom.Scanner.Expression.Evaluator,
  DelphiDoom.Scanner.ContextEvaluator.Intf;

type
  /// <summary>
  ///   Port of TActorEvaluator and of the SC_*ActorEvaluator functions (sc_evaluate_actor.pas):
  ///   a TExpressionEvaluator whose functions receive the context of the evaluation, and the
  ///   list of the functions without arguments (the single tokens)
  /// </summary>
  TContextExpressionEvaluator = class(TInterfacedObject, IContextFunctionRegistry,
    IContextExpressionEvaluator)
  strict private
    FEvaluator: TExpressionEvaluator;
    FSingleTokens: TDictionary<string, Boolean>;
    FContext: Pointer;
  public
    /// <summary>ALog receives the warnings of the expressions and may be nil; AVariables may be nil (no variables)</summary>
    constructor Create(const ALog: ILog; const AVariables: IExpressionVariables);
    destructor Destroy; override;
    procedure AddFunction(const AName: string; const AFunction: TContextExpressionFunction;
      AParams: Integer);
    function Evaluate(AContext: Pointer; const AExpression: string): string;
    function IsSingleToken(const AToken: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

const
  SFunctionMissing = 'TContextExpressionEvaluator: the function %s is nil';

{ TContextExpressionEvaluator }

constructor TContextExpressionEvaluator.Create(const ALog: ILog; const AVariables: IExpressionVariables);
begin
  inherited Create;
  FEvaluator := TExpressionEvaluator.Create(ALog, AVariables);
  FSingleTokens := TDictionary<string, Boolean>.Create;
end;

destructor TContextExpressionEvaluator.Destroy;
begin
  FSingleTokens.Free;
  FEvaluator.Free;
  inherited;
end;

procedure TContextExpressionEvaluator.AddFunction(const AName: string;
  const AFunction: TContextExpressionFunction; AParams: Integer);
var
  LFunction: TContextExpressionFunction;
begin
  if not Assigned(AFunction) then
    raise EArgumentNilException.CreateFmt(SFunctionMissing, [AName]);
  // the old AddFunc declared the single token before adding the function
  if AParams = 0 then
    FSingleTokens.AddOrSetValue(TScannerStrings.UpperAscii(AName), True);
  LFunction := AFunction;
  FEvaluator.AddFunction(AName,
    function(const AArguments: TArray<string>): string
    begin
      Result := LFunction(FContext, AArguments);
    end, AParams);
end;

function TContextExpressionEvaluator.Evaluate(AContext: Pointer; const AExpression: string): string;
begin
  FContext := AContext;
  // the old SC_EvaluateActorExpression gave the text back on any exception
  try
    Result := FEvaluator.Evaluate(AExpression);
  except
    on Exception do
      Result := AExpression;
  end;
end;

function TContextExpressionEvaluator.IsSingleToken(const AToken: string): Boolean;
begin
  Result := FSingleTokens.ContainsKey(TScannerStrings.UpperAscii(AToken));
end;

end.
