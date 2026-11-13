{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - types of the network of Quake III                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): qcommon.h,      }
{  q_shared.h, msg.c, net_chan.c. Copyright (C) 1999-2005 id Software, Inc.    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>GENTITYNUM_BITS: the bits of an entity number on the wire</summary>
  Q3_GENTITYNUM_BITS = 10;
  /// <summary>MAX_GENTITIES</summary>
  Q3_MAX_GENTITIES = 1 shl Q3_GENTITYNUM_BITS;
  /// <summary>MAX_STRING_CHARS: the size of the buffer of MSG_ReadString (one character is the terminator)</summary>
  Q3_MAX_STRING_CHARS = 1024;
  /// <summary>BIG_INFO_STRING: the size of the buffer of MSG_ReadBigString</summary>
  Q3_BIG_INFO_STRING = 8192;
  /// <summary>MAX_MSGLEN: the longest message, which may be fragmented into several packets</summary>
  Q3_MAX_MSGLEN = 16384;
  /// <summary>MAX_PACKETLEN: the longest datagram</summary>
  Q3_MAX_PACKETLEN = 1400;
  /// <summary>FRAGMENT_SIZE: the data of a full fragment (MAX_PACKETLEN - 100)</summary>
  Q3_FRAGMENT_SIZE = Q3_MAX_PACKETLEN - 100;
  /// <summary>FRAGMENT_BIT: the high bit of the sequence number, set on the fragments of a long message</summary>
  Q3_FRAGMENT_BIT = Integer($80000000);
  /// <summary>HMAX: the largest symbol of the adaptive Huffman tree</summary>
  Q3_HUFFMAN_MAX = 256;
  /// <summary>NYT: the "not yet transmitted" node of the tree</summary>
  Q3_HUFFMAN_NYT = Q3_HUFFMAN_MAX;
  /// <summary>INTERNAL_NODE: the symbol of the nodes that are not leaves</summary>
  Q3_HUFFMAN_INTERNAL_NODE = Q3_HUFFMAN_MAX + 1;
  /// <summary>FLOAT_INT_BITS: a float that is a small integer is sent with these bits</summary>
  Q3_FLOAT_INT_BITS = 13;
  /// <summary>FLOAT_INT_BIAS: added to a small integer float to make it positive</summary>
  Q3_FLOAT_INT_BIAS = 1 shl (Q3_FLOAT_INT_BITS - 1);

  Q3_MAX_STATS = 16;
  Q3_MAX_PERSISTANT = 16;
  Q3_MAX_POWERUPS = 16;
  Q3_MAX_WEAPONS = 16;
  Q3_MAX_PS_EVENTS = 2;

  SQ3MessageBadBits = 'MSG_WriteBits: bad bits %d';
  SQ3MessageCannotReadBits = 'can''t read %d bits';
  SQ3MessageBufferOverrun = 'The message writes past the end of its buffer (byte %d of %d)';
  SQ3MessageBufferTooSmall = 'The length %d is larger than the buffer (%d bytes)';
  SQ3MessageBadEntityNumber = 'Bad entity number: %d';
  SQ3MessageBadFieldCount = 'The delta of a %s has %d changed fields, the largest valid number is %d';
  SQ3MessageFromRequired = 'The delta of a %s needs the state it changes from';
  SQ3HuffmanUnknownSymbol = 'The symbol %d is not in the Huffman tree';
  SQ3NetchanTooLong = 'Netchan_Transmit: length = %d';
  SQ3NetchanBufferTooSmall = 'The message buffer holds %d bytes but the reassembled message needs %d';

type
  /// <summary>The base class of the errors of the network of Quake III</summary>
  EQ3NetException = class(Exception);

  /// <summary>
  ///   A message that cannot be built: a bad number of bits, an entity number out of range, a corrupt
  ///   delta (<c>Com_Error</c> of msg.c)
  /// </summary>
  EQ3MessageException = class(EQ3NetException);

  /// <summary>
  ///   A write (or a copy of a reassembled message) that would go past the end of the buffer. The original
  ///   writes outside the buffer in these cases
  /// </summary>
  EQ3MessageOverflowException = class(EQ3MessageException);

  /// <summary>The network channel refuses a message (too long): <c>Com_Error</c> of net_chan.c</summary>
  EQ3NetchanException = class(EQ3NetException);

  /// <summary>netsrc_t: who owns a network channel</summary>
  TQ3NetSource = (nsClient = 0, nsServer = 1);

  /// <summary>netadrtype_t</summary>
  TQ3NetAddressType = (
    natBot = 0,
    natBad = 1,
    natLoopback = 2,
    natBroadcast = 3,
    natIp = 4,
    natIpx = 5,
    natBroadcastIpx = 6
  );

  /// <summary>
  ///   netadr_t: 20 bytes, no padding, the same at 32 and at 64 bit. The channel does not look inside, it
  ///   gives the address back to the transport
  /// </summary>
  TQ3NetAddress = packed record
    /// <summary>A <c>TQ3NetAddressType</c>, four bytes as in C</summary>
    AddressType: Integer;
    Ip: array[0..3] of Byte;
    Ipx: array[0..9] of Byte;
    Port: Word;
  end;

  /// <summary>A float and its 32 bits (the C code reads one through a pointer to the other)</summary>
  TQ3FloatBits = record
    case Boolean of
      False: (AsSingle: Single);
      True: (AsInteger: Integer);
  end;

  /// <summary>usercmd_t: 24 bytes. The weapon is unsigned, the three moves are signed bytes</summary>
  TQ3UserCmd = packed record
    ServerTime: Integer;
    Angles: array[0..2] of Integer;
    Buttons: Integer;
    Weapon: Byte;
    ForwardMove: ShortInt;
    RightMove: ShortInt;
    UpMove: ShortInt;
  end;
  PQ3UserCmd = ^TQ3UserCmd;

  /// <summary>trajectory_t: 36 bytes (trType is an enum of 4 bytes in C)</summary>
  TQ3Trajectory = packed record
    TrType: Integer;
    TrTime: Integer;
    TrDuration: Integer;
    TrBase: array[0..2] of Single;
    TrDelta: array[0..2] of Single;
  end;

  /// <summary>
  ///   entityState_t: 52 fields of 4 bytes, 208 bytes. The delta works on the fields as 32 bit values (the
  ///   original asserts that the structure is made only of them)
  /// </summary>
  TQ3EntityState = packed record
    Number: Integer;
    EType: Integer;
    EFlags: Integer;
    Pos: TQ3Trajectory;
    Apos: TQ3Trajectory;
    Time: Integer;
    Time2: Integer;
    Origin: array[0..2] of Single;
    Origin2: array[0..2] of Single;
    Angles: array[0..2] of Single;
    Angles2: array[0..2] of Single;
    OtherEntityNum: Integer;
    OtherEntityNum2: Integer;
    GroundEntityNum: Integer;
    ConstantLight: Integer;
    LoopSound: Integer;
    ModelIndex: Integer;
    ModelIndex2: Integer;
    ClientNum: Integer;
    Frame: Integer;
    Solid: Integer;
    Event: Integer;
    EventParm: Integer;
    Powerups: Integer;
    Weapon: Integer;
    LegsAnim: Integer;
    TorsoAnim: Integer;
    Generic1: Integer;
  end;
  PQ3EntityState = ^TQ3EntityState;

  /// <summary>playerState_t: 117 fields of 4 bytes, 468 bytes</summary>
  TQ3PlayerState = packed record
    CommandTime: Integer;
    PmType: Integer;
    BobCycle: Integer;
    PmFlags: Integer;
    PmTime: Integer;
    Origin: array[0..2] of Single;
    Velocity: array[0..2] of Single;
    WeaponTime: Integer;
    Gravity: Integer;
    Speed: Integer;
    DeltaAngles: array[0..2] of Integer;
    GroundEntityNum: Integer;
    LegsTimer: Integer;
    LegsAnim: Integer;
    TorsoTimer: Integer;
    TorsoAnim: Integer;
    MovementDir: Integer;
    GrapplePoint: array[0..2] of Single;
    EFlags: Integer;
    EventSequence: Integer;
    Events: array[0..Q3_MAX_PS_EVENTS - 1] of Integer;
    EventParms: array[0..Q3_MAX_PS_EVENTS - 1] of Integer;
    ExternalEvent: Integer;
    ExternalEventParm: Integer;
    ExternalEventTime: Integer;
    ClientNum: Integer;
    Weapon: Integer;
    WeaponState: Integer;
    ViewAngles: array[0..2] of Single;
    ViewHeight: Integer;
    DamageEvent: Integer;
    DamageYaw: Integer;
    DamagePitch: Integer;
    DamageCount: Integer;
    Stats: array[0..Q3_MAX_STATS - 1] of Integer;
    Persistant: array[0..Q3_MAX_PERSISTANT - 1] of Integer;
    Powerups: array[0..Q3_MAX_POWERUPS - 1] of Integer;
    Ammo: array[0..Q3_MAX_WEAPONS - 1] of Integer;
    Generic1: Integer;
    LoopSound: Integer;
    JumppadEnt: Integer;
    // not communicated over the net at all
    Ping: Integer;
    PmoveFramecount: Integer;
    JumppadFrame: Integer;
    EntityEventSequence: Integer;
  end;
  PQ3PlayerState = ^TQ3PlayerState;

  /// <summary>
  ///   netField_t: a field of a state that the delta sends. Offset is in bytes from the start of the record,
  ///   Bits is the width of an integer (negative: signed), 0 means a float
  /// </summary>
  TQ3NetField = record
    Name: string;
    Offset: Integer;
    Bits: Integer;
  end;

implementation

end.
