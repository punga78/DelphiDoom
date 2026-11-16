{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - a node of the tree of an expression            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Expression.Node;

interface

uses
  System.Generics.Collections, DelphiDoom.Scanner.Expression.Intf;

type
  /// <summary>
  ///   A node is an operator with its two operands, a function with its arguments, or a
  ///   value (a text). The nodes under it belong to it
  /// </summary>
  TExpressionNode = class
  private
    FChildren: TObjectList<TExpressionNode>;
    FOperator: Char;
    FValue: string;
    FFunctionName: string;
    FFunction: TExpressionFunction;
    FFunctionParams: Integer;
    FHasFunction: Boolean;
    function GetCount: Integer;
    function GetChild(AIndex: Integer): TExpressionNode;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A new node under this one</summary>
    function AddChild: TExpressionNode;
    procedure SetFunction(const AName: string; const AFunction: TExpressionFunction; AParams: Integer);
    property Count: Integer read GetCount;
    property Children[AIndex: Integer]: TExpressionNode read GetChild; default;
    /// <summary>#0 if it is not an operator node</summary>
    property OperatorChar: Char read FOperator write FOperator;
    property Value: string read FValue write FValue;
    property HasFunction: Boolean read FHasFunction;
    property FunctionName: string read FFunctionName;
    property FunctionBody: TExpressionFunction read FFunction;
    /// <summary>The number of arguments the function wants; -1 for any number</summary>
    property FunctionParams: Integer read FFunctionParams;
  end;

implementation

{ TExpressionNode }

constructor TExpressionNode.Create;
begin
  inherited Create;
  FChildren := TObjectList<TExpressionNode>.Create(True);
  FOperator := #0;
end;

destructor TExpressionNode.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TExpressionNode.GetCount: Integer;
begin
  Result := FChildren.Count;
end;

function TExpressionNode.GetChild(AIndex: Integer): TExpressionNode;
begin
  if (AIndex < 0) or (AIndex >= FChildren.Count) then
    raise EExpressionException.Create('A node of the expression has no operand');
  Result := FChildren[AIndex];
end;

function TExpressionNode.AddChild: TExpressionNode;
begin
  Result := TExpressionNode.Create;
  FChildren.Add(Result);
end;

procedure TExpressionNode.SetFunction(const AName: string; const AFunction: TExpressionFunction;
  AParams: Integer);
begin
  FFunctionName := AName;
  FFunction := AFunction;
  FFunctionParams := AParams;
  FHasFunction := True;
end;

end.
