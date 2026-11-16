{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the arguments of a system call          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): VMA, VMF,        }
{  PASSFLOAT and FloatAsInt of sv_game.c and cl_cgame.c. Copyright (C)          }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena    }
{  source code and is therefore available under the GNU General Public          }
{  License, version 2 or (at your option) any later version.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Arguments;

interface

uses
  DelphiDoom.Qvm.Intf;

type
  /// <summary>
  ///   How a handler reads what the program passed: floats travel as the bits of a 32 bit integer (VMF and
  ///   PASSFLOAT), a pointer is an address in the data of the program (VMA)
  /// </summary>
  TQ3SyscallArguments = class
  public
    /// <summary>VMF: the argument as a float</summary>
    class function ToSingle(AValue: Integer): Single; static; inline;
    /// <summary>FloatAsInt: the bits of a float, as the result of a system call</summary>
    class function FromSingle(AValue: Single): Integer; static; inline;
    /// <summary>
    ///   VMA of a string: the bytes up to the zero. A null address is an error for the C (it would read the
    ///   address 0 of the host); here it raises EQ3HostException with the name of the call
    /// </summary>
    class function Text(const AMachine: IQvmMachine; AAddress: Integer; const ACall: string): AnsiString; static;
    /// <summary>
    ///   VMA of a buffer of ALength bytes: a host pointer to the bytes, all inside the data of the program
    ///   (EQvmExecutionException otherwise; the C masks the address and then trusts the length)
    /// </summary>
    class function Buffer(const AMachine: IQvmMachine; AAddress: Integer; ALength: Integer): PByte; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Q3Host.Types;

class function TQ3SyscallArguments.ToSingle(AValue: Integer): Single;
begin
  Result := PSingle(@AValue)^;
end;

class function TQ3SyscallArguments.FromSingle(AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

class function TQ3SyscallArguments.Text(const AMachine: IQvmMachine; AAddress: Integer;
  const ACall: string): AnsiString;
begin
  if AAddress = 0 then
    raise EQ3HostException.CreateFmt(SQ3NullStringArgument, [ACall]);
  Result := AMachine.Memory.ReadString(AAddress);
end;

class function TQ3SyscallArguments.Buffer(const AMachine: IQvmMachine; AAddress: Integer;
  ALength: Integer): PByte;
begin
  if ALength < 0 then
    ALength := High(Integer);
  Result := PByte(AMachine.Memory.Range(AAddress, ALength));
end;

end.
