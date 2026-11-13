{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - a simulation that shows its events on    }
{  the geoscape that receives it                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.PopupSimulation;

interface

uses
  DelphiDoom.XcomStrategy.Simulation.Intf, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   Decorates the simulation of the strategy with the popups: the geoscape that is given this simulation attaches
  ///   itself to it, and the events that the inner simulation reports are shown on that geoscape
  /// </summary>
  TXcomPopupSimulation = class(TInterfacedObject, IXcomGeoscapeSimulation, IXcomGeoscapeAware)
  strict private
    FInner: IXcomGeoscapeSimulation;
    FEvents: IXcomGeoscapeAware;
  public
    /// <param name="AInner">The simulation that does the work</param>
    /// <param name="AEvents">The listener that the inner simulation reports to (it is the one that opens the popups)</param>
    constructor Create(const AInner: IXcomGeoscapeSimulation; const AEvents: IXcomGeoscapeAware);
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
    procedure Time5Seconds;
    procedure Time10Minutes;
    procedure Time30Minutes;
    procedure Time1Hour;
    procedure Time1Day;
    procedure Time1Month;
    procedure StartFirstMonth;
  end;

implementation

{ TXcomPopupSimulation }

constructor TXcomPopupSimulation.Create(const AInner: IXcomGeoscapeSimulation; const AEvents: IXcomGeoscapeAware);
begin
  inherited Create;
  FInner := AInner;
  FEvents := AEvents;
end;

procedure TXcomPopupSimulation.AttachGeoscape(const AControl: IXcomGeoscapeControl);
begin
  FEvents.AttachGeoscape(AControl);
end;

procedure TXcomPopupSimulation.Time5Seconds;
begin
  FInner.Time5Seconds;
end;

procedure TXcomPopupSimulation.Time10Minutes;
begin
  FInner.Time10Minutes;
end;

procedure TXcomPopupSimulation.Time30Minutes;
begin
  FInner.Time30Minutes;
end;

procedure TXcomPopupSimulation.Time1Hour;
begin
  FInner.Time1Hour;
end;

procedure TXcomPopupSimulation.Time1Day;
begin
  FInner.Time1Day;
end;

procedure TXcomPopupSimulation.Time1Month;
begin
  FInner.Time1Month;
end;

procedure TXcomPopupSimulation.StartFirstMonth;
begin
  FInner.StartFirstMonth;
end;

end.
