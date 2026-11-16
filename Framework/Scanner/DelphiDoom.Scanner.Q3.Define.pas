{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3Define, a macro of the precompiler of      }
{  Quake III Arena                                                             }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c (define_t, PC_CopyDefine, PC_FindDefineParm, PC_FreeDefine).    }
{  Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU General    }
{  Public License, version 2 or later.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Define;

interface

uses
  DelphiDoom.Scanner.Q3.TokenNode;

type
  /// <summary>A macro: the name, the flags, the parameters and the tokens it expands to</summary>
  TQ3Define = class sealed
  public
    Name: AnsiString;
    Flags: Integer;
    /// <summary>more than zero for a builtin define (__LINE__...)</summary>
    Builtin: Integer;
    NumParms: Integer;
    /// <summary>define parameters (owned)</summary>
    Parms: TQ3TokenNode;
    /// <summary>macro tokens, possibly with parameter tokens (owned)</summary>
    Tokens: TQ3TokenNode;
    /// <summary>next define in a list (the list of the global defines)</summary>
    Next: TQ3Define;
    /// <summary>next define in the hash chain</summary>
    HashNext: TQ3Define;
    destructor Destroy; override;
    /// <summary>PC_CopyDefine: a copy that is not linked</summary>
    function Copy: TQ3Define;
    /// <summary>PC_FindDefineParm: the number of the parameter with the name, -1 if none</summary>
    function FindParm(const AName: AnsiString): Integer;
  end;

implementation

{ TQ3Define }

destructor TQ3Define.Destroy;
begin
  TQ3TokenNode.FreeChain(Parms);
  TQ3TokenNode.FreeChain(Tokens);
  inherited;
end;

function TQ3Define.Copy: TQ3Define;
begin
  Result := TQ3Define.Create;
  Result.Name := Name;
  Result.Flags := Flags;
  Result.Builtin := Builtin;
  Result.NumParms := NumParms;
  Result.Tokens := TQ3TokenNode.CopyChain(Tokens);
  Result.Parms := TQ3TokenNode.CopyChain(Parms);
end;

function TQ3Define.FindParm(const AName: AnsiString): Integer;
var
  LNode: TQ3TokenNode;
begin
  Result := 0;
  LNode := Parms;
  while LNode <> nil do
  begin
    if LNode.Token.Text = AName then
      Exit;
    Inc(Result);
    LNode := LNode.Next;
  end;
  Result := -1;
end;

end.
