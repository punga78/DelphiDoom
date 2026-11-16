{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - undo and redo of a document                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.UndoHistory;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   Undo and redo as two stacks of snapshots of the document. It replaces the undo managers of
  ///   the three tools (ee_undo, ff_undo, vxe_undo: a stack of compressed memory or file streams,
  ///   with a callback that saved and loaded the document): the rules are the same, the undo stack
  ///   keeps the last ALimit snapshots and a new snapshot clears the redo stack. The snapshots are
  ///   copied, so the caller can go on changing its buffer
  /// </summary>
  TToolUndoHistory = class(TInterfacedObject, IToolUndoHistory)
  strict private
    FUndo: TList<TBytes>;
    FRedo: TList<TBytes>;
    FLimit: Integer;
    class function CopyOf(const ABytes: TBytes): TBytes; static;
    procedure PushUndo(const ABytes: TBytes);
  public
    /// <param name="ALimit">Snapshots kept for the undo; 0 means no limit</param>
    constructor Create(ALimit: Integer);
    destructor Destroy; override;
    procedure Clear;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    procedure Save(const ACurrent: TBytes);
    function Undo(const ACurrent: TBytes): TBytes;
    function Redo(const ACurrent: TBytes): TBytes;
  end;

implementation

uses
  DelphiDoom.Tools.Types;

{ TToolUndoHistory }

constructor TToolUndoHistory.Create(ALimit: Integer);
begin
  inherited Create;
  if ALimit < 0 then
    raise EToolsException.CreateFmt(SToolsBadLimit, [ALimit]);
  FLimit := ALimit;
  FUndo := TList<TBytes>.Create;
  FRedo := TList<TBytes>.Create;
end;

destructor TToolUndoHistory.Destroy;
begin
  FRedo.Free;
  FUndo.Free;
  inherited Destroy;
end;

class function TToolUndoHistory.CopyOf(const ABytes: TBytes): TBytes;
begin
  Result := Copy(ABytes, 0, Length(ABytes));
end;

procedure TToolUndoHistory.PushUndo(const ABytes: TBytes);
begin
  FUndo.Add(CopyOf(ABytes));
  if (FLimit > 0) and (FUndo.Count > FLimit) then
    FUndo.Delete(0);
end;

procedure TToolUndoHistory.Clear;
begin
  FUndo.Clear;
  FRedo.Clear;
end;

function TToolUndoHistory.CanUndo: Boolean;
begin
  Result := FUndo.Count > 0;
end;

function TToolUndoHistory.CanRedo: Boolean;
begin
  Result := FRedo.Count > 0;
end;

procedure TToolUndoHistory.Save(const ACurrent: TBytes);
begin
  PushUndo(ACurrent);
  FRedo.Clear;
end;

function TToolUndoHistory.Undo(const ACurrent: TBytes): TBytes;
begin
  Result := CopyOf(ACurrent);
  if not CanUndo then
    Exit;
  FRedo.Add(CopyOf(ACurrent));
  Result := FUndo[FUndo.Count - 1];
  FUndo.Delete(FUndo.Count - 1);
end;

function TToolUndoHistory.Redo(const ACurrent: TBytes): TBytes;
begin
  Result := CopyOf(ACurrent);
  if not CanRedo then
    Exit;
  PushUndo(ACurrent);
  Result := FRedo[FRedo.Count - 1];
  FRedo.Delete(FRedo.Count - 1);
end;

end.
