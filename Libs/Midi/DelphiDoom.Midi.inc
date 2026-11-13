// MIDI_LEGACY_LOOP: the sequencer keeps a defect of the old TMidi (i_midi_new).
//
// The old code did not bring the time of the song back to zero when the song started again
// (at the end of a loop, or after Rewind). The first event after the restart had a delta of
// "its time minus the time of the end of the song", which wraps around to $FFFFFFxx ticks: the
// second round of a song starts after an absurd delay, or with events at the wrong time.
// By ear: the song is right the first time and late or silent the second time.
//
// With the line below the blocks are the same bytes as the old code (the golden files of
// Tests\Data\Midi are of the old code). Without it the time starts from zero at every
// restart and the code is right.
//
// DECISION 2026-11-13: the defect was heard by the user (second round of a Hexen song late or
// silent with the define, normal without it) and the define is REMOVED: the code is the
// corrected one. The IFDEF branches stay in the sources only as the record of the old behaviour;
// to see the old bytes again (golden files of the old code) put the line below back. The tests
// that depend on the defect are inside IFDEF MIDI_LEGACY_LOOP, those for the corrected behaviour
// inside IFNDEF.
//
// The other defect of the old code, the event written 192 bytes after its place after a change
// of tempo (a pointer to a record of 16 bytes moved by 12 steps), is not under this define: what
// the old code left in the bytes between depended on what the buffer held before, and a block
// of the library does not have it. The old bytes are in the lines /legacy-tempo of the golden
// file, for information.
// {$DEFINE MIDI_LEGACY_LOOP}
