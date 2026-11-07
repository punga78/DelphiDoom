{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the priority of the thread                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.WindowsThreadPriority;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   IThreadPriority on SetThreadPriority. It always acts on the thread that calls it
  ///   (GetCurrentThread), and one object remembers one raise at a time
  /// </summary>
  TWindowsThreadPriority = class(TInterfacedObject, IThreadPriority)
  strict private
    FSaved: Integer;
    FRaised: Boolean;
  public
    constructor Create;
    procedure RaiseToCritical;
    procedure Restore;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsThreadPriority }

constructor TWindowsThreadPriority.Create;
begin
  inherited Create;
  FSaved := THREAD_PRIORITY_ERROR_RETURN;
  FRaised := False;
end;

procedure TWindowsThreadPriority.RaiseToCritical;
begin
  if not FRaised then
  begin
    FSaved := GetThreadPriority(GetCurrentThread);
    if FSaved <> THREAD_PRIORITY_ERROR_RETURN then
      SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);
    FRaised := True;
  end;
end;

procedure TWindowsThreadPriority.Restore;
begin
  if FRaised then
  begin
    if FSaved <> THREAD_PRIORITY_ERROR_RETURN then
      SetThreadPriority(GetCurrentThread, FSaved);
    FRaised := False;
  end;
end;

end.
