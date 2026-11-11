{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom program - the return addresses on the stack when an         }
{  exception is raised, in the terms of the .map file                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.StackScan;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Keeps, for every exception, the words of the stack that look like return addresses into the code of the
  ///   executable (the word points just after a CALL instruction), read when the exception is raised. It is not a
  ///   real stack walk: some addresses can be leftovers of older calls, but the real callers are all there, the
  ///   nearest first. Install hooks the three procedures of Exception; without Install nothing changes
  /// </summary>
  TXcomStackScan = class
  strict private
    const
      MAX_ADDRESSES = 48;
    type
      TAddresses = array[0..MAX_ADDRESSES] of NativeUInt;
      PAddresses = ^TAddresses;
    class var
      FCodeStart: NativeUInt;
      FCodeEnd: NativeUInt;
    class function Capture(ARecord: System.PExceptionRecord): Pointer; static;
    class function Describe(AInfo: Pointer): string; static;
    class procedure Release(AInfo: Pointer); static;
    class function LooksLikeReturn(AAddress: NativeUInt): Boolean; static;
  public
    /// <summary>Hooks Exception.GetExceptionStackInfoProc and its two companions</summary>
    class procedure Install; static;
    /// <summary>The addresses of the exception as the .map file writes them (image base 00400000), one per word</summary>
    class function MapAddresses(AException: Exception): string; static;
  end;

implementation

uses
  Winapi.Windows;

class procedure TXcomStackScan.Install;
var
  LDos: PImageDosHeader;
  LNt: PImageNtHeaders;
begin
  LDos := PImageDosHeader(HInstance);
  LNt := PImageNtHeaders(NativeUInt(HInstance) + NativeUInt(LDos^._lfanew));
  FCodeStart := NativeUInt(HInstance) + LNt^.OptionalHeader.BaseOfCode;
  FCodeEnd := FCodeStart + LNt^.OptionalHeader.SizeOfCode;
  Exception.GetExceptionStackInfoProc := Capture;
  Exception.GetStackInfoStringProc := Describe;
  Exception.CleanUpStackInfoProc := Release;
end;

class function TXcomStackScan.LooksLikeReturn(AAddress: NativeUInt): Boolean;
var
  LCode: PByte;
begin
  Result := False;
  if (AAddress < FCodeStart + 7) or (AAddress >= FCodeEnd) then
    Exit;
  LCode := PByte(AAddress);
  // CALL rel32 (E8), CALL through a register or memory (FF /2: two, three or six bytes)
  if PByte(NativeUInt(LCode) - 5)^ = $E8 then
    Exit(True);
  if (PByte(NativeUInt(LCode) - 2)^ = $FF) and ((PByte(NativeUInt(LCode) - 1)^ and $38) = $10) then
    Exit(True);
  if (PByte(NativeUInt(LCode) - 3)^ = $FF) and ((PByte(NativeUInt(LCode) - 2)^ and $38) = $10) then
    Exit(True);
  if (PByte(NativeUInt(LCode) - 6)^ = $FF) and ((PByte(NativeUInt(LCode) - 5)^ and $38) = $10) then
    Exit(True);
end;

class function TXcomStackScan.Capture(ARecord: System.PExceptionRecord): Pointer;
var
  LAddresses: PAddresses;
  LInfo: TMemoryBasicInformation;
  LWord: PNativeUInt;
  LTop: NativeUInt;
  LCount: Integer;
  LMarker: NativeUInt;
begin
  New(LAddresses);
  FillChar(LAddresses^, SizeOf(TAddresses), 0);
  Result := LAddresses;
  LCount := 0;
  // the stack goes from this local up to the end of its region of committed memory
  LWord := @LMarker;
  if VirtualQuery(LWord, LInfo, SizeOf(LInfo)) = 0 then
    Exit;
  LTop := NativeUInt(LInfo.BaseAddress) + LInfo.RegionSize;
  while (NativeUInt(LWord) + SizeOf(NativeUInt) <= LTop) and (LCount < MAX_ADDRESSES) do
  begin
    if LooksLikeReturn(LWord^) then
    begin
      LAddresses^[LCount] := LWord^;
      Inc(LCount);
    end;
    Inc(LWord);
  end;
end;

class function TXcomStackScan.Describe(AInfo: Pointer): string;
var
  LAddresses: PAddresses;
  LIndex: Integer;
begin
  Result := '';
  LAddresses := AInfo;
  if LAddresses = nil then
    Exit;
  LIndex := 0;
  while (LIndex < MAX_ADDRESSES) and (LAddresses^[LIndex] <> 0) do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + IntToHex(LAddresses^[LIndex] - NativeUInt(HInstance) + $400000, 8);
    Inc(LIndex);
  end;
end;

class procedure TXcomStackScan.Release(AInfo: Pointer);
begin
  if AInfo <> nil then
    Dispose(PAddresses(AInfo));
end;

class function TXcomStackScan.MapAddresses(AException: Exception): string;
begin
  Result := AException.StackTrace;
end;

end.
