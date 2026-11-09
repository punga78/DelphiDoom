program RadixXlatDump;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  d_delphi,
  radix_xlat_wad;

function Fnv(const B: TBytes): Cardinal;
var
  I: Integer;
begin
  Result := $811C9DC5;
  for I := 0 to High(B) do
    Result := (Result xor B[I]) * $01000193;
end;

procedure Dump(const AWad: string; const AOut: string);
var
  S: TFileStream;
  L: TStringList;
  Count, Dir, I, Pos, Size, J: Integer;
  Name: array[0..7] of AnsiChar;
  N: AnsiString;
  Data: TBytes;
  Sig: array[0..3] of AnsiChar;
  Entries: array of record P, S: Integer; N: AnsiString; end;
begin
  S := TFileStream.Create(AWad, fmOpenRead);
  L := TStringList.Create;
  try
    S.Read(Sig, 4);
    S.Read(Count, 4);
    S.Read(Dir, 4);
    SetLength(Entries, Count);
    S.Position := Dir;
    for I := 0 to Count - 1 do
    begin
      S.Read(Pos, 4);
      S.Read(Size, 4);
      S.Read(Name, 8);
      N := '';
      for J := 0 to 7 do
        if Name[J] = #0 then
          Break
        else
          N := N + Name[J];
      Entries[I].P := Pos;
      Entries[I].S := Size;
      Entries[I].N := N;
    end;
    L.Add('lumps ' + IntToStr(Count));
    for I := 0 to Count - 1 do
    begin
      SetLength(Data, Entries[I].S);
      if Entries[I].S > 0 then
      begin
        S.Position := Entries[I].P;
        S.Read(Data[0], Entries[I].S);
        L.Add(Format('%d %s %d %.8x', [I, string(Entries[I].N), Entries[I].S, Fnv(Data)]));
        if Entries[I].N = 'RADIXINF' then
          with TFileStream.Create(AOut + '.radixinf.txt', fmCreate) do
          try
            WriteBuffer(Data[0], Length(Data));
          finally
            Free;
          end;
      end
      else
        L.Add(Format('%d %s 0 00000000', [I, string(Entries[I].N)]));
    end;
    L.SaveToFile(AOut);
  finally
    L.Free;
    S.Free;
  end;
end;

begin
  try
    Radix2WAD_Game(ParamStr(1), ParamStr(2));
    Dump(ParamStr(2), ParamStr(3));
    Writeln('done');
  except
    on E: Exception do
      Writeln('ERR ', E.ClassName, ' ', E.Message);
  end;
end.
