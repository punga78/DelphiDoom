program GreedGolden;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: usa il codice ORIGINALE di xGreed (d_disk, g_fixlump, r_spans) per produrre i golden.
// Uso: GreedGolden <GREED.BLO> <uscita.txt> [LEVEL1.LAY ...]
uses
  SysUtils, Classes, System.ZLib, g_delphi, d_disk;

function Crc(const P: Pointer; N: Integer): string;
var
  C: Cardinal;
begin
  C := System.ZLib.crc32(0, nil, 0);
  if N > 0 then
    C := System.ZLib.crc32(C, System.PByte(P), N);
  Result := LowerCase(IntToHex(C, 8));
end;

function NameOf(I: Integer): AnsiString;
var
  Ofs: Integer;
begin
  Result := '';
  Ofs := infotable[I].nameofs;
  if Ofs <> 0 then
    Result := PAnsiChar(System.PByte(infotable) + Ofs);
end;

type pixel_t = byte;
const FRACUNIT = 65536;
var windowWidth, sp_count, sp_frac, sp_fracstep, sp_loopvalue: integer; sp_dest, sp_source, sp_colormap: PByteArray;
procedure ScaleMaskedPost;
var
  color: pixel_t;
begin
  sp_dest := @sp_dest[-windowWidth * (sp_count - 1)];     // go to the top
  while sp_count > 0 do
  begin
    color := sp_source[sp_frac div FRACUNIT];
    if color <> 0 then
      sp_dest[0] := sp_colormap[color];
    sp_dest := @sp_dest[windowWidth];
    sp_frac := sp_frac + sp_fracstep;
    sp_frac := sp_frac and sp_loopvalue;
    dec(sp_count);
  end;
end;
function SmallAt(P: PByteArray; O: Integer): Integer;
begin
  Result := SmallInt(P[O] or (P[O + 1] shl 8));
end;

var
  Out: TStringList;
  I, N, Startsp, Endsp, Startfl, Endfl, Startwl, Endwl, Kind, J, X, Y: Integer;
  Data: PByteArray;
  Sz, W, H, Hh, Cnt, Ofs: Integer;
  Buf: TBytes;
  Pal: PByteArray;
  Ok: Boolean;
  Ident: array[0..255] of Byte;
  Top, Bottom: Integer;
  Names: string;
  F: file;
  Plane: array[0..4095] of Byte;
  P: Integer;
