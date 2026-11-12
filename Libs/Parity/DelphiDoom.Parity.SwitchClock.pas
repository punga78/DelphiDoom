{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the clock that is real or virtual              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.SwitchClock;

interface

uses
  DelphiDoom.Clock.Intf,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.VirtualClock;

type
  /// <summary>
  ///   The clock of the engine when the parity tools may be on: as long as they are off every call goes to
  ///   the real clock (nothing changes); when they are on, to the virtual one. The command line is read
  ///   after the clock is made, so the choice is made at every call (a reading of a boolean)
  /// </summary>
  TParitySwitchClock = class(TInterfacedObject, IClock)
  strict private
    FReal: IClock;
    FVirtual: TParityVirtualClock;
    FVirtualRef: IClock;
    FSwitch: IParitySwitch;
    function Current: IClock;
  public
    /// <summary>ARate: the tics in a second of the game (35)</summary>
    constructor Create(const AReal: IClock; const ASwitch: IParitySwitch; ARate: Integer);
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
    /// <summary>The end of a frame: the virtual clock goes on by one tic (nothing if the tools are off)</summary>
    procedure AdvanceFrame;
    /// <summary>The tics of the virtual clock</summary>
    function VirtualTics: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TParitySwitchClock }

constructor TParitySwitchClock.Create(const AReal: IClock; const ASwitch: IParitySwitch; ARate: Integer);
begin
  inherited Create;
  if not Assigned(AReal) then
    raise EArgumentNilException.Create('AReal');
  if not Assigned(ASwitch) then
    raise EArgumentNilException.Create('ASwitch');
  FReal := AReal;
  FSwitch := ASwitch;
  FVirtual := TParityVirtualClock.Create(ARate);
  FVirtualRef := FVirtual;
end;

function TParitySwitchClock.Current: IClock;
begin
  if FSwitch.IsActive then
    Result := FVirtualRef
  else
    Result := FReal;
end;

function TParitySwitchClock.Seconds: Double;
begin
  Result := Current.Seconds;
end;

function TParitySwitchClock.Steps(ARate: Integer): Integer;
begin
  Result := Current.Steps(ARate);
end;

function TParitySwitchClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := Current.ScaledSteps(ARate, AScale);
end;

procedure TParitySwitchClock.Sleep(AMilliseconds: Integer);
begin
  Current.Sleep(AMilliseconds);
end;

procedure TParitySwitchClock.Wait(AMilliseconds: Integer);
begin
  Current.Wait(AMilliseconds);
end;

procedure TParitySwitchClock.AdvanceFrame;
begin
  if FSwitch.IsActive then
    FVirtual.AdvanceFrame;
end;

function TParitySwitchClock.VirtualTics: Integer;
begin
  Result := FVirtual.Tics;
end;

end.
