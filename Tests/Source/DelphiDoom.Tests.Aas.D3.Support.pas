{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 AAS navigation - files, fakes and helpers   }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Support;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.Aas.D3.Intf;

type
  /// <summary>The log: keeps what the navigation prints and warns</summary>
  TD3FakeLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FMessages: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    property Messages: TStringList read FMessages;
  end;

  /// <summary>The callback of FindNearestGoal that accepts the areas whose number gives a remainder</summary>
  TD3ModuloCallback = class(TInterfacedObject, IAasAreaCallback)
  strict private
    FModulus: Integer;
    FRemainder: Integer;
    FAsked: Integer;
  public
    constructor Create(const AModulus, ARemainder: Integer);
    function TestArea(const ANavigator: IAasNavigator; const AAreaNum: Integer): Boolean;
    /// <summary>How many times it was asked</summary>
    property Asked: Integer read FAsked;
  end;

/// <summary>The folder with the .aas files of the tests</summary>
function D3DataFolder: string;
/// <summary>Reads one of them; the caller frees the file</summary>
function D3LoadFile(const AName: string; const ACrc: Cardinal = 0): TAasFile;
/// <summary>The bits of a float as the tool of the C prints them: #xxxxxxxx</summary>
function D3Bits(const AValue: Single): string;
function D3VectorBits(const AValue: TGeoVec3): string;

implementation

uses
  System.IOUtils, DelphiDoom.MapFile.Aas.Intf, DelphiDoom.MapFile.Aas.Factory;

{ TD3FakeLog }

constructor TD3FakeLog.Create;
begin
  inherited Create;
  FMessages := TStringList.Create;
end;

destructor TD3FakeLog.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

procedure TD3FakeLog.Printf(const AMessage: string);
begin
  FMessages.Add('P: ' + AMessage);
end;

procedure TD3FakeLog.Warning(const AMessage: string);
begin
  FMessages.Add('W: ' + AMessage);
end;

{ TD3ModuloCallback }

constructor TD3ModuloCallback.Create(const AModulus, ARemainder: Integer);
begin
  inherited Create;
  FModulus := AModulus;
  FRemainder := ARemainder;
end;

function TD3ModuloCallback.TestArea(const ANavigator: IAasNavigator; const AAreaNum: Integer): Boolean;
begin
  Inc(FAsked);
  Result := (AAreaNum * 7 + FRemainder) mod FModulus = 0;
end;

function D3DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\AasD3\');
end;

function D3LoadFile(const AName: string; const ACrc: Cardinal): TAasFile;
var
  LBytes: TBytes;
  LText: AnsiString;
begin
  Assert(TFile.Exists(D3DataFolder + AName), AName + ' not found in ' + D3DataFolder);
  LBytes := TFile.ReadAllBytes(D3DataFolder + AName);
  SetLength(LText, Length(LBytes));
  Move(LBytes[0], LText[1], Length(LBytes));
  Result := TAasFileFactory.CreateReader(nil).ParseText(LText, AnsiString(AName), ACrc);
end;

function D3Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := '#' + LowerCase(IntToHex(PCardinal(@LValue)^, 8));
end;

function D3VectorBits(const AValue: TGeoVec3): string;
begin
  Result := D3Bits(AValue.X) + ' ' + D3Bits(AValue.Y) + ' ' + D3Bits(AValue.Z);
end;

end.
