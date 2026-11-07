{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the golden file                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Golden;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The file of Tests\Data\Automap: lines key=fingerprint, made by the old engine code (see
  ///   Tests\Data\Automap\README.md)
  /// </summary>
  TGoldenFile = class
  private
    FLines: TStringList;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    /// <summary>The value of a key; fails the test if the key is not there</summary>
    function ValueOf(const AKey: string): string;
    /// <summary>Compares the fingerprint of a scenario with the one of the old code</summary>
    procedure Check(const AKey, AActual: string);
  end;

implementation

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework;

{ TGoldenFile }

constructor TGoldenFile.Create(const AFileName: string);
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.NameValueSeparator := '=';
  FLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Automap\' + AFileName)));
end;

destructor TGoldenFile.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TGoldenFile.ValueOf(const AKey: string): string;
begin
  Assert.IsTrue(FLines.IndexOfName(AKey) >= 0, 'chiave assente nel file golden: ' + AKey);
  Result := FLines.Values[AKey];
end;

procedure TGoldenFile.Check(const AKey, AActual: string);
begin
  Assert.AreEqual(ValueOf(AKey), AActual, AKey);
end;

end.
