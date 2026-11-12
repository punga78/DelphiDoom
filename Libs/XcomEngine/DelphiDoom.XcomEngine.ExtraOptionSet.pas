{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - several groups of the settings the         }
{  program adds to the ones of OpenXcom, listed as one (issue 184)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ExtraOptionSet;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.ExtraOptions.Intf, DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf;

type
  /// <summary>
  ///   The rows of several IXcomExtraOptions one after the other under the heading of the first. A part that is
  ///   also an IXcomExtraChoiceOptions keeps its kinds, the others are toggles
  /// </summary>
  TXcomExtraOptionSet = class(TInterfacedObject, IXcomExtraOptions, IXcomExtraChoiceOptions)
  strict private
    FParts: TArray<IXcomExtraOptions>;
    procedure Locate(AIndex: Integer; out APart, ALocal: Integer);
    function ChoicesOf(APart: Integer; out AChoices: IXcomExtraChoiceOptions): Boolean;
  public
    /// <param name="AParts">At least one</param>
    constructor Create(const AParts: TArray<IXcomExtraOptions>);
    function Heading: string;
    function Count: Integer;
    function Title(AIndex: Integer): string;
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
    function Kind(AIndex: Integer): TXcomExtraKind;
    procedure Step(AIndex, ADirection: Integer);
    procedure Discard;
  end;

implementation

const
  SNoParts = 'AParts';
  SBadIndex = 'Xcom: no such extra option';

constructor TXcomExtraOptionSet.Create(const AParts: TArray<IXcomExtraOptions>);
var
  LPart: IXcomExtraOptions;
begin
  inherited Create;
  if Length(AParts) = 0 then
    raise EArgumentNilException.Create(SNoParts);
  for LPart in AParts do
    if not Assigned(LPart) then
      raise EArgumentNilException.Create(SNoParts);
  FParts := AParts;
end;

procedure TXcomExtraOptionSet.Locate(AIndex: Integer; out APart, ALocal: Integer);
var
  LPart: Integer;
begin
  ALocal := AIndex;
  APart := 0;
  for LPart := 0 to High(FParts) do
  begin
    APart := LPart;
    if (ALocal >= 0) and (ALocal < FParts[LPart].Count) then
      Exit;
    Dec(ALocal, FParts[LPart].Count);
  end;
  raise EArgumentOutOfRangeException.Create(SBadIndex);
end;

function TXcomExtraOptionSet.ChoicesOf(APart: Integer; out AChoices: IXcomExtraChoiceOptions): Boolean;
begin
  Result := Supports(FParts[APart], IXcomExtraChoiceOptions, AChoices);
end;

function TXcomExtraOptionSet.Heading: string;
begin
  Result := FParts[0].Heading;
end;

function TXcomExtraOptionSet.Count: Integer;
var
  LPart: IXcomExtraOptions;
begin
  Result := 0;
  for LPart in FParts do
    Inc(Result, LPart.Count);
end;

function TXcomExtraOptionSet.Title(AIndex: Integer): string;
var
  LPart: Integer;
  LLocal: Integer;
begin
  Locate(AIndex, LPart, LLocal);
  Result := FParts[LPart].Title(LLocal);
end;

function TXcomExtraOptionSet.Description(AIndex: Integer): string;
var
  LPart: Integer;
  LLocal: Integer;
begin
  Locate(AIndex, LPart, LLocal);
  Result := FParts[LPart].Description(LLocal);
end;

function TXcomExtraOptionSet.IsOn(AIndex: Integer): Boolean;
var
  LPart: Integer;
  LLocal: Integer;
begin
  Locate(AIndex, LPart, LLocal);
  Result := FParts[LPart].IsOn(LLocal);
end;

procedure TXcomExtraOptionSet.SetOn(AIndex: Integer; AValue: Boolean);
var
  LPart: Integer;
  LLocal: Integer;
begin
  Locate(AIndex, LPart, LLocal);
  FParts[LPart].SetOn(LLocal, AValue);
end;

function TXcomExtraOptionSet.Kind(AIndex: Integer): TXcomExtraKind;
var
  LPart: Integer;
  LLocal: Integer;
  LChoices: IXcomExtraChoiceOptions;
begin
  Locate(AIndex, LPart, LLocal);
  if ChoicesOf(LPart, LChoices) then
    Result := LChoices.Kind(LLocal)
  else
    Result := ekToggle;
end;

procedure TXcomExtraOptionSet.Step(AIndex, ADirection: Integer);
var
  LPart: Integer;
  LLocal: Integer;
  LChoices: IXcomExtraChoiceOptions;
begin
  Locate(AIndex, LPart, LLocal);
  if ChoicesOf(LPart, LChoices) then
    LChoices.Step(LLocal, ADirection);
end;

procedure TXcomExtraOptionSet.Discard;
var
  LIndex: Integer;
  LChoices: IXcomExtraChoiceOptions;
begin
  for LIndex := 0 to High(FParts) do
    if ChoicesOf(LIndex, LChoices) then
      LChoices.Discard;
end;

end.
