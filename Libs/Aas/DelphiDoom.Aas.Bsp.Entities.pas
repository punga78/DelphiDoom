{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the entities of the BSP                            }
{                                                                              }
{  Port of AAS_ParseBSPEntities, AAS_ValueForBSPEpairKey and the other key      }
{  functions of be_aas_bspq3.c. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is        }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Bsp.Entities;

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Bsp.Intf;

const
  /// <summary>MAX_BSPENTITIES</summary>
  AAS_MAX_BSP_ENTITIES = 2048;

type
  /// <summary>
  ///   The entity text of a map parsed once. A text that is not well formed leaves no entities, with a message
  ///   to the import, like the original; the import is not owned
  /// </summary>
  TAasBspEntities = class(TInterfacedObject, IAasBspEntities)
  strict private
    type
      TPair = record
        Key: AnsiString;
        Value: AnsiString;
      end;
  strict private
    FImport: IBotImport;
    // index 0 is the entity that does not exist; the pairs are in the order of the file
    FEntities: TList<TArray<TPair>>;
    procedure Parse(const AText: AnsiString);
    procedure Clear;
  public
    constructor Create(const AImport: IBotImport; const AEntityText: AnsiString);
    destructor Destroy; override;
    function GetCount: Integer;
    function NextEntity(const AEntity: Integer): Integer;
    function EntityInRange(const AEntity: Integer): Boolean;
    function ValueForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
      const ASize: Integer = 128): Boolean;
    function VectorForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
    function FloatForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
    function IntForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Bsp.CNumbers;

type
  TTokenKind = (tkEnd, tkString, tkPunctuation, tkOther);

  // The part of PS_ReadToken that entity texts need: comments and white space are skipped, a string has no
  // escapes (SCFL_NOSTRINGESCAPECHARS) and does not go on to the next one (SCFL_NOSTRINGWHITESPACES)
  TEntityScanner = class
  strict private
    FText: AnsiString;
    FPosition: Integer;
    function SkipBlanks: Boolean;
  public
    constructor Create(const AText: AnsiString);
    function Read(out AToken: AnsiString): TTokenKind;
  end;

{ TEntityScanner }

constructor TEntityScanner.Create(const AText: AnsiString);
begin
  inherited Create;
  FText := AText;
  FPosition := 1;
end;

