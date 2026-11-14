{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the gatherers without a game around them          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Gather.NullEvents;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Gather.Intf;

type
  /// <summary>IWarGatherEvents that does nothing (the default when nobody listens)</summary>
  TWarNullGatherEvents = class(TInterfacedObject, IWarGatherEvents)
  public
    procedure TreeChopped(const APosition: TWarVec2);
  end;

implementation

{ TWarNullGatherEvents }

procedure TWarNullGatherEvents.TreeChopped(const APosition: TWarVec2);
begin
end;

end.
