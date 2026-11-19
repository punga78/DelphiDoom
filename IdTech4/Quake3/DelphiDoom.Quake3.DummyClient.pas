{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - a client with no screen                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): CL_Connect_f,   }
{  CL_CheckForResend, CL_WritePacket (cl_main.c, cl_input.c). Copyright (C)    }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Quake3.DummyClient;

// Overflow and range checks are off: the time and the angle are 32 bit ints of the C.

interface

uses
  System.SysUtils, DelphiDoom.Net.Transport.Intf, DelphiDoom.Console.Q3.Intf, DelphiDoom.Net.Q3.Intf,
  DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Net.Q3.ServerMessageParser,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.ClientState, DelphiDoom.Q3Host.ClientPacketWriter,
  DelphiDoom.Q3Host.ClientNetwork, DelphiDoom.Q3Host.Server;

type
  /// <summary>Where the dummy client is on its way into the game</summary>
  TQ3DummyClientPhase = (
    /// <summary>The server has no level yet</summary>
    Waiting,
    /// <summary>getchallenge and connect are going back and forth</summary>
    Connecting,
    /// <summary>Connected: the first packet is out, the gamestate (in fragments) is on its way</summary>
    Loading,
    /// <summary>The gamestate is in: a packet with a command goes every frame and the snapshots come</summary>
    Playing);

  /// <summary>
  ///   The client of a server in the same process, without a screen, a sound or a cgame: it joins over the
  ///   network of the process (the netchan of both sides on a wire in memory), takes the gamestate and the
  ///   snapshots through the parser of the messages and every frame sends a user command that walks forward and
  ///   turns, so the player is in the game and the bots have somebody to see. What the C does in CL_Frame
  ///   splits in two calls to be put around the frame of the server: SendFrame before it and ReceiveFrame after
  /// </summary>
  TQ3DummyClient = class
  strict private
    const
      // cl_guid: OpenArena refuses a connect without one
      USERINFO = '\name\Dummy\model\sarge\rate\25000\cl_voip\0\cl_guid\0123456789ABCDEF0123456789ABCDEF';
      PROTOCOL = 68;
      QPORT = 1234;
    var
      FServer: TQ3Server;
      FState: TQ3ClientState;
      FStateIntf: IQ3HostClientState;
      FSink: IInterface;
      FEntityCodec: TQ3EntityStateCodec;
      FPlayerCodec: TQ3PlayerStateCodec;
      FCoder: IQ3HuffmanCoder;
      FParser: TQ3ServerMessageParser;
      FWriter: TQ3ClientPacketWriter;
      FNetwork: TQ3ClientNetwork;
      FPhase: TQ3DummyClientPhase;
      FFrames: Integer;
      FSnapshots: Integer;
      FLastSnapshot: Integer;
      FEntities: Integer;
    procedure AddWalkCommand;
    procedure CountSnapshot;
  public
    /// <summary>
    ///   The client speaks on ATransport (node 1 is the server) with the coder the server uses; it asks the server
    ///   only for its time. The arguments are the console's (the C has one tokenizer for everybody)
    /// </summary>
    constructor Create(const AServer: TQ3Server; const ATransport: INetTransport;
      const AArguments: IQ3CommandArguments; const ACoder: IQ3HuffmanCoder);
    destructor Destroy; override;
    /// <summary>The first half of the frame: the connection goes on, or a packet with a command goes to the server</summary>
    procedure SendFrame;
    /// <summary>The second half of the frame: what the server sent is read</summary>
    procedure ReceiveFrame;
    property Phase: TQ3DummyClientPhase read FPhase;
    property State: TQ3ClientState read FState;
    /// <summary>The frames with a command that were sent</summary>
    property Frames: Integer read FFrames;
    /// <summary>The snapshots that came (each snapshot number counts once)</summary>
    property Snapshots: Integer read FSnapshots;
    /// <summary>The entities in the last snapshot</summary>
    property Entities: Integer read FEntities;
  end;

implementation

