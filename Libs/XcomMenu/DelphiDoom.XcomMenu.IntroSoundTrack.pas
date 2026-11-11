{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - the sound track of the introduction of UFO   }
{  (the tables of VideoState.cpp of OpenXcom)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.IntroSoundTrack;

interface

const
  /// <summary>A command with this bit starts a music ($200 GMINTRO1, $201 GMINTRO2, $202 GMINTRO3)</summary>
  XCOM_INTRO_COMMAND_MUSIC = $200;
  /// <summary>A command with this bit sets the speed of the animation to its low byte</summary>
  XCOM_INTRO_COMMAND_SPEED = $400;
  /// <summary>The commands up to this one are sounds: an index of the tables of sounds</summary>
  XCOM_INTRO_LAST_SOUND = $19;
  XCOM_INTRO_SOUND_COUNT = XCOM_INTRO_LAST_SOUND + 1;
  XCOM_INTRO_TRACK_COUNT = 132;
  XCOM_INTRO_SOUND_SETS = 3;

type
  /// <summary>soundInFile: a sound of a CAT file and the volume of its channel (0..128)</summary>
  TXcomIntroSound = record
    CatFile: string;
    Sound: Integer;
    Volume: Integer;
  end;

  /// <summary>introSoundEffect: what happens when the animation gets to a frame</summary>
  TXcomIntroSoundEffect = record
    Frame: Integer;
    Command: Integer;
  end;

  TXcomIntroSoundTable = array[0..XCOM_INTRO_SOUND_COUNT - 1] of TXcomIntroSound;

const
  /// <summary>
  ///   introSounds: the tables to try in order for a sound command: the mix of the two versions, then INTRO.CAT
  ///   alone (DOS), then SAMPLE3.CAT alone (Windows)
  /// </summary>
  XCOM_INTRO_SOUNDS: array[0..XCOM_INTRO_SOUND_SETS - 1] of TXcomIntroSoundTable = ((
    (CatFile: 'SAMPLE3.CAT'; Sound: 24; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 5; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 23; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 3; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 4; Volume: 64),
    (CatFile: 'INTRO.CAT'; Sound: 5; Volume: 64),
    (CatFile: 'INTRO.CAT'; Sound: 6; Volume: 64),
    (CatFile: 'INTRO.CAT'; Sound: 7; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 8; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 11; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 4; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 11; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 19; Volume: 48),
    (CatFile: 'INTRO.CAT'; Sound: 13; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 14; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 30; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 21; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 17; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 13; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 14; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 19; Volume: 64),
    (CatFile: 'INTRO.CAT'; Sound: 21; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 15; Volume: 128),
    (CatFile: 'SAMPLE3.CAT'; Sound: 12; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 18; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 20; Volume: 32)
  ), (
    (CatFile: 'INTRO.CAT'; Sound: 0; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 1; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 2; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 3; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 4; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 5; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 6; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 7; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 8; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 9; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 10; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 11; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 12; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 13; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 14; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 15; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 16; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 17; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 18; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 19; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 20; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 21; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 22; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 23; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 24; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 24; Volume: 32)
  ), (
    (CatFile: 'SAMPLE3.CAT'; Sound: 24; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 5; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 23; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 6; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 9; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 7; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 27; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 4; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 8; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 11; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 4; Volume: 32),
    (CatFile: 'INTRO.CAT'; Sound: 11; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 19; Volume: 48),
    (CatFile: 'INTRO.CAT'; Sound: 13; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 2; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 30; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 21; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 0; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 13; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 14; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 19; Volume: 64),
    (CatFile: 'SAMPLE3.CAT'; Sound: 3; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 15; Volume: 128),
    (CatFile: 'SAMPLE3.CAT'; Sound: 12; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 18; Volume: 32),
    (CatFile: 'SAMPLE3.CAT'; Sound: 20; Volume: 32)
  ));

  /// <summary>introSoundTrack: in order of frame; the last row is never reached</summary>
  XCOM_INTRO_SOUND_TRACK: array[0..XCOM_INTRO_TRACK_COUNT - 1] of TXcomIntroSoundEffect = (
    (Frame: 0; Command: $200), (Frame: 149; Command: $11), (Frame: 173; Command: $0C), (Frame: 183; Command: $0E),
    (Frame: 205; Command: $15), (Frame: 211; Command: $201), (Frame: 211; Command: $407), (Frame: 223; Command: $7),
    (Frame: 250; Command: $1), (Frame: 253; Command: $1), (Frame: 255; Command: $1), (Frame: 257; Command: $1),
    (Frame: 260; Command: $1), (Frame: 261; Command: $3), (Frame: 262; Command: $1), (Frame: 264; Command: $1),
    (Frame: 268; Command: $1), (Frame: 270; Command: $1), (Frame: 272; Command: $5), (Frame: 272; Command: $1),
    (Frame: 274; Command: $1), (Frame: 278; Command: $1), (Frame: 280; Command: $1), (Frame: 282; Command: $8),
    (Frame: 282; Command: $1), (Frame: 284; Command: $1), (Frame: 286; Command: $1), (Frame: 288; Command: $1),
    (Frame: 290; Command: $1), (Frame: 292; Command: $6), (Frame: 292; Command: $1), (Frame: 296; Command: $1),
    (Frame: 298; Command: $1), (Frame: 300; Command: $1), (Frame: 302; Command: $1), (Frame: 304; Command: $1),
    (Frame: 306; Command: $1), (Frame: 308; Command: $1), (Frame: 310; Command: $1), (Frame: 312; Command: $1),
    (Frame: 378; Command: $202), (Frame: 378; Command: $9), (Frame: 386; Command: $9), (Frame: 393; Command: $9),
    (Frame: 399; Command: $17), (Frame: 433; Command: $17), (Frame: 463; Command: $12), (Frame: 477; Command: $12),
    (Frame: 487; Command: $13), (Frame: 495; Command: $16), (Frame: 501; Command: $16), (Frame: 512; Command: $D),
    (Frame: 514; Command: $D), (Frame: 522; Command: $0B), (Frame: 523; Command: $D), (Frame: 525; Command: $D),
    (Frame: 534; Command: $18), (Frame: 535; Command: $405), (Frame: 560; Command: $407),
    (Frame: 577; Command: $14), (Frame: 582; Command: $405), (Frame: 582; Command: $19),
    (Frame: 613; Command: $407), (Frame: 615; Command: $10), (Frame: 635; Command: $14), (Frame: 638; Command: $14),
    (Frame: 639; Command: $14), (Frame: 644; Command: $2), (Frame: 646; Command: $2), (Frame: 648; Command: $2),
    (Frame: 650; Command: $2), (Frame: 652; Command: $2), (Frame: 654; Command: $2), (Frame: 656; Command: $2),
    (Frame: 658; Command: $2), (Frame: 660; Command: $2), (Frame: 662; Command: $2), (Frame: 664; Command: $2),
    (Frame: 666; Command: $2), (Frame: 668; Command: $401), (Frame: 681; Command: $406),
    (Frame: 687; Command: $402), (Frame: 689; Command: $407), (Frame: 694; Command: $0A),
    (Frame: 711; Command: $407), (Frame: 711; Command: $0), (Frame: 714; Command: $0), (Frame: 716; Command: $4),
    (Frame: 717; Command: $0), (Frame: 720; Command: $0), (Frame: 723; Command: $0), (Frame: 726; Command: $5),
    (Frame: 726; Command: $0), (Frame: 729; Command: $0), (Frame: 732; Command: $0), (Frame: 735; Command: $0),
    (Frame: 738; Command: $0), (Frame: 741; Command: $0), (Frame: 742; Command: $6), (Frame: 744; Command: $0),
    (Frame: 747; Command: $0), (Frame: 750; Command: $0), (Frame: 753; Command: $0), (Frame: 756; Command: $0),
    (Frame: 759; Command: $0), (Frame: 762; Command: $0), (Frame: 765; Command: $0), (Frame: 768; Command: $0),
    (Frame: 771; Command: $0), (Frame: 774; Command: $0), (Frame: 777; Command: $0), (Frame: 780; Command: $0),
    (Frame: 783; Command: $0), (Frame: 786; Command: $0), (Frame: 790; Command: $15), (Frame: 790; Command: $15),
    (Frame: 807; Command: $2), (Frame: 810; Command: $2), (Frame: 812; Command: $2), (Frame: 814; Command: $2),
    (Frame: 816; Command: $0), (Frame: 819; Command: $0), (Frame: 822; Command: $0), (Frame: 824; Command: $40A),
    (Frame: 824; Command: $5), (Frame: 827; Command: $6), (Frame: 835; Command: $0F), (Frame: 841; Command: $0F),
    (Frame: 845; Command: $0F), (Frame: 855; Command: $407), (Frame: 879; Command: $0C),
    (Frame: 65535; Command: $0FFFF)
  );

implementation

end.