program RadixDiff;

{$APPTYPE CONSOLE}

// Compares the WAD that TRadixFactory.CreateTranslator gives with a golden file of the old translator:
// RadixDiff <RADIX.DAT> <golden.txt> [-v]  (lists the lumps that are missing or different)

uses
  System.SysUtils, System.Classes,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory;

function Fnv(const AData: TBytes): string;
var
  LIndex: Integer;
  LHash: Cardinal;
begin
  {$Q-}{$R-}
  if Length(AData) = 0 then
    Exit('00000000');
  LHash := $811C9DC5;
  for LIndex := 0 to High(AData) do
    LHash := (LHash xor AData[LIndex]) * $01000193;
  Result := Format('%.8X', [LHash]);
end;

var
  LWad: IGameWadComposer;
  LGolden: TStringList;
  LOrder: TStringList;
  LIndex: Integer;
  LParts: TArray<string>;
  LKey: string;
  LSame, LDifferent, LMissing, LPosition: Integer;
  LVerbose: Boolean;
  LData: TBytes;
begin
  LVerbose := ParamStr(3) = '-v';
  LWad := TRadixFactory.CreateTranslator.Translate(TRadixFactory.OpenContainer(ParamStr(1)));
  LOrder := TStringList.Create;
  LGolden := TStringList.Create;
  try
    for LIndex := 0 to LWad.Count - 1 do
    begin
      LData := LWad.LumpData[LIndex];
      LOrder.Add(Format('%s %d %s', [LWad.LumpNames[LIndex], Length(LData), Fnv(LData)]));
    end;
    LGolden.LoadFromFile(ParamStr(2));
    LSame := 0;
    LDifferent := 0;
    LMissing := 0;
    LPosition := 0;
    // the lumps of the library come in the same relative order as the old ones
    for LIndex := 1 to LGolden.Count - 1 do
    begin
      LParts := LGolden[LIndex].Split([' ']);
      LKey := Format('%s %s %s', [LParts[1], LParts[2], LParts[3]]);
      if (LPosition < LOrder.Count) and (LOrder[LPosition] = LKey) then
      begin
        Inc(LSame);
        Inc(LPosition);
      end
      else if (LPosition < LOrder.Count) and (Copy(LOrder[LPosition], 1, Length(LParts[1]) + 1) = LParts[1] + ' ') then
      begin
        Inc(LDifferent);
        if LVerbose then
          Writeln('DIFF ', LKey, ' <> ', LOrder[LPosition]);
        Inc(LPosition);
      end
      else
      begin
        Inc(LMissing);
        if LVerbose then
          Writeln('MISSING ', LKey);
      end;
    end;
    Writeln(Format('golden %d, same %d, different %d, missing %d, library lumps %d',
      [LGolden.Count - 1, LSame, LDifferent, LMissing, LOrder.Count]));
  finally
    LGolden.Free;
    LOrder.Free;
  end;
end.
