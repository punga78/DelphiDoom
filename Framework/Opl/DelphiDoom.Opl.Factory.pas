{******************************************************************************}
{                                                                              }
{  DelphiDoom: OPL2 (YM3812) library - the factory: the composition root        }
{                                                                              }
{  Port of fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later)            }
{  See DelphiDoom.Opl.Types for the copyright notice                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Opl.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf, DelphiDoom.Opl.Tables, DelphiDoom.Opl.Noise,
  DelphiDoom.Opl.Chip;

type
  /// <summary>The only place that knows the classes of the OPL library</summary>
  TOplFactory = class
  strict private
    class var FSharedTables: IOplTables;
    class var FLock: TObject;
    class function SharedTables: IOplTables; static;
  public
    class constructor Create;
    class destructor Destroy;
    /// <summary>
    ///   The tables all the chips of the process can share (built the first time they are asked for, as the C builds
    ///   them with the first chip). Chips given the same tables share the "current chip" of the C globals
    /// </summary>
    class function CreateTables: IOplTables; static;
    /// <summary>
    ///   A YM3812 chip with the shared tables and the noise of rand() of the Windows C library started from the seed
    /// </summary>
    class function CreateChip(AClock, ARate: Integer; ANoiseSeed: Cardinal = 1): IOplChip; overload; static;
    /// <summary>A chip with the parts given (other tables, other noise, another chip type)</summary>
    class function CreateChip(const ATables: IOplTables; const ANoise: IOplNoiseSource; AChipType: TOplChipType;
      AClock, ARate: Integer): IOplChip; overload; static;
  end;

implementation

{ TOplFactory }

class constructor TOplFactory.Create;
begin
  FLock := TObject.Create;
end;

class destructor TOplFactory.Destroy;
begin
  FSharedTables := nil;
  FLock.Free;
end;

class function TOplFactory.SharedTables: IOplTables;
begin
  TMonitor.Enter(FLock);
  try
    if not Assigned(FSharedTables) then
      FSharedTables := TOplTables.Create;
    Result := FSharedTables;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function TOplFactory.CreateTables: IOplTables;
begin
  Result := TOplTables.Create;
end;

class function TOplFactory.CreateChip(AClock, ARate: Integer; ANoiseSeed: Cardinal): IOplChip;
begin
  Result := TOplChip.Create(SharedTables, TOplMsvcrtNoise.Create(ANoiseSeed), octYm3812, AClock, ARate);
end;

class function TOplFactory.CreateChip(const ATables: IOplTables; const ANoise: IOplNoiseSource;
  AChipType: TOplChipType; AClock, ARate: Integer): IOplChip;
begin
  Result := TOplChip.Create(ATables, ANoise, AChipType, AClock, ARate);
end;

end.
