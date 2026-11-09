{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - extra sounds of a sound set (ExtraSounds) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ExtraSounds;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.IntStringMap;

type
  /// <summary>The sound files that a mod adds to a sound set, by number (ExtraSounds)</summary>
  TXcomExtraSounds = class
  strict private
    FType: string;
    FSounds: TXcomIntStringMap;
    FMod: TXcomModData;
  public
    constructor Create;
    destructor Destroy; override;
    /// <param name="ACurrent">The mod that the sounds belong to (_current)</param>
    procedure Load(const ANode: IYamlNode; const ACurrent: TXcomModData);
    property SetName: string read FType;
    property Sounds: TXcomIntStringMap read FSounds;
    property ModData: TXcomModData read FMod;
  end;

implementation

{ TXcomExtraSounds }

constructor TXcomExtraSounds.Create;
begin
  inherited Create;
  FSounds := TXcomIntStringMap.Create;
end;

destructor TXcomExtraSounds.Destroy;
begin
  FSounds.Free;
  inherited Destroy;
end;

procedure TXcomExtraSounds.Load(const ANode: IYamlNode; const ACurrent: TXcomModData);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FSounds.ReadField(ANode, 'files');
  FMod := ACurrent;
end;

end.