begin
  Out := TStringList.Create;
  CA_InitFile(ParamStr(1));
  Out.Add(Format('H %d %d %d', [fileinfo.numlumps, fileinfo.infotableofs, fileinfo.infotablesize]));
  Startsp := CA_CheckNamedNum('startsprites'); Endsp := CA_CheckNamedNum('endsprites');
  Startfl := CA_CheckNamedNum('startflats'); Endfl := CA_CheckNamedNum('endflats');
  Startwl := CA_CheckNamedNum('startwalls'); Endwl := CA_CheckNamedNum('endwalls');
  Out.Add(Format('R %d %d %d %d %d %d', [Startsp, Endsp, Startfl, Endfl, Startwl, Endwl]));
  for I := 0 to 255 do Ident[I] := I;
  for I := 0 to fileinfo.numlumps - 1 do
  begin
    if infotable[I].size > 0 then Data := CA_CacheLump(I) else Data := nil;
    Out.Add(Format('L %d %s %d %d %d %s %d', [I, '"' + string(NameOf(I)) + '"', infotable[I].filepos,
      infotable[I].size, infotable[I].compress, Crc(Data, infotable[I].size), CA_CheckNamedNum(string(NameOf(I)))]));
    if NameOf(I) = '' then
      Continue;
  end;
  // palette
  N := CA_CheckNamedNum('palette');
  if N >= 0 then
  begin
    Pal := CA_CachePalette(N);
    Out.Add(Format('K %d %s', [N, Crc(Pal, 768)]));
  end;
  for I := 0 to fileinfo.numlumps - 1 do
  begin
    Sz := infotable[I].size;
    if Sz = 0 then Continue;
    Data := CA_CacheLump(I);
    if (Startwl >= 0) and (I > Startwl) and (I < Endwl) then
    begin
      // wall: LoadTextures: size := wall[0]*4; colonna x a base[size * x]
      H := Data[0] * 4;
      Ok := (H > 0) and (Sz >= 65 * 2 + 64 * H);
      if not Ok then begin Out.Add(Format('x W %d %d', [I, Sz])); Continue; end;
      SetLength(Buf, 64 * H);
      for Y := 0 to H - 1 do
        for X := 0 to 63 do
          Buf[Y * 64 + X] := Data[65 * 2 + H * X + Y];
      Out.Add(Format('W %d 64 %d %d %s', [I, H, Sz, Crc(@Buf[0], Length(Buf))]));
    end
    else if (Startfl >= 0) and (I > Startfl) and (I < Endfl) then
    begin
      if Sz < 4096 then begin Out.Add(Format('x F %d %d', [I, Sz])); Continue; end;
      Out.Add(Format('F %d %d %s', [I, Sz, Crc(Data, 4096)]));
    end
    else if (Startsp >= 0) and (I > Startsp) and (I < Endsp) then
    begin
      // sprite: scalepic_t, colonne disegnate con ScaleMaskedPost originale (fracstep 1.0, colormap identita')
      if Sz < 4 then begin Out.Add(Format('x S %d %d', [I, Sz])); Continue; end;
      W := SmallAt(Data, 2);
      Ok := (W > 0) and (4 + 2 * W <= Sz);
      Hh := 0;
      if Ok then
        for X := 0 to W - 1 do
        begin
          Ofs := SmallAt(Data, 4 + 2 * X);
          if Ofs = 0 then Continue;
          if (Ofs < 0) or (Ofs + 2 > Sz) then begin Ok := False; Break; end;
          Top := Data[Ofs]; Bottom := Data[Ofs + 1];
          if (Top < Bottom) or (Ofs + 2 + (Top - Bottom) > Sz) then begin Ok := False; Break; end;
          if Top > Hh then Hh := Top;
        end;
      if not Ok then begin Out.Add(Format('x S %d %d', [I, Sz])); Continue; end;
      if Hh = 0 then begin Out.Add(Format('S %d %d %d %d 0 00000000', [I, SmallAt(Data, 0), W, 0])); Continue; end;
      SetLength(Buf, W * Hh);
      FillChar(Buf[0], Length(Buf), 0);
      windowWidth := W;
      sp_colormap := @Ident;
      sp_fracstep := FRACUNIT;
      sp_loopvalue := 256 * FRACUNIT - 1;
      for X := 0 to W - 1 do
      begin
        Ofs := SmallAt(Data, 4 + 2 * X);
        if Ofs = 0 then Continue;
        Top := Data[Ofs]; Bottom := Data[Ofs + 1];
        sp_count := Top - Bottom;
        if sp_count <= 0 then Continue;
        sp_dest := @Buf[(Hh - 1 - Bottom) * W + X];
        sp_source := @Data[Ofs + 2];
        sp_frac := 0;
        ScaleMaskedPost;
      end;
      Out.Add(Format('S %d %d %d %d %d %s', [I, SmallAt(Data, 0), W, Hh, Sz, Crc(@Buf[0], Length(Buf))]));
    end
    else if (I <> N) and (Sz >= 8) then
    begin
      // pic_t
      W := SmallAt(Data, 0); H := SmallAt(Data, 2);
      if (W > 0) and (H > 0) and (8 + W * H = Sz) then
        Out.Add(Format('P %d %d %d %d %d %s', [I, W, H, SmallAt(Data, 4), SmallAt(Data, 6), Crc(@Data[8], W * H)]));
    end;
  end;
  Out.SaveToFile(ParamStr(2));
  Out.Clear;
  // mappe: DoLoadMapData originale (18 piani da 4096 letti uno dopo l'altro) da file .LAY
  for P := 3 to ParamCount do
  begin
    if not fopen(F, ParamStr(P), fOpenReadOnly) then
    begin
      Out.Add('M ' + ExtractFileName(ParamStr(P)) + ' open-failed');
      Continue;
    end;
    Names := '';
    Out.Add(Format('M %s %d', [UpperCase(ExtractFileName(ParamStr(P))), 0]));
    for I := 0 to 17 do
    begin
      fread(@Plane, 4096, 1, F);
      Out.Add(Format('M %s %d %s', [UpperCase(ExtractFileName(ParamStr(P))), I, Crc(@Plane, 4096)]));
    end;
    closefile(F);
  end;
  if Out.Count > 0 then
    Out.SaveToFile(ParamStr(2) + '.maps');
end.





