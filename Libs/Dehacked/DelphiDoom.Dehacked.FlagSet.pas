{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the names of the flags of a field            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FlagSet;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Intf;

type
  /// <summary>A set of flags: the names of the bits, and how a name can be written</summary>
  TDehackedFlagSet = class(TInterfacedObject, IDehackedFlagSet)
  private
    FNames: TArray<string>;
    FIndex: TDictionary<string, Integer>;
    FPrefixes: TArray<string>;
    FStripped: TArray<string>;
    FTrim: Boolean;
    FExtraFrom: Integer;
    function IndexOfName(const AName: string): Integer;
  public
    /// <param name="ANames">The names in the order of the bits</param>
    /// <param name="APrefixes">Prefixes that are tried, in order, before the name as it is (MF_, MF_EX_ ...)</param>
    /// <param name="AStripped">Prefixes that are removed from a name before it is looked for; with them a name must not be empty</param>
    /// <param name="ATrim">The names are trimmed (the old code did it for some fields and not for others)</param>
    /// <param name="AExtraFrom">The index of the first flag that is not in the field but in AExtra (28 for the things); -1 if there is none</param>
    constructor Create(const ANames, APrefixes, AStripped: TArray<string>; ATrim: Boolean;
      AExtraFrom: Integer = -1);
    destructor Destroy; override;
    function Names: TArray<string>;
    function Resolve(const AText: string; ANumber: Integer; AIsNumber: Boolean;
      out AMask, AExtra: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Dehacked.Strings;

{ TDehackedFlagSet }

constructor TDehackedFlagSet.Create(const ANames, APrefixes, AStripped: TArray<string>;
  ATrim: Boolean; AExtraFrom: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FNames := ANames;
  FPrefixes := APrefixes;
  FStripped := AStripped;
  FTrim := ATrim;
  FExtraFrom := AExtraFrom;
  FIndex := TDictionary<string, Integer>.Create;
  for LIndex := 0 to High(FNames) do
    if not FIndex.ContainsKey(FNames[LIndex]) then
      FIndex.Add(FNames[LIndex], LIndex);
end;

destructor TDehackedFlagSet.Destroy;
begin
  FIndex.Free;
  inherited Destroy;
end;

function TDehackedFlagSet.Names: TArray<string>;
begin
  Result := FNames;
end;

function TDehackedFlagSet.IndexOfName(const AName: string): Integer;
begin
  if not FIndex.TryGetValue(TDehackedStrings.Upper(AName), Result) then
    Result := -1;
end;

function TDehackedFlagSet.Resolve(const AText: string; ANumber: Integer; AIsNumber: Boolean;
  out AMask, AExtra: Integer): Boolean;
var
  LText, LToken, LRest, LPrefix: string;
  LIndex: Integer;
begin
  AMask := 0;
  AExtra := 0;
  Result := False;
  if AIsNumber then
  begin
    AMask := ANumber;
    Result := True;
    if FExtraFrom >= 0 then
    begin
      if ANumber < 0 then
        AExtra := AExtra or 1;
      if ANumber and (1 shl 30) <> 0 then
        AExtra := AExtra or 2;
      if ANumber and (1 shl 29) <> 0 then
        AExtra := AExtra or 4;
      if ANumber and (1 shl 28) <> 0 then
        AExtra := AExtra or 8;
    end;
    Exit;
  end;

  LText := AText;
  repeat
    TDehackedStrings.SplitSet(LText, LToken, LRest, [' ', '|', ',', '+']);
    if FTrim then
      LToken := TDehackedStrings.Trim(LToken);
    LIndex := -1;
    if Length(FStripped) > 0 then
    begin
      for LPrefix in FStripped do
        if TDehackedStrings.StartsWith(LPrefix, LToken) then
          Delete(LToken, 1, Length(LPrefix));
      if LToken <> '' then
        LIndex := IndexOfName(LToken);
    end
    else
    begin
      for LPrefix in FPrefixes do
      begin
        LIndex := IndexOfName(LPrefix + LToken);
        if LIndex >= 0 then
          Break;
      end;
      if LIndex < 0 then
        LIndex := IndexOfName(LToken);
    end;
    if LIndex >= 0 then
    begin
      if (FExtraFrom >= 0) and (LIndex >= FExtraFrom) then
        AExtra := AExtra or (1 shl (31 - LIndex))
      else
      begin
        Result := True;
        AMask := AMask or (1 shl LIndex);
      end;
    end;
    LText := LRest;
  until LText = '';
end;

end.
