{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the factory: the composition root              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Factory;

interface

uses
  DelphiDoom.Clock.Intf,
  DelphiDoom.Parity.FrameHashWriter,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.SwitchClock,
  DelphiDoom.Parity.Types;

type
  /// <summary>The only place that knows the classes behind the contracts of the parity library</summary>
  TParityFactory = class
  public
    /// <summary>A log in a text file (overwritten); EParityException if it cannot be created</summary>
    class function CreateFileLog(const AFileName: string): IParityLog; static;
    /// <summary>The writer of the state: with the detail of the tics of the range if ADetail</summary>
    class function CreateStateWriter(const ALog: IParityLog; ADetail: Boolean;
      ADetailFirstTic, ADetailLastTic: Integer): IParityStateSink; static;
    /// <summary>The writer of the hashes of the frames (the caller owns it)</summary>
    class function CreateFrameWriter(const ALog: IParityLog): TFrameHashWriter; static;
    /// <summary>The pilot of the options (-autodemo)</summary>
    class function CreatePilot(const AOptions: TParityOptions): IParityPilot; static;
    /// <summary>The clock that is the real one until ASwitch says that the tools are on</summary>
    class function CreateSwitchClock(const AReal: IClock; const ASwitch: IParitySwitch;
      ARate: Integer): TParitySwitchClock; static;
  end;

implementation

uses
  DelphiDoom.Parity.FileLog,
  DelphiDoom.Parity.Pilot,
  DelphiDoom.Parity.StateHashWriter;

{ TParityFactory }

class function TParityFactory.CreateFileLog(const AFileName: string): IParityLog;
begin
  Result := TParityFileLog.Create(AFileName);
end;

class function TParityFactory.CreateStateWriter(const ALog: IParityLog; ADetail: Boolean;
  ADetailFirstTic, ADetailLastTic: Integer): IParityStateSink;
begin
  Result := TStateHashWriter.Create(ALog, ADetail, ADetailFirstTic, ADetailLastTic);
end;

class function TParityFactory.CreateFrameWriter(const ALog: IParityLog): TFrameHashWriter;
begin
  Result := TFrameHashWriter.Create(ALog);
end;

class function TParityFactory.CreatePilot(const AOptions: TParityOptions): IParityPilot;
begin
  Result := TParityPilot.Create(AOptions.AutoDemoSeed, AOptions.AutoDemoTics);
end;

class function TParityFactory.CreateSwitchClock(const AReal: IClock; const ASwitch: IParitySwitch;
  ARate: Integer): TParitySwitchClock;
begin
  Result := TParitySwitchClock.Create(AReal, ASwitch, ARate);
end;

end.
