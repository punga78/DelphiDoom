{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom geoscape library - a host for the states       }
{  (a fake of the game with the parts that the tests give)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.Host;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.Clock.ManualClock;

type
  /// <summary>
  ///   A host with a manual clock and nothing else (the rest raises): enough for the surfaces that only ask the host
  ///   for the time. The clock is held as an interface for the whole life of the host
  /// </summary>
  TXcomClockHost = class(TXcomStateHost)
  strict private
    FClockObject: TManualClock;
    FClock: IClock;
  public
    constructor Create;
    /// <summary>Lets time pass on the clock</summary>
    procedure Advance(AMilliseconds: Cardinal);
    function Screen: TXcomScreen; override;
    function Cursor: TXcomInteractiveSurface; override;
    function FpsCounter: TXcomInteractiveSurface; override;
    function Language: TXcomLanguage; override;
    function Resources: IXcomResources; override;
    function Options: TXcomOptions; override;
    function Clock: IClock; override;
    procedure PushState(AState: TXcomState); override;
    procedure PopState; override;
    procedure SetState(AState: TXcomState); override;
    procedure Quit; override;
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); override;
    function IsState(AState: TXcomState): Boolean; override;
  end;

implementation

constructor TXcomClockHost.Create;
begin
  inherited Create;
  FClockObject := TManualClock.Create(0);
  FClock := FClockObject;
end;

procedure TXcomClockHost.Advance(AMilliseconds: Cardinal);
begin
  FClockObject.Advance(AMilliseconds);
end;

function TXcomClockHost.Screen: TXcomScreen;
begin
  Result := nil;
end;

function TXcomClockHost.Cursor: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TXcomClockHost.FpsCounter: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TXcomClockHost.Language: TXcomLanguage;
begin
  Result := nil;
end;

function TXcomClockHost.Resources: IXcomResources;
begin
  Result := nil;
end;

function TXcomClockHost.Options: TXcomOptions;
begin
  Result := nil;
end;

function TXcomClockHost.Clock: IClock;
begin
  Result := FClock;
end;

procedure TXcomClockHost.PushState(AState: TXcomState);
begin
  AState.Free;
end;

procedure TXcomClockHost.PopState;
begin
end;

procedure TXcomClockHost.SetState(AState: TXcomState);
begin
  AState.Free;
end;

procedure TXcomClockHost.Quit;
begin
end;

procedure TXcomClockHost.AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage);
begin
  ALanguage.Free;
end;

function TXcomClockHost.IsState(AState: TXcomState): Boolean;
begin
  Result := False;
end;

end.
