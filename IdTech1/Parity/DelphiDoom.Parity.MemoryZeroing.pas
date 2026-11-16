{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - memory that starts at zero                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.MemoryZeroing;

interface

type
  /// <summary>
  ///   Makes every block that GetMem gives start at zero. The engine reads some memory it never wrote (the
  ///   columns of a texture whose patch is not in the WAD, for example): a hole shows what the block held
  ///   before, so two runs draw other pixels. With zeroed blocks they draw the same. It is only for the runs of
  ///   the parity tools: it slows every allocation down
  /// </summary>
  TParityMemoryZeroing = class
  public
    /// <summary>The blocks given from now on are zeroed (once: a second call does nothing)</summary>
    class procedure Install; static;
    /// <summary>The memory manager as it was before Install</summary>
    class procedure Uninstall; static;
    class function IsInstalled: Boolean; static;
  end;

implementation

const
  // the engine sometimes reads a few bytes after the end of a block (a column of a texture that is not 128 high):
  // with some zeros after every block it reads zeros, not what the next block holds
  OVERREAD_PADDING = 512;

var
  GInstalled: Boolean = False;
  GPrevious: TMemoryManagerEx;

function ZeroedGetMem(ASize: NativeInt): Pointer;
begin
  Result := GPrevious.GetMem(ASize + OVERREAD_PADDING);
  if Result <> nil then
    FillChar(Result^, ASize + OVERREAD_PADDING, 0);
end;

class procedure TParityMemoryZeroing.Install;
var
  LManager: TMemoryManagerEx;
begin
  if GInstalled then
    Exit;
  GetMemoryManager(GPrevious);
  LManager := GPrevious;
  LManager.GetMem := ZeroedGetMem;
  SetMemoryManager(LManager);
  GInstalled := True;
end;

class procedure TParityMemoryZeroing.Uninstall;
begin
  if not GInstalled then
    Exit;
  SetMemoryManager(GPrevious);
  GInstalled := False;
end;

class function TParityMemoryZeroing.IsInstalled: Boolean;
begin
  Result := GInstalled;
end;

end.
