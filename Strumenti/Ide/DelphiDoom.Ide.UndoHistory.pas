{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - undo and redo of a document                       }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.UndoHistory;

interface

uses
  System.Generics.Collections;

type
  /// <summary>
  ///   The snapshots of a document for undo and redo. It replaces the old undo manager (stacks
  ///   of compressed temporary files): the rules are the same, the undo stack keeps the last
  ///   IDE_UNDO_LIMIT snapshots and a new snapshot clears the redo stack
  /// </summary>
  TIdeUndoHistory = class
  strict private
    FUndo: TList<AnsiString>;
    FRedo: TList<AnsiString>;
    FLimit: Integer;
  public
    constructor Create(const ALimit: Integer);
    destructor Destroy; override;
    procedure Clear;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    /// <summary>Remembers the state the document has now, before a change</summary>
    procedure Save(const ACurrent: AnsiString);
    /// <summary>Gives the state to go back to; the current one can be redone</summary>
    function Undo(const ACurrent: AnsiString): AnsiString;
    /// <summary>Gives the state to go forward to; the current one can be undone</summary>
    function Redo(const ACurrent: AnsiString): AnsiString;
  end;

implementation

uses
  System.SysUtils;

{ TIdeUndoHistory }

constructor TIdeUndoHistory.Create(const ALimit: Integer);
begin
  inherited Create;
  FLimit := ALimit;
  FUndo := TList<AnsiString>.Create;
  FRedo := TList<AnsiString>.Create;
end;

destructor TIdeUndoHistory.Destroy;
begin
  FRedo.Free;
  FUndo.Free;
  inherited Destroy;
end;

procedure TIdeUndoHistory.Clear;
begin
  FUndo.Clear;
  FRedo.Clear;
end;

function TIdeUndoHistory.CanUndo: Boolean;
begin
  Result := FUndo.Count > 0;
end;

function TIdeUndoHistory.CanRedo: Boolean;
begin
  Result := FRedo.Count > 0;
end;

procedure TIdeUndoHistory.Save(const ACurrent: AnsiString);
begin
  FUndo.Add(ACurrent);
  if (FLimit > 0) and (FUndo.Count > FLimit) then
    FUndo.Delete(0);
  FRedo.Clear;
end;

function TIdeUndoHistory.Undo(const ACurrent: AnsiString): AnsiString;
begin
  Result := ACurrent;
  if not CanUndo then
    Exit;
  FRedo.Add(ACurrent);
  Result := FUndo[FUndo.Count - 1];
  FUndo.Delete(FUndo.Count - 1);
end;

function TIdeUndoHistory.Redo(const ACurrent: AnsiString): AnsiString;
begin
  Result := ACurrent;
  if not CanRedo then
    Exit;
  FUndo.Add(ACurrent);
  if (FLimit > 0) and (FUndo.Count > FLimit) then
    FUndo.Delete(0);
  Result := FRedo[FRedo.Count - 1];
  FRedo.Delete(FRedo.Count - 1);
end;

end.
