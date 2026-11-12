{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the fakes                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.Fakes;

interface

uses
  System.Classes,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Parity.Intf;

type
  /// <summary>A log that keeps the lines in memory</summary>
  TFakeParityLog = class(TInterfacedObject, IParityLog)
  strict private
    FLines: TStringList;
    FFlushCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteLine(const ALine: string);
    procedure Flush;
    property Lines: TStringList read FLines;
    property FlushCount: Integer read FFlushCount;
  end;

  /// <summary>A switch that is on or off as the test wants</summary>
  TFakeParitySwitch = class(TInterfacedObject, IParitySwitch)
  strict private
    FActive: Boolean;
  public
    function IsActive: Boolean;
    property Active: Boolean read FActive write FActive;
  end;

  /// <summary>An entropy source that always gives the same number</summary>
  TFakeEntropySource = class(TInterfacedObject, IEntropySource)
  strict private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    function Next(ARange: Integer): Integer;
  end;

implementation

{ TFakeParityLog }

constructor TFakeParityLog.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TFakeParityLog.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TFakeParityLog.WriteLine(const ALine: string);
begin
  FLines.Add(ALine);
end;

procedure TFakeParityLog.Flush;
begin
  Inc(FFlushCount);
end;

{ TFakeParitySwitch }

function TFakeParitySwitch.IsActive: Boolean;
begin
  Result := FActive;
end;

{ TFakeEntropySource }

constructor TFakeEntropySource.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TFakeEntropySource.Next(ARange: Integer): Integer;
begin
  Result := FValue;
end;

end.
