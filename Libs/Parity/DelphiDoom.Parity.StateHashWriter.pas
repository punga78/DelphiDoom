{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the hash of the state of the game, tic by tic  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.StateHashWriter;

interface

uses
  System.SysUtils,
  DelphiDoom.Parity.Hasher,
  DelphiDoom.Parity.Intf;

type
  /// <summary>
  ///   IParityStateSink that writes the log of the state: for every tic one line
  ///   <c>T tic total category=hash... scalar=value...</c> (total: 16 digits; the hash of a category: 8 digits).
  ///   Inside the range of the detail (if any) it also writes, before the line of the tic, one line
  ///   <c>D tic category index field value</c> for every field of every object, so that the first difference
  ///   between two runs says the tic, the kind of object, its number and the field
  /// </summary>
  TStateHashWriter = class(TInterfacedObject, IParityStateSink)
  strict private
    type
      TCategory = record
        Name: string;
        Fields: TArray<string>;
        Hasher: TParityHasher;
      end;
      TScalar = record
        Name: string;
        Value: Int64;
      end;
  strict private
    FLog: IParityLog;
    FDetail: Boolean;
    FDetailFirstTic: Integer;
    FDetailLastTic: Integer;
    FCategories: TArray<TCategory>;
    FScalars: TArray<TScalar>;
    FScalarCount: Integer;
    FTic: Integer;
    FCurrentCategory: Integer;
    FCurrentIndex: Integer;
    FWriteDetail: Boolean;
  public
    /// <summary>ADetail False: no detail lines (the range is ignored)</summary>
    constructor Create(const ALog: IParityLog; ADetail: Boolean; ADetailFirstTic, ADetailLastTic: Integer);
    function RegisterCategory(const AName: string; const AFieldNames: array of string): Integer;
    procedure BeginTic(ATic: Integer);
    procedure BeginObject(ACategory: Integer; AIndex: Integer);
    procedure Field(AField: Integer; AValue: Int64);
    procedure EndObject;
    procedure Scalar(const AName: string; AValue: Int64);
    procedure EndTic;
  end;

implementation

uses
  DelphiDoom.Parity.Types;

const
  SNoLog = 'ALog';
  SWrongCategory = 'The category %d was not registered';
  SWrongField = 'The field %d of the category %s was not declared';
  SNoObject = 'Field without BeginObject';

{ TStateHashWriter }

constructor TStateHashWriter.Create(const ALog: IParityLog; ADetail: Boolean; ADetailFirstTic,
  ADetailLastTic: Integer);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create(SNoLog);
  FLog := ALog;
  FDetail := ADetail;
  FDetailFirstTic := ADetailFirstTic;
  FDetailLastTic := ADetailLastTic;
  FCurrentCategory := -1;
end;

function TStateHashWriter.RegisterCategory(const AName: string; const AFieldNames: array of string): Integer;
var
  LIndex: Integer;
begin
  Result := Length(FCategories);
  SetLength(FCategories, Result + 1);
  FCategories[Result].Name := AName;
  SetLength(FCategories[Result].Fields, Length(AFieldNames));
  for LIndex := 0 to High(AFieldNames) do
    FCategories[Result].Fields[LIndex] := AFieldNames[LIndex];
  FCategories[Result].Hasher.Reset;
end;

procedure TStateHashWriter.BeginTic(ATic: Integer);
var
  LIndex: Integer;
begin
  FTic := ATic;
  FScalarCount := 0;
  FCurrentCategory := -1;
  for LIndex := 0 to High(FCategories) do
    FCategories[LIndex].Hasher.Reset;
  FWriteDetail := FDetail and (ATic >= FDetailFirstTic) and (ATic <= FDetailLastTic);
end;

procedure TStateHashWriter.BeginObject(ACategory: Integer; AIndex: Integer);
begin
  if (ACategory < 0) or (ACategory > High(FCategories)) then
    raise EParityException.CreateFmt(SWrongCategory, [ACategory]);
  FCurrentCategory := ACategory;
  FCurrentIndex := AIndex;
  FCategories[ACategory].Hasher.AddInteger(AIndex);
end;

procedure TStateHashWriter.Field(AField: Integer; AValue: Int64);
begin
  if FCurrentCategory < 0 then
    raise EParityException.Create(SNoObject);
  FCategories[FCurrentCategory].Hasher.AddInt64(AValue);
  if FWriteDetail then
  begin
    if (AField < 0) or (AField > High(FCategories[FCurrentCategory].Fields)) then
      raise EParityException.CreateFmt(SWrongField, [AField, FCategories[FCurrentCategory].Name]);
    FLog.WriteLine(Format('D %d %s %d %s %d', [FTic, FCategories[FCurrentCategory].Name, FCurrentIndex,
      FCategories[FCurrentCategory].Fields[AField], AValue]));
  end;
end;

procedure TStateHashWriter.EndObject;
begin
  FCurrentCategory := -1;
end;

procedure TStateHashWriter.Scalar(const AName: string; AValue: Int64);
begin
  if FScalarCount > High(FScalars) then
    SetLength(FScalars, FScalarCount + 8);
  FScalars[FScalarCount].Name := AName;
  FScalars[FScalarCount].Value := AValue;
  Inc(FScalarCount);
end;

procedure TStateHashWriter.EndTic;
var
  LTotal: TParityHasher;
  LLine: string;
  LIndex: Integer;
begin
  LTotal.Reset;
  LLine := '';
  for LIndex := 0 to High(FCategories) do
  begin
    LTotal.AddInt64(Int64(FCategories[LIndex].Hasher.Value));
    LLine := LLine + ' ' + FCategories[LIndex].Name + '=' +
      TParityHasher.ToShortHex(FCategories[LIndex].Hasher.Value);
  end;
  for LIndex := 0 to FScalarCount - 1 do
  begin
    LTotal.AddInt64(FScalars[LIndex].Value);
    LLine := LLine + ' ' + FScalars[LIndex].Name + '=' + IntToStr(FScalars[LIndex].Value);
  end;
  FLog.WriteLine('T ' + IntToStr(FTic) + ' ' + TParityHasher.ToHex(LTotal.Value) + LLine);
end;

end.
