{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - extra sprites of a surface set            }
{  (ExtraSprites)                                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ExtraSprites;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.IntStringMap;

type
  /// <summary>The image files that a mod adds to a surface set, by number (ExtraSprites)</summary>
  TXcomExtraSprites = class
  strict private
    FType: string;
    FSprites: TXcomIntStringMap;
    FWidth: Integer;
    FHeight: Integer;
    FSingleImage: Boolean;
    FSubX: Integer;
    FSubY: Integer;
    FMod: TXcomModData;
  public
    constructor Create;
    destructor Destroy; override;
    /// <param name="ACurrent">The mod that the sprites belong to (_current)</param>
    procedure Load(const ANode: IYamlNode; const ACurrent: TXcomModData);
    property SetName: string read FType;
    property Sprites: TXcomIntStringMap read FSprites;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property SingleImage: Boolean read FSingleImage;
    property SubX: Integer read FSubX;
    property SubY: Integer read FSubY;
    property ModData: TXcomModData read FMod;
  end;

implementation

{ TXcomExtraSprites }

constructor TXcomExtraSprites.Create;
begin
  inherited Create;
  FSprites := TXcomIntStringMap.Create;
  FWidth := 320;
  FHeight := 200;
end;

destructor TXcomExtraSprites.Destroy;
begin
  FSprites.Free;
  inherited Destroy;
end;

procedure TXcomExtraSprites.Load(const ANode: IYamlNode; const ACurrent: TXcomModData);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FSprites.ReadField(ANode, 'files');
  FWidth := TXcomNodeReader.ReadInteger(ANode, 'width', FWidth);
  FHeight := TXcomNodeReader.ReadInteger(ANode, 'height', FHeight);
  FSingleImage := TXcomNodeReader.ReadBoolean(ANode, 'singleImage', FSingleImage);
  FSubX := TXcomNodeReader.ReadInteger(ANode, 'subX', FSubX);
  FSubY := TXcomNodeReader.ReadInteger(ANode, 'subY', FSubY);
  FMod := ACurrent;
end;

end.
