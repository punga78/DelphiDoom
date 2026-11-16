{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3TokenNode, a token in a chain of the       }
{  precompiler of Quake III Arena                                              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software), code\botlib\    }
{  l_precomp.c (token_t with its "next" pointer). Licensed under the GNU       }
{  General Public License, version 2 or later.                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.TokenNode;

interface

uses
  DelphiDoom.Scanner.Q3.Types;

type
  /// <summary>
  ///   A token of a chain (the tokens of a define, of its parameters, of the tokens read ahead). The chain
  ///   is a linked list as in the C: it is walked with Next, and freed with FreeChain
  /// </summary>
  TQ3TokenNode = class sealed
  public
    Token: TQ3Token;
    Next: TQ3TokenNode;
    /// <summary>PC_CopyToken: a copy of the token, not linked</summary>
    constructor CreateCopy(const AToken: TQ3Token);
    /// <summary>Frees the node and everything after it, and sets the head to nil</summary>
    class procedure FreeChain(var AHead: TQ3TokenNode); static;
    /// <summary>A copy of the whole chain</summary>
    class function CopyChain(const AHead: TQ3TokenNode): TQ3TokenNode; static;
  end;

implementation

{ TQ3TokenNode }

constructor TQ3TokenNode.CreateCopy(const AToken: TQ3Token);
begin
  inherited Create;
  Token := AToken;
  Next := nil;
end;

class procedure TQ3TokenNode.FreeChain(var AHead: TQ3TokenNode);
var
  LNode: TQ3TokenNode;
  LNext: TQ3TokenNode;
begin
  LNode := AHead;
  AHead := nil;
  while LNode <> nil do
  begin
    LNext := LNode.Next;
    LNode.Free;
    LNode := LNext;
  end;
end;

class function TQ3TokenNode.CopyChain(const AHead: TQ3TokenNode): TQ3TokenNode;
var
  LNode: TQ3TokenNode;
  LLast: TQ3TokenNode;
  LCopy: TQ3TokenNode;
begin
  Result := nil;
  LLast := nil;
  LNode := AHead;
  while LNode <> nil do
  begin
    LCopy := TQ3TokenNode.CreateCopy(LNode.Token);
    if LLast <> nil then
      LLast.Next := LCopy
    else
      Result := LCopy;
    LLast := LCopy;
    LNode := LNode.Next;
  end;
end;

end.
