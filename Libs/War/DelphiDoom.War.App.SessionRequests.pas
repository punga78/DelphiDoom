{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the requests to save and to load                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.SessionRequests;

interface

uses
  DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The buttons of the menus and the keys F5 and F9 do not save or load: they leave a request, and the loop of the
  ///   program does it between two frames. Each request is taken once
  /// </summary>
  TWarSessionRequests = class(TInterfacedObject, IWarSessionRequests)
  strict private
    FSave: Boolean;
    FLoad: Boolean;
  public
    procedure RequestSave;
    procedure RequestLoad;
    /// <summary>True once for each RequestSave</summary>
    function TakeSave: Boolean;
    /// <summary>True once for each RequestLoad</summary>
    function TakeLoad: Boolean;
    /// <summary>Forgets what was asked (what a game that is played again asked while it was)</summary>
    procedure Clear;
  end;

implementation

{ TWarSessionRequests }

procedure TWarSessionRequests.RequestSave;
begin
  FSave := True;
end;

procedure TWarSessionRequests.RequestLoad;
begin
  FLoad := True;
end;

function TWarSessionRequests.TakeSave: Boolean;
begin
  Result := FSave;
  FSave := False;
end;

function TWarSessionRequests.TakeLoad: Boolean;
begin
  Result := FLoad;
  FLoad := False;
end;

procedure TWarSessionRequests.Clear;
begin
  FSave := False;
  FLoad := False;
end;

end.
