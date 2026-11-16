{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Factory;

interface

uses
  DelphiDoom.Automap.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the automap</summary>
  TAutomapFactory = class
  public
    /// <summary>
    ///   The window of the automap: the view for the drawing and the navigator for the keys and the
    ///   tics are the same window seen through two contracts
    /// </summary>
    class procedure CreateView(out AView: IAutomapView; out ANavigator: IAutomapNavigator); static;
    /// <summary>The marks of the player</summary>
    class function CreateMarks: IAutomapMarks; static;
  end;

implementation

uses
  DelphiDoom.Automap.View, DelphiDoom.Automap.Marks;

{ TAutomapFactory }

class procedure TAutomapFactory.CreateView(out AView: IAutomapView;
  out ANavigator: IAutomapNavigator);
var
  LView: TAutomapView;
begin
  LView := TAutomapView.Create;
  AView := LView;
  ANavigator := LView;
end;

class function TAutomapFactory.CreateMarks: IAutomapMarks;
begin
  Result := TAutomapMarks.Create;
end;

end.
