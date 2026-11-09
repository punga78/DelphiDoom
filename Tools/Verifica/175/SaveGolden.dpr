program SaveGolden;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: usa il player_t, il SoundCard_s e il pevent_t ORIGINALI di xGreed (protos_h.pas)
// per produrre Tests\Data\Greed\save.golden.txt.
// Uso: SaveGolden <uscita.txt>   (compilare con le unit di Reference\xGreed\Greed nel percorso)
uses
  SysUtils, Classes, protos_h;

function Fnv(const P: Pointer; N: Integer): string;
var
  H: Cardinal;
  I: Integer;
begin
  H := $811C9DC5;
  for I := 0 to N - 1 do
    H := (H xor PByte(PByte(P) + I)^) * 16777619;
  Result := LowerCase(IntToHex(H, 8));
end;

var
  P: player_t;
  S: SoundCard_s;
  E: pevent_t;
  L: TStringList;
  I: Integer;
  Base: PByte;

procedure Off(const Name: string; const F: Pointer; const Base: PByte);
begin
  L.Add(Format('O %s %d', [Name, PByte(F) - Base]));
end;

begin
  L := TStringList.Create;
  FillChar(P, SizeOf(P), 0);
  P.x := 1; P.y := 2; P.z := 3; P.mapspot := 4; P.angle := 5; P.height := 6; P.currentweapon := 7;
  P.shield := 8; P.angst := 9; P.maxshield := 10; P.maxangst := 11; P.map := 12; P.mission := 13;
  P.chartype := 14; P.levelscore := 15; P.difficulty := 16;
  for I := 0 to 4 do P.weapons[I] := 100 + I;
  for I := 0 to 2 do P.ammo[I] := 200 + I;
  P.bodycount := 17; P.timecount := 18; P.score := 19;
  for I := 0 to 4095 do
  begin
    P.northmap[I] := I and 255; P.westmap[I] := (I + 1) and 255; P.northwall[I] := (I + 2) and 255;
    P.westwall[I] := (I + 3) and 255; P.savesprites[I] := (I + 4) and 255;
  end;
  P.scrollmin := 20; P.scrollmax := 21;
  for I := 0 to 1 do P.primaries[I] := 300 + I;
  for I := 0 to 6 do P.secondaries[I] := 400 + I;
  for I := 0 to MAXPLAYERS - 1 do P.frags[I] := 500 + I;
  P.runmod := 22; P.walkmod := 23;
  for I := 0 to MAXINVENTORY - 1 do P.inventory[I] := 600 + I;
  P.status := 24; P.holopic := 25; P.holoscale := 26; P.jumpmod := 27;
  for I := 0 to 255 do P.events[I] := (I * 7) and 255;
  L.Add(Format('S player_t %d %s', [SizeOf(P), Fnv(@P, SizeOf(P))]));
  Base := @P;
  Off('x', @P.x, Base); Off('mapspot', @P.mapspot, Base); Off('weapons', @P.weapons, Base);
  Off('ammo', @P.ammo, Base); Off('bodycount', @P.bodycount, Base); Off('northmap', @P.northmap, Base);
  Off('westmap', @P.westmap, Base); Off('northwall', @P.northwall, Base); Off('westwall', @P.westwall, Base);
  Off('savesprites', @P.savesprites, Base); Off('scrollmin', @P.scrollmin, Base);
  Off('primaries', @P.primaries, Base); Off('secondaries', @P.secondaries, Base); Off('frags', @P.frags, Base);
  Off('runmod', @P.runmod, Base); Off('inventory', @P.inventory, Base); Off('status', @P.status, Base);
  Off('jumpmod', @P.jumpmod, Base); Off('events', @P.events, Base);

  FillChar(E, SizeOf(E), 0);
  E.id := 1; E.playerid := 2; E.x := 3; E.y := 4; E.z := 5; E.angle := 6; E.angst := 7; E.chartype := 8;
  E.status := 9; E.holopic := 10; E.holoscale := 11; E.height := 12; E.specialeffect := 13;
  L.Add(Format('S pevent_t %d %s', [SizeOf(E), Fnv(@E, SizeOf(E))]));

  L.SaveToFile(ParamStr(1));
end.
