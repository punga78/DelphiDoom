{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a commendation of a soldier            }
{  (SoldierCommendations)                                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SoldierCommendation;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>A medal that a soldier earned: the type of commendation, its noun and its level of decoration</summary>
  TXcomSoldierCommendation = class
  strict private
    FType: string;
    FNoun: string;
    FDecorationLevel: Integer;
    FIsNew: Boolean;
  public
    /// <summary>SoldierCommendations(node)</summary>
    constructor Create(const ANode: IYamlNode); overload;
    /// <summary>A new commendation (level 0, new)</summary>
    constructor Create(const ACommendationType, ANoun: string); overload;
    /// <summary>A noun that is not in the file is "noNoun"; isNew is false</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>The noun is saved only if it is not "noNoun"; isNew is never saved</summary>
    function Save: IYamlNode;
    property CommendationType: string read FType;
    property Noun: string read FNoun;
    property DecorationLevel: Integer read FDecorationLevel;
    property IsNew: Boolean read FIsNew;
    /// <summary>makeOld</summary>
    procedure MakeOld;
    /// <summary>addDecoration: the next level; the commendation is new again</summary>
    procedure AddDecoration;
  end;

implementation

{ TXcomSoldierCommendation }

constructor TXcomSoldierCommendation.Create(const ANode: IYamlNode);
begin
  inherited Create;
  Load(ANode);
end;

constructor TXcomSoldierCommendation.Create(const ACommendationType, ANoun: string);
begin
  inherited Create;
  FType := ACommendationType;
  FNoun := ANoun;
  FIsNew := True;
end;

procedure TXcomSoldierCommendation.Load(const ANode: IYamlNode);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'commendationName', FType);
  FNoun := TXcomNodeReader.ReadString(ANode, 'noun', 'noNoun');
  FDecorationLevel := TXcomNodeReader.ReadInteger(ANode, 'decorationLevel', FDecorationLevel);
  FIsNew := TXcomNodeReader.ReadBoolean(ANode, 'isNew', False);
end;

function TXcomSoldierCommendation.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'commendationName', FType);
  if FNoun <> 'noNoun' then
    TXcomNodeWriter.SetString(Result, 'noun', FNoun);
  TXcomNodeWriter.SetInteger(Result, 'decorationLevel', FDecorationLevel);
end;

procedure TXcomSoldierCommendation.MakeOld;
begin
  FIsNew := False;
end;

procedure TXcomSoldierCommendation.AddDecoration;
begin
  Inc(FDecorationLevel);
  FIsNew := True;
end;

end.
