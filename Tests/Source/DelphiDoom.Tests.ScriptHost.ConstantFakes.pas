{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the constants of the scripts for the tests             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ConstantFakes;

interface

uses
  System.Classes,
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>A table of constants that writes what it was given, one text for each: name:type=value</summary>
  TRecordingConstantTable = class(TInterfacedObject, IScriptConstantTable)
  strict private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddInteger(const AName: string; const AValue: Integer);
    procedure AddLongWord(const AName: string; const AValue: Cardinal);
    procedure AddExtended(const AName: string; const AValue: Extended);
    property Entries: TStringList read FEntries;
  end;

  /// <summary>A provider that writes the integer constants that it was given (the value is the position)</summary>
  TFakeConstantProvider = class(TInterfacedObject, IScriptConstantProvider)
  strict private
    FNames: TArray<string>;
    FAsked: Integer;
  public
    constructor Create(const ANames: array of string);
    procedure Describe(const ATable: IScriptConstantTable);
    /// <summary>How many times it was asked</summary>
    property Asked: Integer read FAsked;
  end;

implementation

uses
  System.SysUtils;

{ TRecordingConstantTable }

constructor TRecordingConstantTable.Create;
begin
  inherited Create;
  FEntries := TStringList.Create;
end;

destructor TRecordingConstantTable.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TRecordingConstantTable.AddInteger(const AName: string; const AValue: Integer);
begin
  FEntries.Add(Format('%s:integer=%d', [AName, AValue]));
end;

procedure TRecordingConstantTable.AddLongWord(const AName: string; const AValue: Cardinal);
begin
  FEntries.Add(Format('%s:longword=%d', [AName, AValue]));
end;

procedure TRecordingConstantTable.AddExtended(const AName: string; const AValue: Extended);
begin
  FEntries.Add(Format('%s:extended=%s', [AName, FloatToStr(AValue, TFormatSettings.Invariant)]));
end;

{ TFakeConstantProvider }

constructor TFakeConstantProvider.Create(const ANames: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FNames, Length(ANames));
  for LIndex := 0 to High(ANames) do
    FNames[LIndex] := ANames[LIndex];
end;

procedure TFakeConstantProvider.Describe(const ATable: IScriptConstantTable);
var
  LIndex: Integer;
begin
  Inc(FAsked);
  for LIndex := 0 to High(FNames) do
    ATable.AddInteger(FNames[LIndex], LIndex);
end;

end.
