procedure OldDoomNext;
begin
  // wminfo.next is 0 biased, unlike gamemap
  if gamemode = commercial then
  begin
    if secretexit then
    begin
      case gamemap of
         2: if customgame = cg_bfg2 then wminfo.next := 32 else wminfo.next := gamemap;
        15: wminfo.next := 30;
        31: wminfo.next := 31;
      end
    end
    else
    begin
      case gamemap of
        31,
        32: wminfo.next := 15;
        33: if customgame = cg_bfg2 then wminfo.next := 2 else wminfo.next := gamemap;
      else
        wminfo.next := gamemap;
      end;
    end
  end
  else
  begin
    if secretexit then
      wminfo.next := 8  // go to secret level
    else if gamemap = 9 then
    begin
      // returning from secret level
      case gameepisode of
        1: wminfo.next := 3;
        2: wminfo.next := 5;
        3: wminfo.next := 6;
        4: wminfo.next := 2;
      end
    end
    else
      wminfo.next := gamemap; // go to next level
  end;

  if gamemode = commercial then
end;

procedure OldHereticNext;
begin
  if secretexit then
    wminfo.next := 8  // go to secret level
  else if gamemap = 9 then
  begin
    // returning from secret level
    case gameepisode of
      1: wminfo.next := 7;
      2: wminfo.next := 5;
      3: wminfo.next := 5;
      4: wminfo.next := 5;
      5: wminfo.next := 4;
    end
  end
  else
    wminfo.next := gamemap; // go to next level
;
end;
