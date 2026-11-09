{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - progress of a long job                      }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.ProgressReporter;

interface

uses
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   Counts the steps of a job and tells an observer the percentage when it changes. The
  ///   observer is optional: without it the reporter only counts (and can still be cancelled)
  /// </summary>
  TProgressReporter = class(TInterfacedObject, IProgressReporter)
  strict private
    FObserver: IProgressObserver;
    FText: string;
    FTotal: Integer;
    FDone: Integer;
    FPercent: Integer;
    FCancelled: Boolean;
    procedure Publish(APercent: Integer);
  public
    /// <param name="AObserver">Who is told of the progress; may be nil</param>
    constructor Create(const AObserver: IProgressObserver);
    procedure Start(const AText: string; ATotal: Integer);
    procedure Advance(AStep: Integer);
    procedure Finish;
    procedure Cancel;
    function IsCancelled: Boolean;
    function Percent: Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Tools.Types;

{ TProgressReporter }

constructor TProgressReporter.Create(const AObserver: IProgressObserver);
begin
  inherited Create;
  FObserver := AObserver;
end;

procedure TProgressReporter.Publish(APercent: Integer);
begin
  if APercent < 0 then
    APercent := 0
  else if APercent > 100 then
    APercent := 100;
  if APercent = FPercent then
    Exit;
  FPercent := APercent;
  if Assigned(FObserver) then
    FObserver.ProgressChanged(FText, FPercent);
end;

procedure TProgressReporter.Start(const AText: string; ATotal: Integer);
begin
  if ATotal < 0 then
    raise EToolsException.CreateFmt(SToolsBadProgressTotal, [ATotal]);
  FText := AText;
  FTotal := ATotal;
  FDone := 0;
  FCancelled := False;
  FPercent := -1;
  Publish(0);
end;

procedure TProgressReporter.Advance(AStep: Integer);
begin
  Inc(FDone, AStep);
  // a job without a known length has no percentage until it ends
  if FTotal > 0 then
    Publish(Round(FDone * 100 / FTotal));
end;

procedure TProgressReporter.Finish;
begin
  Publish(100);
end;

procedure TProgressReporter.Cancel;
begin
  FCancelled := True;
end;

function TProgressReporter.IsCancelled: Boolean;
begin
  Result := FCancelled;
end;

function TProgressReporter.Percent: Integer;
begin
  if FPercent < 0 then
    Result := 0
  else
    Result := FPercent;
end;

end.
