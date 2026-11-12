unit modplay;
// stub of the harness: the sound is not played but written in the fingerprint of the harness (SoundEffect with its
// arguments, PlaySong with the name of the song, StopMusic). InitDefaults has the values of the original; InitSound
// does what the original does to the globals of the game, without BASS
interface
uses
  protos_h, r_public_h;
const
  MAXEFFECTS = 8;
  MAXCACHESIZE = MAXEFFECTS * 2 + 4;
  MAXSOUNDS = 90;
  MAXSOUNDDIST = 384;
  MSD = MAXSOUNDDIST * FRACUNIT;
  DEFAULTVRDIST = 157286;
  DEFAULTVRANGLE = 4;
var
  MusicPresent, MusicSwapChannels: boolean;
  SC: SoundCard;
  MusicError, EffectChan, CurrentChan, FXLump: integer;
  effecttracks: integer;
procedure PlaySong(const aname: string; const pattern: integer);
procedure StopMusic;
procedure InitDefaults;
procedure InitSound;
procedure I_ShutDownSound;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure SetVolumes(const amusic: integer; const afx: integer);
procedure UpdateSound;
implementation
uses
  constant, d_disk, d_ints_h, d_ints, raven, harness_world;
procedure PlaySong(const aname: string; const pattern: integer);
begin
  HarnessSong(aname);
end;
procedure StopMusic;
begin
  HarnessSong('');
end;
procedure InitDefaults;
begin
  SC.ambientlight := AMBIENTLIGHT;
  SC.violence := true;
  SC.animation := true;
  SC.musicvol := 100;
  SC.sfxvol := 128;
  SC.ckeys[0] := scanbuttons[bt_run];
  SC.ckeys[1] := scanbuttons[bt_jump];
  SC.ckeys[2] := scanbuttons[bt_straf];
  SC.ckeys[3] := scanbuttons[bt_fire];
  SC.ckeys[4] := scanbuttons[bt_use];
  SC.ckeys[5] := scanbuttons[bt_useitem];
  SC.ckeys[6] := scanbuttons[bt_asscam];
  SC.ckeys[7] := scanbuttons[bt_lookup];
  SC.ckeys[8] := scanbuttons[bt_lookdown];
  SC.ckeys[9] := scanbuttons[bt_centerview];
  SC.ckeys[10] := scanbuttons[bt_slideleft];
  SC.ckeys[11] := scanbuttons[bt_slideright];
  SC.ckeys[12] := scanbuttons[bt_invleft];
  SC.ckeys[13] := scanbuttons[bt_invright];
  SC.inversepan := false;
  SC.screensize := 4;
  SC.camdelay := 35;
  SC.effecttracks := 4;
  SC.mouse := 1;
  SC.joystick := 0;
  SC.chartype := 0;
  SC.socket := 1234;
  SC.numplayers := 2;
  SC.serplayers := 1;
  SC.com := 1;
  SC.rightbutton := bt_north;
  SC.leftbutton := bt_fire;
  SC.joybut1 := bt_fire;
  SC.joybut2 := bt_straf;
  SC.dialnum := '            ';
  SC.netname := '            ';
  SC.netmap := 22;
  SC.netdifficulty := 2;
  SC.turnspeed := DEF_PLAYERTURNSPEED;
  SC.turnaccel := DEF_TURNUNIT;
  SC.mousesensitivity := 10;
  SC.vrhelmet := 0;
  SC.vrangle := DEFAULTVRANGLE;
  SC.vrdist := DEFAULTVRDIST;
end;
procedure InitSound;
begin
  MusicPresent := false;
  MusicError := 0;
  FXLump := CA_GetNamedNum('SOUNDEFFECTS') + 1;
  MusicSwapChannels := SC.inversepan;
  lighting := 1;
  changelight := SC.ambientlight;
  playerturnspeed := SC.turnspeed;
  turnunit := SC.turnaccel;
  effecttracks := SC.effecttracks;
end;
procedure I_ShutDownSound;
begin
end;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  HarnessSound(n, variation, x, y);
end;
procedure SetVolumes(const amusic: integer; const afx: integer);
begin
end;
procedure UpdateSound;
begin
end;
end.
