{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - the memory of the buffers                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.Memory;

interface

type
  /// <summary>
  ///   The blocks that the library gives away and takes back, from the memory manager
  ///   of Delphi, which is the one behind malloc, realloc and free of the C runtime of
  ///   the engine. A block that cannot be had is nil, not an exception: the library
  ///   is called from C code that does not know exceptions
  /// </summary>
  TOggMemory = class
  public
    /// <summary>A block of ASize bytes, filled with zeros like the malloc of the engine</summary>
    class function Allocate(const ASize: NativeInt): Pointer; static;

    /// <summary>Changes the size of a block; the old one is still valid when the result is nil</summary>
    class function Reallocate(const ABlock: Pointer; const ASize: NativeInt): Pointer; static;

    /// <summary>Gives a block back; nil is allowed</summary>
    class procedure Release(const ABlock: Pointer); static;
  end;

implementation

uses
  System.SysUtils;

{ TOggMemory }

class function TOggMemory.Allocate(const ASize: NativeInt): Pointer;
begin
  try
    Result := AllocMem(ASize);
  except
    on EOutOfMemory do
      Result := nil;
  end;
end;

class function TOggMemory.Reallocate(const ABlock: Pointer; const ASize: NativeInt): Pointer;
begin
  if not Assigned(ABlock) then
    Exit(Allocate(ASize));
  Result := ABlock;
  try
    ReallocMem(Result, ASize);
  except
    on EOutOfMemory do
      Result := nil;
  end;
end;

class procedure TOggMemory.Release(const ABlock: Pointer);
begin
  if Assigned(ABlock) then
    FreeMem(ABlock);
end;

end.
