{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - options with weights (WeightedOptions)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.WeightedOptions;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   A set of options with a weight each, to choose one at random with a probability proportional to its
  ///   weight. The weights are 32 bit numbers (size_t of the Win32 build)
  /// </summary>
  TXcomWeightedOptions = class
  strict private
    FChoices: TXcomStringMap<Cardinal>;
    FTotalWeight: Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Loads "name: weight" pairs from a map node (a weight of 0 removes the option)</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>
    ///   set: an existing option takes the new weight, a weight of 0 removes it, a new option with a weight
    ///   is added
    /// </summary>
    procedure SetWeight(const AId: string; AWeight: Cardinal);
    /// <summary>True when the total weight is zero</summary>
    function IsEmpty: Boolean;
    /// <summary>choose: a random option ('' if there are none)</summary>
    function Choose(const ARandom: IXcomRandom): string;
    /// <summary>getNames: the options in the order of the keys</summary>
    function Names: TArray<string>;
  end;

implementation

{ TXcomWeightedOptions }

constructor TXcomWeightedOptions.Create;
begin
  inherited Create;
  FChoices := TXcomStringMap<Cardinal>.Create;
end;

destructor TXcomWeightedOptions.Destroy;
begin
  FChoices.Free;
  inherited Destroy;
end;

procedure TXcomWeightedOptions.Load(const ANode: IYamlNode);
var
  LPair: TYamlPair;
begin
  // the C++ walks a sequence with a map iterator: the first element has no key (an invalid node)
  if ANode.IsSequence then
  begin
    if ANode.Size > 0 then
      raise EYamlInvalidNode.Create(TYamlMark.NullMark, YamlInvalidNodeMessage(''));
    Exit;
  end;
  for LPair in ANode.Pairs do
    SetWeight(TXcomNodeReader.TextOf(LPair.Key), LPair.Value.AsCardinal);
end;

procedure TXcomWeightedOptions.SetWeight(const AId: string; AWeight: Cardinal);
var
  LOld: Cardinal;
begin
  if FChoices.TryGetValue(AId, LOld) then
  begin
    Dec(FTotalWeight, LOld);
    if AWeight <> 0 then
    begin
      FChoices.SetValue(AId, AWeight);
      Inc(FTotalWeight, AWeight);
    end
    else
      FChoices.Remove(AId);
  end
  else if AWeight <> 0 then
  begin
    FChoices.SetValue(AId, AWeight);
    Inc(FTotalWeight, AWeight);
  end;
end;

function TXcomWeightedOptions.IsEmpty: Boolean;
begin
  Result := FTotalWeight = 0;
end;

function TXcomWeightedOptions.Choose(const ARandom: IXcomRandom): string;
var
  LValue: Cardinal;
  LIndex: Integer;
begin
  if FTotalWeight = 0 then
    Exit('');
  LValue := Cardinal(ARandom.Generate(0, Integer(FTotalWeight)));
  for LIndex := 0 to FChoices.Count - 1 do
  begin
    if LValue <= FChoices.Value(LIndex) then
      Exit(FChoices.Key(LIndex));
    Dec(LValue, FChoices.Value(LIndex));
  end;
  // the C++ always finds an option here
  Result := FChoices.Key(FChoices.Count - 1);
end;

function TXcomWeightedOptions.Names: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FChoices.Count);
  for LIndex := 0 to FChoices.Count - 1 do
    Result[LIndex] := FChoices.Key(LIndex);
end;

end.
