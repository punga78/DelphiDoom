{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - binding to the C code                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Native;

// The libsndfile objects (AUDIOLIB\libsndfile\obj\*.obj) are linked with the L
// directive, together with the units libogg, libvorbis and libflac (codecs of
// libsndfile) and C_LIB\c_lib, which emulates the C runtime the objects import.
// The folders AUDIOLIB and C_LIB must be in the unit search path and in the
// object path of the project.
//
// This unit replaces AUDIOLIB\libsndfile.pas inside the DLL: that unit needs
// d_delphi (only for the TDStream type of its callbacks), so it would drag the
// whole engine in. Here the callbacks receive a plain Pointer. The two units
// must never be compiled in the same program (they link the same objects).
//
// The Pascal names must match the symbols of the objects (underscore prefix),
// so they cannot follow the naming rules.

interface

const
  // Modes of _sf_open_virtual
  SF_MODE_READ = $10;

  // Origins of _sf_seek
  SF_SEEK_SET = 0;
  SF_SEEK_CUR = 1;
  SF_SEEK_END = 2;

type
  /// <summary>
  ///   Opaque SNDFILE* of the C code
  /// </summary>
  TSndfileHandle = Pointer;

  /// <summary>
  ///   sf_count_t of the C code
  /// </summary>
  TSfCount = Int64;

  PSfInfo = ^TSfInfo;

  // Layout of SF_INFO: field names follow the C declaration
  TSfInfo = record
    frames: TSfCount;
    samplerate: Integer;
    channels: Integer;
    format: Integer;
    sections: Integer;
    seekable: Integer;
  end;

  // Callbacks of SF_VIRTUAL_IO: AUserData is the pointer given to _sf_open_virtual
  TSfGetLength = function(AUserData: Pointer): TSfCount; cdecl;
  TSfSeek = function(AOffset: TSfCount; AWhence: Integer;
    AUserData: Pointer): TSfCount; cdecl;
  TSfRead = function(ABuffer: Pointer; ACount: TSfCount;
    AUserData: Pointer): TSfCount; cdecl;
  TSfWrite = function(ABuffer: Pointer; ACount: TSfCount;
    AUserData: Pointer): TSfCount; cdecl;
  TSfTell = function(AUserData: Pointer): TSfCount; cdecl;

  PSfVirtualIO = ^TSfVirtualIO;

  // Layout of SF_VIRTUAL_IO
  TSfVirtualIO = packed record
    get_filelen: TSfGetLength;
    seek: TSfSeek;
    read: TSfRead;
    write: TSfWrite;
    tell: TSfTell;
  end;

function _sf_open_virtual(AVirtualIO: PSfVirtualIO; AMode: Integer;
  AInfo: PSfInfo; AUserData: Pointer): TSndfileHandle; cdecl;
function _sf_close(AHandle: TSndfileHandle): Integer; cdecl;
function _sf_error(AHandle: TSndfileHandle): Integer; cdecl;
function _sf_strerror(AHandle: TSndfileHandle): PAnsiChar; cdecl;
function _sf_version_string: PAnsiChar; cdecl;
function _sf_seek(AHandle: TSndfileHandle; AFrame: TSfCount;
  AWhence: Integer): TSfCount; cdecl;
function _sf_readf_short(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl;
function _sf_readf_int(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl;
function _sf_readf_double(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl;

implementation

uses
  c_lib, libogg, libvorbis, libflac;


{$L libsndfile\obj\add.obj}
{$L libsndfile\obj\ag_dec.obj}
{$L libsndfile\obj\ag_enc.obj}
{$L libsndfile\obj\aiff.obj}
{$L libsndfile\obj\alac.obj}
{$L libsndfile\obj\ALACBitUtilities.obj}
{$L libsndfile\obj\alac_decoder.obj}
{$L libsndfile\obj\alac_encoder.obj}
{$L libsndfile\obj\alaw.obj}
{$L libsndfile\obj\au.obj}
{$L libsndfile\obj\audio_detect.obj}
{$L libsndfile\obj\avr.obj}
{$L libsndfile\obj\broadcast.obj}
{$L libsndfile\obj\caf.obj}
{$L libsndfile\obj\cart.obj}
{$L libsndfile\obj\chanmap.obj}
{$L libsndfile\obj\chunk.obj}
{$L libsndfile\obj\code.obj}
{$L libsndfile\obj\command.obj}
{$L libsndfile\obj\common.obj}
{$L libsndfile\obj\decode.obj}
{$L libsndfile\obj\dither.obj}
{$L libsndfile\obj\double64.obj}
{$L libsndfile\obj\dp_dec.obj}
{$L libsndfile\obj\dp_enc.obj}
{$L libsndfile\obj\dwd.obj}
{$L libsndfile\obj\dwvw.obj}
{$L libsndfile\obj\file_io.obj}
{$L libsndfile\obj\flac.obj}
{$L libsndfile\obj\float32.obj}
{$L libsndfile\obj\g721.obj}
{$L libsndfile\obj\g723_16.obj}
{$L libsndfile\obj\g723_24.obj}
{$L libsndfile\obj\g723_40.obj}
{$L libsndfile\obj\g72x_main.obj}
{$L libsndfile\obj\g72x.obj}
{$L libsndfile\obj\gsm610.obj}
{$L libsndfile\obj\gsm_create.obj}
{$L libsndfile\obj\gsm_decode.obj}
{$L libsndfile\obj\gsm_destroy.obj}
{$L libsndfile\obj\gsm_encode.obj}
{$L libsndfile\obj\gsm_option.obj}
{$L libsndfile\obj\htk.obj}
{$L libsndfile\obj\id3.obj}
{$L libsndfile\obj\ima_adpcm.obj}
{$L libsndfile\obj\ima_oki_adpcm.obj}
{$L libsndfile\obj\interleave.obj}
{$L libsndfile\obj\ircam.obj}
{$L libsndfile\obj\long_term.obj}
{$L libsndfile\obj\lpc.obj}
{$L libsndfile\obj\macos.obj}
{$L libsndfile\obj\mat4.obj}
{$L libsndfile\obj\mat5.obj}
{$L libsndfile\obj\matrix_dec.obj}
{$L libsndfile\obj\matrix_enc.obj}
{$L libsndfile\obj\mpc2k.obj}
{$L libsndfile\obj\ms_adpcm.obj}
{$L libsndfile\obj\nist.obj}
{$L libsndfile\obj\ogg.obj}
{$L libsndfile\obj\ogg_opus.obj}
{$L libsndfile\obj\ogg_pcm.obj}
{$L libsndfile\obj\ogg_speex.obj}
{$L libsndfile\obj\ogg_vorbis.obj}
{$L libsndfile\obj\paf.obj}
{$L libsndfile\obj\pcm.obj}
{$L libsndfile\obj\preprocess.obj}
{$L libsndfile\obj\pvf.obj}
{$L libsndfile\obj\raw.obj}
{$L libsndfile\obj\rf64.obj}
{$L libsndfile\obj\rpe.obj}
{$L libsndfile\obj\rx2.obj}
{$L libsndfile\obj\sd2.obj}
{$L libsndfile\obj\sds.obj}
{$L libsndfile\obj\short_term.obj}
{$L libsndfile\obj\sfendian.obj}
{$L libsndfile\obj\sndfile.obj}
{$L libsndfile\obj\strings.obj}
{$L libsndfile\obj\svx.obj}
{$L libsndfile\obj\table.obj}
{$L libsndfile\obj\txw.obj}
{$L libsndfile\obj\ulaw.obj}
{$L libsndfile\obj\voc.obj}
{$L libsndfile\obj\vox_adpcm.obj}
{$L libsndfile\obj\w64.obj}
{$L libsndfile\obj\wav.obj}
{$L libsndfile\obj\wavlike.obj}
{$L libsndfile\obj\windows.obj}
{$L libsndfile\obj\wve.obj}
{$L libsndfile\obj\xi.obj}

function _sf_open_virtual(AVirtualIO: PSfVirtualIO; AMode: Integer;
  AInfo: PSfInfo; AUserData: Pointer): TSndfileHandle; cdecl; external;
function _sf_close(AHandle: TSndfileHandle): Integer; cdecl; external;
function _sf_error(AHandle: TSndfileHandle): Integer; cdecl; external;
function _sf_strerror(AHandle: TSndfileHandle): PAnsiChar; cdecl; external;
function _sf_version_string: PAnsiChar; cdecl; external;
function _sf_seek(AHandle: TSndfileHandle; AFrame: TSfCount;
  AWhence: Integer): TSfCount; cdecl; external;
function _sf_readf_short(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl; external;
function _sf_readf_int(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl; external;
function _sf_readf_double(AHandle: TSndfileHandle; ABuffer: Pointer;
  AFrames: TSfCount): TSfCount; cdecl; external;

// Entry points of libsndfile that this unit does not use. They are declared like
// in AUDIOLIB\libsndfile.pas so that the linker resolves the references between
// the objects exactly as it does in the engine
procedure _sf_open; external;
procedure _sf_open_fd; external;
procedure _sf_error_number; external;
procedure _sf_perror; external;
procedure _sf_error_str; external;
procedure _sf_command; external;
procedure _sf_format_check; external;
procedure _sf_set_string; external;
procedure _sf_get_string; external;
procedure _sf_read_raw; external;
procedure _sf_write_raw; external;
procedure _sf_writef_short; external;
procedure _sf_writef_int; external;
procedure _sf_readf_float; external;
procedure _sf_writef_float; external;
procedure _sf_writef_double; external;
procedure _sf_read_short; external;
procedure _sf_write_short; external;
procedure _sf_read_int; external;
procedure _sf_write_int; external;
procedure _sf_read_float; external;
procedure _sf_write_float; external;
procedure _sf_read_double; external;
procedure _sf_write_double; external;
procedure _sf_write_sync; external;
procedure _sf_copy_data_fp; external;
procedure _sf_copy_data_int; external;

// Internal functions shared between the objects of libsndfile
procedure _BitBufferReadSmall; external;
procedure _BitBufferRead; external;
procedure _set_ag_params; external;
procedure _dyn_decomp; external;
procedure _BitBufferByteAlign; external;
procedure _BitBufferReadOne; external;
procedure _dyn_comp; external;
procedure _BitBufferWrite; external;
procedure _BitBufferGetPosition; external;
procedure _set_standard_ag_params; external;
procedure _alac_init; external;
procedure _alac_get_desc_chunk_items; external;
procedure _psf_decode_frame_count; external;
procedure _g723_16_decoder; external;
procedure _g723_24_decoder; external;
procedure _g721_decoder; external;
procedure _g723_40_decoder; external;
procedure _g723_16_encoder; external;
procedure _g723_24_encoder; external;
procedure _g721_encoder; external;
procedure _g723_40_encoder; external;
procedure _g72x_reader_init; external;
procedure _g72x_writer_init; external;
procedure _g72x_decode_block; external;
procedure _g72x_encode_block; external;
procedure _Gsm_Decoder; external;
procedure _Gsm_Coder; external;
procedure _psf_get_date_str; external;
procedure _psf_asciiheader_printf; external;
procedure _u_bitwidth_to_subformat; external;
procedure _gsm_add; external;
procedure _gsm_sub; external;
procedure _gsm_asl; external;
procedure _gsm_asr; external;
procedure _psf_use_rsrc; external;
procedure _psf_file_valid; external;
procedure _psf_open_rsrc; external;
procedure _psf_close_rsrc; external;
procedure _psf_allocate; external;
procedure _psf_init_files; external;
procedure _psf_set_stdio; external;
procedure _psf_fopen; external;
procedure _psf_set_file; external;
procedure _psf_fsync; external;
procedure _psf_get_format_simple_count; external;
procedure _psf_get_format_major_count; external;
procedure _psf_get_format_subtype_count; external;
procedure _psf_calc_signal_max; external;
procedure _dither_init; external;
procedure _broadcast_var_set; external;
procedure _cart_var_set; external;
procedure _psf_get_cues; external;
procedure _psf_cues_dup; external;
procedure _cart_var_get; external;
procedure _broadcast_var_get; external;
procedure _psf_ftruncate; external;
procedure _psf_get_max_all_channels; external;
procedure _psf_get_signal_max; external;
procedure _psf_calc_max_all_channels; external;
procedure _psf_get_format_info; external;
procedure _psf_get_format_subtype; external;
procedure _psf_get_format_major; external;
procedure _psf_get_format_simple; external;
procedure _psf_memset; external;
procedure _id3_skip; external;
procedure _psf_fclose; external;
procedure _psf_default_seek; external;
procedure _psf_rand_int32; external;
procedure _aiff_open; external;
procedure _au_open; external;
procedure _raw_open; external;
procedure _rf64_open; external;
procedure _paf_open; external;
procedure _nist_open; external;
procedure _ircam_open; external;
procedure _sds_open; external;
procedure _ogg_open; external;
procedure _dwd_open; external;
procedure _mat4_open; external;
procedure _mat5_open; external;
procedure _pvf_open; external;
procedure _htk_open; external;
procedure _sd2_open; external;
procedure _rx2_open; external;
procedure _avr_open; external;
procedure _flac_open; external;
procedure _caf_open; external;
procedure _mpc2k_open; external;
procedure _psf_log_SF_INFO; external;
procedure _ima_oki_adpcm_init; external;
procedure _ima_oki_adpcm_decode_block; external;
procedure _ima_oki_adpcm_encode_block; external;
procedure _append_snprintf; external;
procedure _gsm_norm; external;
procedure _gsm_mult; external;
procedure _gsm_div; external;
procedure _wavlike_ima_init; external;
procedure _wavlike_msadpcm_init; external;
procedure _wavlike_msadpcm_write_adapt_coeffs; external;
procedure _audio_detect; external;
procedure _broadcast_var_alloc; external;
procedure _psf_location_string_count; external;
procedure _cart_var_alloc; external;

end.
