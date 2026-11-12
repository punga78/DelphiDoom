unit d_video;
interface
type
  pic_t = packed record
    width: smallint;
    height: smallint;
    orgx: smallint;
    orgy: smallint;
    data: byte;
  end;
  Ppic_t = ^pic_t;
implementation
end.
