{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - real time and snap vector              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,      }
{  cl_cgame.c, cl_ui.c (G_REAL_TIME, G_SNAPVECTOR and their twins) and         }
{  Sys_SnapVector of win_shared.c. Copyright (C) 1999-2005 Id Software, Inc.   }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.MiscSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   G_REAL_TIME, CG_REAL_TIME, UI_REAL_TIME (Com_RealTime: the calendar fills the 36 bytes of qtime_t and the
  ///   seconds since 1970 are the result) and G_SNAPVECTOR, CG_SNAPVECTOR (Sys_SnapVector: every component to the
  ///   nearest integer, ties to even as the x87 does, a value outside 32 bits becomes -2^31 as fistp's
  ///   "integer indefinite")
  /// </summary>
  TQ3MiscSyscalls = class
  public
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
      const ACalendar: IQ3HostCalendar); static;
    /// <summary>The snapped value of one component (the fistp of the C, then back to a float)</summary>
    class function Snap(AValue: Single): Single; static;
  end;

implementation

uses
  System.Math, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments;

const
  NONE = -1;

class function TQ3MiscSyscalls.Snap(AValue: Single): Single;
begin
  if IsNaN(AValue) or (Abs(AValue) >= 2147483648.0) then
    Exit(-2147483648.0);
  Result := Round(Double(AValue));
end;

class procedure TQ3MiscSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const ACalendar: IQ3HostCalendar);
const
  REAL_TIME: array[TQ3Module] of Integer = (G_REAL_TIME, CG_REAL_TIME, UI_REAL_TIME);
  SNAP_VECTOR: array[TQ3Module] of Integer = (G_SNAPVECTOR, CG_SNAPVECTOR, NONE);
begin
  ARegistry.Register(REAL_TIME[AModule],
    function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
    var
      LTime: TQ3HostRealTime;
    begin
      Result := ACalendar.RealTime(LTime);
      // a null qtime_t only asks for the seconds
      if AArgs[1] <> 0 then
      begin
        AMachine.Memory.WriteInt32(AArgs[1], LTime.Second);
        AMachine.Memory.WriteInt32(AArgs[1] + 4, LTime.Minute);
        AMachine.Memory.WriteInt32(AArgs[1] + 8, LTime.Hour);
        AMachine.Memory.WriteInt32(AArgs[1] + 12, LTime.DayOfMonth);
        AMachine.Memory.WriteInt32(AArgs[1] + 16, LTime.Month);
        AMachine.Memory.WriteInt32(AArgs[1] + 20, LTime.Year);
        AMachine.Memory.WriteInt32(AArgs[1] + 24, LTime.DayOfWeek);
        AMachine.Memory.WriteInt32(AArgs[1] + 28, LTime.DayOfYear);
        AMachine.Memory.WriteInt32(AArgs[1] + 32, LTime.IsDst);
      end;
    end);

  if SNAP_VECTOR[AModule] <> NONE then
    ARegistry.Register(SNAP_VECTOR[AModule],
      function(const AMachine: IQvmMachine; const AArgs: TQvmSystemCallArguments): Integer
      var
        LIndex: Integer;
      begin
        for LIndex := 0 to 2 do
          AMachine.Memory.WriteInt32(AArgs[1] + 4 * LIndex, TQ3SyscallArguments.FromSingle(
            Snap(TQ3SyscallArguments.ToSingle(AMachine.Memory.ReadInt32(AArgs[1] + 4 * LIndex)))));
        Result := 0;
      end);
end;

end.
