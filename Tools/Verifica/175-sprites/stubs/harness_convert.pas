unit harness_convert;
// harness: scaleobj_t and doorobj_t of the original as the records of the library, and the trace that the stubs
// of the rest of the game write to (the same values that TFakeSpriteGame writes on the side of the library)
interface
uses
  r_public_h, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Tests.Greed.SpriteScenarios;
var
  HarnessTrace: TSpriteTrace;
function ToLibrary(const s: scaleobj_t): TGreedSprite;
procedure FromLibrary(const g: TGreedSprite; const s: Pscaleobj_t);
function DoorToLibrary(const d: doorobj_t): TGreedDoor;
implementation

function ToLibrary(const s: scaleobj_t): TGreedSprite;
begin
  Result.Animation := s.animation;
  Result.AnimationTime := s.animationTime;
  Result.MoveSpeed := s.moveSpeed;
  Result.ZAdjust := s.zadj;
  Result.X := s.x; Result.Y := s.y; Result.Z := s.z;
  Result.LastX := s.lastx; Result.LastY := s.lasty;
  Result.BasePic := s.basepic;
  Result.Rotate := TGreedRotate(Ord(s.rotate));
  Result.Angle := s.angle; Result.Angle2 := s.angle2;
  Result.MoveSize := s.movesize;
  Result.Active := s.active;
  Result.NoFalling := s.nofalling;
  Result.Intelligence := s.intelligence;
  Result.Bullet := s.bullet;
  Result.Enraged := s.enraged;
  Result.MoveTime := s.movetime;
  Result.ModeTime := s.modetime;
  Result.ActionTime := s.actiontime;
  Result.ScanTime := s.scantime;
  Result.FireTime := s.firetime;
  Result.Heat := s.heat;
  Result.StartPic := s.startpic;
  Result.MoveMode := s.movemode;
  Result.StartSpot := s.startspot;
  Result.Damage := s.damage;
  Result.HitPoints := s.hitpoints;
  Result.Kind := s.typ;
  Result.SpawnId := s.spawnid;
  Result.Score := s.score;
  Result.MaxMove := s.maxmove;
  Result.Regen := s.regen;
  Result.DeathEvent := s.deathevent;
  Result.Height := s.height;
  Result.SpecialType := TGreedSpecialType(Ord(s.specialtype));
  Result.Scale := s.scale;
  Result.OldX := s.oldx; Result.OldY := s.oldy; Result.OldZ := s.oldz;
  Result.OldAngle := s.oldangle; Result.OldAngle2 := s.oldangle2; Result.OldFloorZ := s.oldfloorz;
  Result.NewX := s.newx; Result.NewY := s.newy; Result.NewZ := s.newz;
  Result.NewAngle := s.newangle; Result.NewAngle2 := s.newangle2; Result.NewFloorZ := s.newfloorz;
  Result.Grounded := s.grounded;
end;

procedure FromLibrary(const g: TGreedSprite; const s: Pscaleobj_t);
begin
  s.animation := g.Animation;
  s.animationTime := g.AnimationTime;
  s.moveSpeed := g.MoveSpeed;
  s.zadj := g.ZAdjust;
  s.x := g.X; s.y := g.Y; s.z := g.Z;
  s.lastx := g.LastX; s.lasty := g.LastY;
  s.basepic := g.BasePic;
  s.rotate := rotate_t(Ord(g.Rotate));
  s.angle := g.Angle; s.angle2 := g.Angle2;
  s.movesize := g.MoveSize;
  s.active := g.Active;
  s.nofalling := g.NoFalling;
  s.intelligence := g.Intelligence;
  s.bullet := g.Bullet;
  s.enraged := g.Enraged;
  s.movetime := g.MoveTime;
  s.modetime := g.ModeTime;
  s.actiontime := g.ActionTime;
  s.scantime := g.ScanTime;
  s.firetime := g.FireTime;
  s.heat := g.Heat;
  s.startpic := g.StartPic;
  s.movemode := g.MoveMode;
  s.startspot := g.StartSpot;
  s.damage := g.Damage;
  s.hitpoints := g.HitPoints;
  s.typ := g.Kind;
  s.spawnid := g.SpawnId;
  s.score := g.Score;
  s.maxmove := g.MaxMove;
  s.regen := g.Regen;
  s.deathevent := g.DeathEvent;
  s.height := g.Height;
  s.specialtype := special_t(Ord(g.SpecialType));
  s.scale := g.Scale;
  s.oldx := g.OldX; s.oldy := g.OldY; s.oldz := g.OldZ;
  s.oldangle := g.OldAngle; s.oldangle2 := g.OldAngle2; s.oldfloorz := g.OldFloorZ;
  s.newx := g.NewX; s.newy := g.NewY; s.newz := g.NewZ;
  s.newangle := g.NewAngle; s.newangle2 := g.NewAngle2; s.newfloorz := g.NewFloorZ;
  s.grounded := g.Grounded;
end;

function DoorToLibrary(const d: doorobj_t): TGreedDoor;
begin
  Result.TileX := d.tilex;
  Result.TileY := d.tiley;
  Result.Open := d.doorOpen;
  Result.Opening := d.doorOpening;
  Result.Closing := d.doorClosing;
  Result.Blocked := d.doorBlocked;
  Result.Bumpable := d.doorBumpable;
  Result.Size := d.doorSize;
  Result.Timer := d.doorTimer;
  Result.Locks := d.doorLocks;
  Result.Orientation := TGreedDoorOrientation(Ord(d.orientation));
  Result.Transparent := d.transparent;
  Result.Pic := d.pic;
  Result.Height := d.height;
  Result.Position := d.position;
end;

end.
