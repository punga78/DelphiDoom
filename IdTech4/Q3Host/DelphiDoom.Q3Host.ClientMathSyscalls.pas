{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - CG_ACOS                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c       }
{  (CG_ACOS) and qcommon\common.c (Q_acos). Copyright (C) 1999-2005 Id          }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientMathSyscalls;

interface

uses
  DelphiDoom.Q3Host.Intf;

type
  /// <summary>
  ///   CG_ACOS: FloatAsInt( Q_acos( VMF(1) ) ). Q_acos is acos of the float widened to a double, narrowed to a float
  ///   (the tests against pi never change the value: acos is between 0 and pi, and the float nearest to pi is the
  ///   one that is returned). A value out of -1..1 is the negative quiet NaN the C library gives (0xFFC00000), a
  ///   NaN is itself; equal to the C on Tests\Data\Q3Host\acos.golden.txt
  /// </summary>
  TQ3ClientMathSyscalls = class
  public
    class procedure Register(const ARegistry: IQ3SyscallRegistry); static;
    /// <summary>Q_acos</summary>
    class function Acos(AValue: Single): Single; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

class function TQ3ClientMathSyscalls.Acos(AValue: Single): Single;
begin
  if IsNaN(AValue) then
    Exit(AValue);
  if Abs(AValue) > 1 then
  begin
    PCardinal(@Result)^ := $FFC00000;
    Exit;
  end;
  Result := ArcCos(Double(AValue));
end;

class procedure TQ3ClientMathSyscalls.Register(const ARegistry: IQ3SyscallRegistry);
begin
  ARegistry.Register(CG_ACOS,
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    begin
      Result := TQ3SyscallArguments.FromSingle(Acos(TQ3SyscallArguments.ToSingle(AArgs[1])));
    end);
end;

end.
