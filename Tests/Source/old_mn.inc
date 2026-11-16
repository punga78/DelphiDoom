function OldDoomValidateMapName(const amap: string; const pepi, pmapnum: PInteger): boolean;
var
  epi, mapnum: integer;
  len: integer;
  map: string;
begin
  result := false;
  len := Length(amap);
  if not len in [4, 5] then
    exit;

  epi := 0;
  mapnum := 0;
  map := strupper(amap);

  if (map[1] = 'E') and (map[3] = 'M') then
  begin
    if len = 4 then
    begin
      if not isdigit(map[2]) then
        exit;
      epi := atoi(map[2]);
      mapnum := atoi(map[4]);
      result := IsIntegerInRange(epi, 1, 8) and IsIntegerInRange(mapnum, 1, 9);
    end;
  end
  else if (map[1] = 'M') and (map[2] = 'A') and (map[3] = 'P') then
  begin
    if len = 5 then
    begin
      mapnum := atoi(map[4] + map[5]);
      result := IsIntegerInRange(mapnum, 1, 99);
    end;
  end;

  if result then
  begin
    if pepi <> nil then
      pepi^ := epi;
    if pmapnum <> nil then
      pmapnum^ := mapnum;
  end;
end;

function OldHereticValidateMapName(const amap: string; const pepi, pmapnum: PInteger): boolean;
var
  epi, mapnum: integer;
  len: integer;
  map: string;
begin
  result := false;
  len := Length(amap);
  if len <> 4 then
    exit;
  epi := 0;
  mapnum := 0;
  map := strupper(amap);
  if (map[1] = 'E') and (map[3] = 'M') then
  begin
    if not isdigit(map[2]) then
      exit;
    epi := atoi(map[2]);
    mapnum := atoi(map[4]);
    result := IsIntegerInRange(epi, 1, 8) and IsIntegerInRange(mapnum, 1, 9);
  end;

  if result then
  begin
    if pepi <> nil then
      pepi^ := epi;
    if pmapnum <> nil then
      pmapnum^ := mapnum;
  end;
end;

function OldStrifeValidateMapName(const amap: string; const pepi, pmapnum: PInteger): boolean;
var
  epi, mapnum: integer;
  len: integer;
  map: string;
begin
  result := false;
  len := Length(amap);
  if len <> 5 then
    exit;

  epi := 0;
  mapnum := 0;
  map := strupper(amap);

  if (map[1] = 'E') and (map[3] = 'M') then
  begin
    if len = 5 then
    begin
      if not isdigit(map[2]) then
        exit;
      epi := atoi(map[2]);
      mapnum := atoi(map[4]);
      result := IsIntegerInRange(epi, 1, 8) and IsIntegerInRange(mapnum, 1, 9);
    end;
  end
  else if (map[1] = 'M') and (map[2] = 'A') and (map[3] = 'P') then
  begin
    if len = 5 then
    begin
      mapnum := atoi(map[4] + map[5]);
      result := IsIntegerInRange(mapnum, 1, 99);
    end;
  end;

  if result then
  begin
    if pepi <> nil then
      pepi^ := epi;
    if pmapnum <> nil then
      pmapnum^ := mapnum;
  end;
end;

