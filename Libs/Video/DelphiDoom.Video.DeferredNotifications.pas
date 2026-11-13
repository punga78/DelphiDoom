{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - notifications done between two frames           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.DeferredNotifications;

interface

uses
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   Port of d_notifications.pas: remembers a request for a new display mode and one for the
  ///   OpenGL window, and does them in Run. Two requests of a mode before Run make one change,
  ///   with the last size. Run is called once per tic.
  /// </summary>
  TDeferredNotifications = class(TInterfacedObject, IDeferredNotifications)
  strict private
    FApplier: IDisplayModeApplier;
    FChangeVideoMode: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FNotifyGLWindow: Boolean;
  public
    /// <summary>EArgumentNilException if AApplier is nil</summary>
    constructor Create(const AApplier: IDisplayModeApplier);
    procedure NotifyVideoModeChange(AWidth, AHeight: Integer);
    procedure NotifyGLDisplayMode;
    procedure Run;
  end;

implementation

uses
  System.SysUtils;

{ TDeferredNotifications }

constructor TDeferredNotifications.Create(const AApplier: IDisplayModeApplier);
begin
  inherited Create;
  if not Assigned(AApplier) then
    raise EArgumentNilException.Create('AApplier');
  FApplier := AApplier;
end;

procedure TDeferredNotifications.NotifyVideoModeChange(AWidth, AHeight: Integer);
begin
  FChangeVideoMode := True;
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TDeferredNotifications.NotifyGLDisplayMode;
begin
  FNotifyGLWindow := True;
end;

procedure TDeferredNotifications.Run;
begin
  if FChangeVideoMode then
  begin
    FApplier.ApplyDisplayMode(FWidth, FHeight);
    FChangeVideoMode := False;
  end;
  if FNotifyGLWindow then
  begin
    FApplier.ApplyGLDisplayMode;
    FNotifyGLWindow := False;
  end;
end;

end.
