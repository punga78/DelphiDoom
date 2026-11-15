{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3GlobalDefines, the defines added to every  }
{  source of Quake III Arena                                                   }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c (globaldefines, PC_AddGlobalDefine, PC_RemoveGlobalDefine,      }
{  PC_RemoveAllGlobalDefines, PC_AddGlobalDefinesToSource). Copyright (C)      }
{  1999-2005 Id Software, Inc. Licensed under the GNU General Public License,  }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.GlobalDefines;

interface

uses
  DelphiDoom.Scanner.Q3.Define, DelphiDoom.Scanner.Q3.DefineHash;

type
  /// <summary>
  ///   The list of the global defines (a global of the C: here an object that the sources get). A new
  ///   define goes at the head of the list. It owns the defines
  /// </summary>
  TQ3GlobalDefines = class sealed
  strict private
    FHead: TQ3Define;
  public
    destructor Destroy; override;
    /// <summary>The second half of PC_AddGlobalDefine: puts a define at the head (nil is ignored)</summary>
    procedure Add(const ADefine: TQ3Define);
    /// <summary>
    ///   PC_RemoveGlobalDefine: takes the define with the name out of the list and frees it. (The C frees it
    ///   but leaves it linked: the next walk of the list reads freed memory)
    /// </summary>
    function Remove(const AName: AnsiString): Boolean;
    /// <summary>PC_RemoveAllGlobalDefines</summary>
    procedure Clear;
    /// <summary>PC_AddGlobalDefinesToSource: a copy of every global define goes into the hash table</summary>
    procedure AddTo(const AHash: TQ3DefineHash);
    function Count: Integer;
  end;

implementation

{ TQ3GlobalDefines }

destructor TQ3GlobalDefines.Destroy;
begin
  Clear;
  inherited;
end;

procedure TQ3GlobalDefines.Add(const ADefine: TQ3Define);
begin
  if ADefine = nil then
    Exit;
  ADefine.Next := FHead;
  FHead := ADefine;
end;

function TQ3GlobalDefines.Remove(const AName: AnsiString): Boolean;
var
  LDefine: TQ3Define;
  LLast: TQ3Define;
begin
  LLast := nil;
  LDefine := FHead;
  while LDefine <> nil do
  begin
    if LDefine.Name = AName then
    begin
      if LLast <> nil then
        LLast.Next := LDefine.Next
      else
        FHead := LDefine.Next;
      LDefine.Free;
      Exit(True);
    end;
    LLast := LDefine;
    LDefine := LDefine.Next;
  end;
  Result := False;
end;

procedure TQ3GlobalDefines.Clear;
var
  LDefine: TQ3Define;
begin
  while FHead <> nil do
  begin
    LDefine := FHead;
    FHead := FHead.Next;
    LDefine.Free;
  end;
end;

procedure TQ3GlobalDefines.AddTo(const AHash: TQ3DefineHash);
var
  LDefine: TQ3Define;
begin
  LDefine := FHead;
  while LDefine <> nil do
  begin
    AHash.Add(LDefine.Copy);
    LDefine := LDefine.Next;
  end;
end;

function TQ3GlobalDefines.Count: Integer;
var
  LDefine: TQ3Define;
begin
  Result := 0;
  LDefine := FHead;
  while LDefine <> nil do
  begin
    Inc(Result);
    LDefine := LDefine.Next;
  end;
end;

end.
