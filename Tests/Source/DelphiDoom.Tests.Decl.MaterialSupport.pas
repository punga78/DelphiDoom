{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the material declaration - helpers                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.MaterialSupport;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Intf,
  DelphiDoom.Decl.Material.Types, DelphiDoom.Tests.Decl.Support;

const
  /// <summary>The tables the materials of the tests use</summary>
  TEST_TABLES =
    'table sinTable { { 0, 0.5, 1, 0.5, 0, -0.5, -1, -0.5 } }'#10 +
    'table cosTable { { 1, 0.5, 0, -0.5, -1, -0.5, 0, 0.5 } }'#10 +
    'table ramp { clamp { 0, 0.25, 1 } }'#10;

type
  /// <summary>A manager over one file of materials in memory (<c>materials/test.mtr</c>) with a few tables</summary>
  TMaterialTestKit = class
  strict private
    FKit: TDeclKit;
  public
    /// <summary>The text is the content of the file after the tables; the options are those of the materials</summary>
    constructor Create(const AMaterials: string; const AOptions: TMaterialOptions); overload;
    constructor Create(const AMaterials: string); overload;
    destructor Destroy; override;
    function Decl(const AName: AnsiString): IDecl;
    function Material(const AName: AnsiString): IDeclMaterial;
    function Registers(const AName: AnsiString): IMaterialRegisters;
    function LogText: string;
    property Kit: TDeclKit read FKit;
  end;

  /// <summary>A material of one stage: the text of <c>m/one</c> with the given lines in the stage</summary>
  function StageMaterial(const AStageLines: string): string;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Factory, DelphiDoom.Decl.StandardTypes;

function StageMaterial(const AStageLines: string): string;
begin
  Result := 'm/one'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map textures/one'#10#9#9 + AStageLines + #10#9'}'#10'}'#10;
end;

{ TMaterialTestKit }

constructor TMaterialTestKit.Create(const AMaterials: string; const AOptions: TMaterialOptions);
begin
  inherited Create;
  FKit := TDeclKit.Create;
  FKit.Source.Add('materials/test.mtr', AnsiString(TEST_TABLES + AMaterials));
  FKit.Source.Add('skins/test.skin', 'skin sk { "*" "m/other" }'#10);
  FKit.Start(False);
  TDeclStandardTypes.RegisterTypes(FKit.Manager.GetRegistry, [], AOptions);
  TDeclStandardTypes.RegisterFolders(FKit.Manager.GetRegistry);
end;

constructor TMaterialTestKit.Create(const AMaterials: string);
begin
  Create(AMaterials, TMaterialOptions.Standard);
end;

destructor TMaterialTestKit.Destroy;
begin
  FKit.Free;
  inherited Destroy;
end;

function TMaterialTestKit.Decl(const AName: AnsiString): IDecl;
begin
  Result := FKit.Manager.FindType(DECL_MATERIAL, AName, True);
end;

function TMaterialTestKit.Material(const AName: AnsiString): IDeclMaterial;
begin
  Supports(Decl(AName), IDeclMaterial, Result);
end;

function TMaterialTestKit.Registers(const AName: AnsiString): IMaterialRegisters;
begin
  Supports(Decl(AName), IMaterialRegisters, Result);
end;

function TMaterialTestKit.LogText: string;
begin
  Result := FKit.LogText;
end;

end.
