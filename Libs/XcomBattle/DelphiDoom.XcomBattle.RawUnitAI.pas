{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the AI state of a unit kept as data   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.RawUnitAI;

interface

uses
  DelphiDoom.Yaml.Intf, DelphiDoom.XcomBattle.Intf;

type
  /// <summary>
  ///   Until AIModule is ported, the "AI" node of a saved unit is kept as it was read and written back as it
  ///   is (the C++ loads it into an AIModule and saves that: the two agree on a file that the C++ wrote)
  /// </summary>
  TXcomRawUnitAI = class(TInterfacedObject, IXcomUnitAI)
  strict private
    FNode: IYamlNode;
  public
    constructor Create(const ANode: IYamlNode);
    function Save: IYamlNode;
    procedure Reset;
    procedure FreePatrolTarget;
  end;

implementation

constructor TXcomRawUnitAI.Create(const ANode: IYamlNode);
begin
  inherited Create;
  FNode := ANode;
end;

function TXcomRawUnitAI.Save: IYamlNode;
begin
  Result := FNode;
end;

procedure TXcomRawUnitAI.Reset;
begin
  // nothing to reset: the data are not interpreted
end;

procedure TXcomRawUnitAI.FreePatrolTarget;
begin
  // the patrol node is not tracked
end;

end.