uses
  DelphiDoom.Net.Q3.Factory, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.ClientMessageSink,
  DelphiDoom.Net.Q3.ServerMessage.Intf;

{ TQ3DummyClient }

constructor TQ3DummyClient.Create(const AServer: TQ3Server; const ATransport: INetTransport;
  const AArguments: IQ3CommandArguments; const ACoder: IQ3HuffmanCoder);
begin
  inherited Create;
  FServer := AServer;
  FCoder := ACoder;
  FState := TQ3ClientState.Create(AArguments);
  FStateIntf := FState;
  FSink := TQ3ClientMessageSink.Create(FState);
  FEntityCodec := TQ3NetFactory.CreateEntityStateCodec;
  FPlayerCodec := TQ3NetFactory.CreatePlayerStateCodec;
  FParser := TQ3NetFactory.CreateServerMessageParser(FCoder, FEntityCodec, FPlayerCodec,
    FSink as IQ3ServerMessageSink);
  FWriter := TQ3ClientPacketWriter.Create(FState, FCoder);
  FNetwork := TQ3ClientNetwork.Create(ATransport, 1, True, FState, FParser, FWriter, AArguments, FCoder);
  FLastSnapshot := -1;
  FPhase := TQ3DummyClientPhase.Waiting;
end;

destructor TQ3DummyClient.Destroy;
begin
  FNetwork.Free;
  FWriter.Free;
  FParser.Free;
  FEntityCodec.Free;
  FPlayerCodec.Free;
  FSink := nil;
  FStateIntf := nil;
  inherited Destroy;
end;

procedure TQ3DummyClient.AddWalkCommand;
var
  LCommand: TQ3HostUserCmd;
begin
  LCommand := Default(TQ3HostUserCmd);
  // usercmd_t: serverTime, angles[3], buttons, weapon, forwardmove, rightmove, upmove
  PInteger(@LCommand[0])^ := FServer.Time + 50;
  // the yaw turns about 1.4 degrees a frame
  PInteger(@LCommand[8])^ := (FFrames * 256) and $FFFF;
  LCommand[21] := 100;
  FState.AddUserCommand(LCommand);
end;

procedure TQ3DummyClient.CountSnapshot;
var
  LNumber, LTime: Integer;
  LSnapshot: TQ3HostSnapshot;
begin
  FState.CurrentSnapshotNumber(LNumber, LTime);
  if (LNumber <> FLastSnapshot) and FState.TryGetSnapshot(LNumber, LSnapshot) then
  begin
    FLastSnapshot := LNumber;
    Inc(FSnapshots);
    FEntities := LSnapshot.NumEntities;
  end;
end;

procedure TQ3DummyClient.SendFrame;
begin
  case FPhase of
    TQ3DummyClientPhase.Waiting:
      if FServer.IsRunning then
      begin
        FNetwork.Connect(AnsiString(USERINFO), PROTOCOL, QPORT);
        FPhase := TQ3DummyClientPhase.Connecting;
      end;
    TQ3DummyClientPhase.Connecting:
      if FNetwork.Connection = TQ3ClientConnection.Connected then
      begin
        // the first packet has a server id that is not the server's: the gamestate comes back
        FNetwork.SendPacket;
        FPhase := TQ3DummyClientPhase.Loading;
      end;
    TQ3DummyClientPhase.Loading:
      // a gamestate that is longer than a datagram comes in pieces, one for each frame of the server
      FNetwork.SendPacket;
    TQ3DummyClientPhase.Playing:
      begin
        Inc(FFrames);
        AddWalkCommand;
        FNetwork.SendPacket;
      end;
  end;
end;

procedure TQ3DummyClient.ReceiveFrame;
begin
  FNetwork.Poll;
  if (FPhase = TQ3DummyClientPhase.Loading) and (FState.ConfigString(1) <> '') then
    FPhase := TQ3DummyClientPhase.Playing;
  if FPhase = TQ3DummyClientPhase.Playing then
    CountSnapshot;
end;

end.
