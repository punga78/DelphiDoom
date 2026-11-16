{******************************************************************************}
{                                                                              }
{  DelphiDoom: ENDOOM library - the time of the end screen                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Session;

interface

uses
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The counters of E_Ticker and E_Responder of the old e_endoom.pas: the tics since the
  ///   screen was shown, the tic inside the second for the blinking, the phase of the blinking
  ///   (the blinking cells are visible until the first tic, hidden in the first half of every
  ///   second and visible in the second half)
  /// </summary>
  TEndoomSession = class(TInterfacedObject, IEndoomSession)
  private
    FTicRate: Integer;
    FTicks: Integer;
    FTic: Integer;
    FBlinkVisible: Boolean;
    FNeedsRedraw: Boolean;
  public
    /// <param name="ATicRate">The tics in a second (35); raises EArgumentOutOfRangeException below 2</param>
    constructor Create(ATicRate: Integer);
    procedure Start;
    function Tick: Boolean;
    function AcceptsKey: Boolean;
    function IsBlinkVisible: Boolean;
    function NeedsRedraw: Boolean;
    procedure Drawn;
  end;

implementation

uses
  System.SysUtils;

const
  SInvalidTicRate = 'TEndoomSession: the tic rate must be at least 2';
  // the program closes by itself after these seconds
  ENDOOM_SECONDS = 10;

{ TEndoomSession }

constructor TEndoomSession.Create(ATicRate: Integer);
begin
  inherited Create;
  if ATicRate < 2 then
    raise EArgumentOutOfRangeException.Create(SInvalidTicRate);
  FTicRate := ATicRate;
  FBlinkVisible := True;
  FNeedsRedraw := True;
end;

procedure TEndoomSession.Start;
begin
  // as before: the tic of the blinking and its phase go on from where they were
  FTicks := 1;
  FNeedsRedraw := True;
end;

function TEndoomSession.Tick: Boolean;
var
  LBlink: Boolean;
begin
  Result := False;
  if FTicks <= 0 then
    Exit;

  Inc(FTicks);
  Result := FTicks > ENDOOM_SECONDS * FTicRate;
  Inc(FTic);
  if FTic >= FTicRate then
    FTic := 0;
  LBlink := FTic > FTicRate div 2;
  if LBlink <> FBlinkVisible then
  begin
    FBlinkVisible := not FBlinkVisible;
    FNeedsRedraw := True;
  end;
end;

function TEndoomSession.AcceptsKey: Boolean;
begin
  Result := FTicks > FTicRate div 2;
end;

function TEndoomSession.IsBlinkVisible: Boolean;
begin
  Result := FBlinkVisible;
end;

function TEndoomSession.NeedsRedraw: Boolean;
begin
  Result := FNeedsRedraw;
end;

procedure TEndoomSession.Drawn;
begin
  FNeedsRedraw := False;
end;

end.
