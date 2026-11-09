{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a Position as a list of numbers       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.PositionCodec;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>convert&lt;Position&gt; of OpenXcom: a sequence of three integers</summary>
  TXcomPositionCodec = class
  public
    /// <summary>
    ///   node[key].as&lt;Position&gt;(default): a missing key or a node that is not a sequence of three gives the
    ///   default; an element that is not an integer raises EYamlBadConversion
    /// </summary>
    class function Read(const ANode: IYamlNode; const AKey: string; const ADefault: TXcomPosition)
      : TXcomPosition; static;
    /// <summary>node[key] = position</summary>
    class procedure Write(const ANode: IYamlNode; const AKey: string; const APosition: TXcomPosition); static;
  end;

implementation

{ TXcomPositionCodec }

class function TXcomPositionCodec.Read(const ANode: IYamlNode; const AKey: string;
  const ADefault: TXcomPosition): TXcomPosition;
var
  LField: IYamlNode;
  LCells: TArray<IYamlNode>;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence or (LField.Size <> 3) then
    Exit(ADefault);
  LCells := LField.Items;
  Result.X := LCells[0].AsInteger;
  Result.Y := LCells[1].AsInteger;
  Result.Z := LCells[2].AsInteger;
end;

class procedure TXcomPositionCodec.Write(const ANode: IYamlNode; const AKey: string;
  const APosition: TXcomPosition);
begin
  TXcomNodeWriter.SetIntegers(ANode, AKey, [APosition.X, APosition.Y, APosition.Z]);
end;

end.
