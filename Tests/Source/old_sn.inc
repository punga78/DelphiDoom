function OldDoomGetSaveName(name: string): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Ord(load_end) - 1 do
  begin
    if name = itoa(i) then
    begin
      sprintf(result, D_GetSavePath + SAVEGAMENAME + '%s.dsg', [name]);
      exit;
    end;
  end;

  if strupper(Copy(name, length(name) - 3, 4)) <> '.DSG' then
    result := name + '.DSG'
  else
    result := name;
end;
function OldHereticGetSaveName(name: string): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Ord(load_end) - 1 do
  begin
    if name = itoa(i) then
    begin
      sprintf(result, D_GetSavePath + SAVEGAMENAME + '%s.dsg', [name]);
      exit;
    end;
  end;

  if strupper(Copy(name, length(name) - 3, 4)) <> '.DSG' then
    result := name + '.DSG'
  else
    result := name;
end;
