procedure OldDoomCmdNewGame(const parm1, parm2: string; var epsd, map: Integer);
var
  mapname: string;
begin
  mapname := strupper(parm1);

  if gamemode = commercial then
  begin
    epsd := 0;
    map := atoi(parm1);
    if (mapname[1] = 'M') then
      if length(mapname) = 5 then
        if (mapname[2] = 'A') and
           (mapname[3] = 'P') then
          map := atoi(mapname[4] + mapname[5]);
  end
  else
  begin
    epsd := atoi(parm1);
    map := atoi(parm2);
    if parm2 = '' then
      if (mapname[1] = 'E') then
        if length(mapname) = 4 then
          if (mapname[3] = 'M') then
          begin
            epsd := atoi(mapname[2]);
            map := atoi(mapname[4]);
          end;
  end;

end;

procedure OldHereticCmdNewGame(const parm1, parm2: string; var epsd, map: Integer);
var
  mapname: string;
begin
  mapname := strupper(parm1);

  epsd := atoi(parm1);
  map := atoi(parm2);
  if parm2 = '' then
    if (mapname[1] = 'E') then
      if length(mapname) = 4 then
        if (mapname[3] = 'M') then
        begin
          epsd := atoi(mapname[2]);
          map := atoi(mapname[4]);
        end;

end;

procedure OldStrifeCmdNewGame(const parm1, parm2: string; var epsd, map: Integer);
var
  mapname: string;
begin
  mapname := strupper(parm1);

  map := atoi(parm1);
  if (mapname[1] = 'M') then
    if length(mapname) = 5 then
      if (mapname[2] = 'A') and
         (mapname[3] = 'P') then
        map := atoi(mapname[4] + mapname[5]);

end;

