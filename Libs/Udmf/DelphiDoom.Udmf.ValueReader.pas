{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - reading the values                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.ValueReader;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.Scanner, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The words of a text, one by one: the parser asks for the keys, the formats for the values.
  ///   A value that is not what was asked is told to the log and read as 0
  /// </summary>
  TUdmfValueReader = class(TInterfacedObject, IUdmfValueReader)
  private
    FScanner: TUdmfScanner;
    FLog: ILog;
    FToken: string;
    FRaw: string;
    FLineTranslate: Boolean;
    procedure Warn(const AFormat: string; const AArguments: array of const); overload;
    function GetLineTranslate: Boolean;
  public
    /// <param name="AText">The text after the preprocessor</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AText: string; const ALog: ILog);
    destructor Destroy; override;
    /// <summary>The next word: Token has it in capital letters, Raw as it was written; false at the end</summary>
    function Advance: Boolean;
    property Token: string read FToken;
    property Raw: string read FRaw;
    property LineTranslate: Boolean read GetLineTranslate write FLineTranslate;
    function ReadToken: string;
    function ReadFloat: Single;
    function ReadInteger: Integer;
    function ReadIntegerList: TArray<Integer>;
    function ReadIsTrue: Boolean;
    procedure Warn(const AText: string); overload;
  end;

implementation

uses
  DelphiDoom.Udmf.Text;

{ TUdmfValueReader }

constructor TUdmfValueReader.Create(const AText: string; const ALog: ILog);
begin
  inherited Create;
  FScanner := TUdmfScanner.Create(AText);
  FLog := ALog;
end;

destructor TUdmfValueReader.Destroy;
begin
  FScanner.Free;
  inherited Destroy;
end;

procedure TUdmfValueReader.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

procedure TUdmfValueReader.Warn(const AFormat: string; const AArguments: array of const);
begin
  if Assigned(FLog) then
    FLog.Warning(Format(AFormat, AArguments));
end;

function TUdmfValueReader.GetLineTranslate: Boolean;
begin
  Result := FLineTranslate;
end;

function TUdmfValueReader.Advance: Boolean;
begin
  Result := FScanner.GetString;
  if Result then
  begin
    FRaw := FScanner.Value;
    FToken := TUdmfText.ToUpper(FRaw);
  end
  else
  begin
    FRaw := '';
    FToken := '';
  end;
end;

function TUdmfValueReader.ReadToken: string;
begin
  Advance;
  Result := FToken;
end;

function TUdmfValueReader.ReadFloat: Single;
begin
  Result := 0;
  if not Advance then
  begin
    Warn('TScriptEngine.MustGetFloat(): Missing float'#13#10);
    Exit;
  end;
  if not TUdmfText.TryParseFloat(FRaw, Result) then
  begin
    Result := 0;
    Warn('TScriptEngine.GetFloat(): Bad numeric constant "%s"'#13#10, [FRaw]);
  end;
end;

function TUdmfValueReader.ReadInteger: Integer;
begin
  Result := 0;
  if not Advance then
  begin
    Warn('TScriptEngine.MustGetInteger(): Missing integer'#13#10);
    Exit;
  end;
  if not TUdmfText.TryParseInteger(FRaw, Result) then
  begin
    Result := 0;
    Warn('TScriptEngine.GetInteger(): Bad numeric constant "%s"'#13#10, [FRaw]);
  end;
end;

function TUdmfValueReader.ReadIntegerList: TArray<Integer>;
var
  LScanner: TUdmfScanner;
  LValue: Integer;
begin
  Result := nil;
  if not Advance then
  begin
    Warn('TScriptEngine.MustGetString(): Missing string'#13#10);
    Exit;
  end;
  // the integers up to the first word that is not one
  LScanner := TUdmfScanner.Create(FRaw);
  try
    while LScanner.GetString and TUdmfText.TryParseInteger(LScanner.Value, LValue) do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LValue;
    end;
  finally
    LScanner.Free;
  end;
end;

function TUdmfValueReader.ReadIsTrue: Boolean;
begin
  Result := ReadToken = 'TRUE';
end;

end.