function TEntityScanner.SkipBlanks: Boolean;
begin
  Result := True;
  while FPosition <= Length(FText) do
  begin
    if FText[FPosition] <= ' ' then
      Inc(FPosition)
    else if (FText[FPosition] = '/') and (FPosition < Length(FText)) and (FText[FPosition + 1] = '/') then
    begin
      while (FPosition <= Length(FText)) and (FText[FPosition] <> #10) do
        Inc(FPosition);
    end
    else if (FText[FPosition] = '/') and (FPosition < Length(FText)) and (FText[FPosition + 1] = '*') then
    begin
      Inc(FPosition, 2);
      while (FPosition < Length(FText)) and not ((FText[FPosition] = '*') and (FText[FPosition + 1] = '/')) do
        Inc(FPosition);
      Inc(FPosition, 2);
    end
    else
      Exit;
  end;
  Result := False;
end;

function TEntityScanner.Read(out AToken: AnsiString): TTokenKind;
var
  LStart: Integer;
begin
  AToken := '';
  if not SkipBlanks then
    Exit(tkEnd);
  if FText[FPosition] = '"' then
  begin
    Inc(FPosition);
    LStart := FPosition;
    while (FPosition <= Length(FText)) and (FText[FPosition] <> '"') do
    begin
      // a new line inside a string is an error: no token
      if FText[FPosition] = #10 then
        Exit(tkEnd);
      Inc(FPosition);
    end;
    if FPosition > Length(FText) then
      Exit(tkEnd);
    AToken := Copy(FText, LStart, FPosition - LStart);
    Inc(FPosition);
    Exit(tkString);
  end;
  if FText[FPosition] in ['{', '}'] then
  begin
    AToken := FText[FPosition];
    Inc(FPosition);
    Exit(tkPunctuation);
  end;
  LStart := FPosition;
  while (FPosition <= Length(FText)) and (FText[FPosition] > ' ') and not (FText[FPosition] in ['{', '}', '"']) do
    Inc(FPosition);
  AToken := Copy(FText, LStart, FPosition - LStart);
  Result := tkOther;
end;

{ TAasBspEntities }

constructor TAasBspEntities.Create(const AImport: IBotImport; const AEntityText: AnsiString);
begin
  inherited Create;
  FImport := AImport;
  FEntities := TList<TArray<TPair>>.Create;
  Parse(AEntityText);
end;

destructor TAasBspEntities.Destroy;
begin
  FEntities.Free;
  inherited Destroy;
end;

procedure TAasBspEntities.Clear;
begin
  FEntities.Clear;
end;

procedure TAasBspEntities.Parse(const AText: AnsiString);
var
  LScanner: TEntityScanner;
  LToken, LValue: AnsiString;
  LKind: TTokenKind;
  LPairs: TArray<TPair>;
  LPair: TPair;
begin
  Clear;
  LScanner := TEntityScanner.Create(AText);
  try
    // the entity zero is not used
    FEntities.Add(nil);
    LKind := LScanner.Read(LToken);
    while LKind <> tkEnd do
    begin
      if (LKind <> tkPunctuation) or (LToken <> '{') then
      begin
        FImport.Print(PRT_ERROR, 'entdata: invalid ' + LToken + #10);
        Clear;
        Exit;
      end;
      if FEntities.Count >= AAS_MAX_BSP_ENTITIES then
      begin
        FImport.Print(PRT_MESSAGE, 'too many entities in BSP file'#10);
        Break;
      end;
      LPairs := nil;
      LKind := LScanner.Read(LToken);
      while LKind <> tkEnd do
      begin
        if (LKind = tkPunctuation) and (LToken = '}') then
          Break;
        if LKind <> tkString then
        begin
          FImport.Print(PRT_ERROR, 'entdata: invalid ' + LToken + #10);
          Clear;
          Exit;
        end;
        LPair.Key := LToken;
        if LScanner.Read(LValue) <> tkString then
        begin
          FImport.Print(PRT_ERROR, 'entdata: expected a string'#10);
          Clear;
          Exit;
        end;
        LPair.Value := LValue;
        LPairs := LPairs + [LPair];
        LKind := LScanner.Read(LToken);
      end;
      if (LKind <> tkPunctuation) or (LToken <> '}') then
      begin
        FImport.Print(PRT_ERROR, 'entdata: missing }'#10);
        Clear;
        Exit;
      end;
      FEntities.Add(LPairs);
      LKind := LScanner.Read(LToken);
    end;
  finally
    LScanner.Free;
  end;
end;

function TAasBspEntities.GetCount: Integer;
begin
  Result := FEntities.Count;
end;

function TAasBspEntities.NextEntity(const AEntity: Integer): Integer;
begin
  Result := AEntity + 1;
  if not ((Result >= 1) and (Result < FEntities.Count)) then
    Result := 0;
end;

function TAasBspEntities.EntityInRange(const AEntity: Integer): Boolean;
begin
  Result := (AEntity > 0) and (AEntity < FEntities.Count);
  if not Result then
    FImport.Print(PRT_MESSAGE, 'bsp entity out of range'#10);
end;

function TAasBspEntities.ValueForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
  const ASize: Integer): Boolean;
var
  LPairs: TArray<TPair>;
  LIndex: Integer;
begin
  AValue := '';
  Result := False;
  if not EntityInRange(AEntity) then
    Exit;
  LPairs := FEntities[AEntity];
  // the original keeps the pairs with the last one first: a key given twice answers with the second value
  for LIndex := High(LPairs) downto 0 do
    if LPairs[LIndex].Key = AKey then
    begin
      AValue := Copy(LPairs[LIndex].Value, 1, ASize - 1);
      Exit(True);
    end;
end;

function TAasBspEntities.VectorForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
var
  LText: AnsiString;
begin
  AValue[0] := 0;
  AValue[1] := 0;
  AValue[2] := 0;
  Result := ValueForKey(AEntity, AKey, LText);
  if Result then
    AValue := TVec3(TAasCNumbers.ScanVector(LText));
end;

function TAasBspEntities.FloatForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
var
  LText: AnsiString;
begin
  AValue := 0;
  Result := ValueForKey(AEntity, AKey, LText);
  if Result then
    AValue := TAasCNumbers.AtoF(LText);
end;

function TAasBspEntities.IntForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
var
  LText: AnsiString;
begin
  AValue := 0;
  Result := ValueForKey(AEntity, AKey, LText);
  if Result then
    AValue := TAasCNumbers.AtoI(LText);
end;

end.
