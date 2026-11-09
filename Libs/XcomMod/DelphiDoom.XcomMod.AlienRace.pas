{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an alien race (AlienRace)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.AlienRace;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>Represents an alien race: the ranks of its members, from the weakest to the strongest</summary>
  TXcomAlienRace = class
  strict private
    FId: string;
    FMembers: TArray<string>;
  public
    constructor Create(const AId: string);
    procedure Load(const ANode: IYamlNode);
    property Id: string read FId;
    property Members: TArray<string> read FMembers;
    /// <summary>getMember: the member of a rank; an index outside the list is EXcomModException (undefined in the C++)</summary>
    function GetMember(AIndex: Integer): string;
  end;

implementation

{ TXcomAlienRace }

constructor TXcomAlienRace.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
end;

procedure TXcomAlienRace.Load(const ANode: IYamlNode);
begin
  FId := TXcomNodeReader.ReadString(ANode, 'id', FId);
  FMembers := TXcomNodeReader.ReadStrings(ANode, 'members', FMembers);
end;

function TXcomAlienRace.GetMember(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Length(FMembers)) then
    raise EXcomModException.CreateFmt('Xcom: the race %s has no member %d', [FId, AIndex]);
  Result := FMembers[AIndex];
end;

end.
