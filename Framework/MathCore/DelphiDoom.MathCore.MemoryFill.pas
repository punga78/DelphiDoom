{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the memory fills (memset and friends)       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.MemoryFill;

interface

type
  /// <summary>
  ///   The fills of memory of d_delphi (memset, memsetsi, memseti, FillDWord) in pure Pascal, for
  ///   the targets where the MMX and string-instruction versions are not compiled (64 bit).
  /// </summary>
  /// <remarks>
  ///   They have no state and write only the memory they are asked to write. A count that is
  ///   zero or negative writes nothing. The 32 bit engine keeps the assembler versions (the
  ///   non-temporal stores are meant for the big buffers of the renderer); the tests compare
  ///   both with the same inputs.
  /// </remarks>
  TMemoryFill = class
  public
    /// <summary>Fills ACount bytes with the low byte of AValue (memset)</summary>
    class procedure FillBytes(ADestination: Pointer; AValue: Integer; ACount: Integer); static;
    /// <summary>Fills ACount 16 bit values (memsetsi)</summary>
    class procedure FillWords(ADestination: Pointer; AValue: SmallInt; ACount: Integer); static;
    /// <summary>Fills ACount 32 bit values (memseti and FillDWord)</summary>
    class procedure FillDWords(ADestination: Pointer; ACount: Integer; AValue: Cardinal); static;
  end;

implementation

{ TMemoryFill }

class procedure TMemoryFill.FillBytes(ADestination: Pointer; AValue: Integer; ACount: Integer);
begin
  if ACount > 0 then
    FillChar(ADestination^, ACount, Byte(AValue and $FF));
end;

class procedure TMemoryFill.FillWords(ADestination: Pointer; AValue: SmallInt; ACount: Integer);
var
  LPointer: PSmallInt;
  LIndex: Integer;
begin
  LPointer := PSmallInt(ADestination);
  for LIndex := 1 to ACount do
  begin
    LPointer^ := AValue;
    Inc(LPointer);
  end;
end;

class procedure TMemoryFill.FillDWords(ADestination: Pointer; ACount: Integer; AValue: Cardinal);
var
  LPointer: PCardinal;
  LIndex: Integer;
begin
  LPointer := PCardinal(ADestination);
  for LIndex := 1 to ACount do
  begin
    LPointer^ := AValue;
    Inc(LPointer);
  end;
end;

end.
