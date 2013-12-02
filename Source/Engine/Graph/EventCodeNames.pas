///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit EventCodeNames;

interface

function MediaEventCodeName(EvCode: Longint): string;

implementation

uses SysUtils;

function MediaEventCodeName(EvCode: Longint): string;
begin
  case EvCode of
    $01: Result:='EC_COMPLETE';
    $02: Result:='EC_USERABORT';
    $03: Result:='EC_ERRORABORT';
    $04: Result:='EC_TIME';
    $05: Result:='EC_REPAINT';
    $06: Result:='EC_STREAM_ERROR_STOPPED';
    $07: Result:='EC_STREAM_ERROR_STILLPLAYING';
    $08: Result:='EC_ERROR_STILLPLAYING';
    $09: Result:='EC_PALETTE_CHANGED';
    $0A: Result:='EC_VIDEO_SIZE_CHANGED';
    $0B: Result:='EC_QUALITY_CHANGE';
    $0C: Result:='EC_SHUTTING_DOWN';
    $0D: Result:='EC_CLOCK_CHANGED';
    $0E: Result:='EC_PAUSED';
    $10: Result:='EC_OPENING_FILE';
    $11: Result:='EC_BUFFERING_DATA';
    $12: Result:='EC_FULLSCREEN_LOST';
    $13: Result:='EC_ACTIVATE';
    $14: Result:='EC_NEED_RESTART';
    $15: Result:='EC_WINDOW_DESTROYED';
    $16: Result:='EC_DISPLAY_CHANGED';
    $17: Result:='EC_STARVATION';
    $18: Result:='EC_OLE_EVENT';
    $19: Result:='EC_NOTIFY_WINDOW';
    $1A: Result:='EC_STREAM_CONTROL_STOPPED';
    $1B: Result:='EC_STREAM_CONTROL_STARTED';
    $1C: Result:='EC_END_OF_SEGMENT';
    $1D: Result:='EC_SEGMENT_STARTED';
    $1E: Result:='EC_LENGTH_CHANGED';
    $1f: Result:='EC_DEVICE_LOST';
    $24: Result:='EC_STEP_COMPLETE';
    $30: Result:='EC_TIMECODE_AVAILABLE';
    $31: Result:='EC_EXTDEVICE_MODE_CHANGE';
    $32: Result:='EC_STATE_CHANGE';
    $50: Result:='EC_GRAPH_CHANGED';
    $51: Result:='EC_CLOCK_UNSET';
    $53: Result:='EC_VMR_RENDERDEVICE_SET';
    $54: Result:='EC_VMR_SURFACE_FLIPPED';
    $55: Result:='EC_VMR_RECONNECTION_FAILED';
    $56: Result:='EC_PREPROCESS_COMPLETE';
    $57: Result:='EC_CODECAPI_EVENT';

    $0101: Result:='EC_DVD_DOMAIN_CHANGE';
    $0102: Result:='EC_DVD_TITLE_CHANGE';
    $0103: Result:='EC_DVD_CHAPTER_START';
    $0104: Result:='EC_DVD_AUDIO_STREAM_CHANGE';
    $0105: Result:='EC_DVD_SUBPICTURE_STREAM_CHANGE';
    $0106: Result:='EC_DVD_ANGLE_CHANGE';
    $0107: Result:='EC_DVD_BUTTON_CHANGE';
    $0108: Result:='EC_DVD_VALID_UOPS_CHANGE';
    $0109: Result:='EC_DVD_STILL_ON';
    $010A: Result:='EC_DVD_STILL_OFF';
    $010B: Result:='EC_DVD_CURRENT_TIME';
    $010C: Result:='EC_DVD_ERROR';
    $010D: Result:='EC_DVD_WARNING';
    $010E: Result:='EC_DVD_CHAPTER_AUTOSTOP';
    $010F: Result:='EC_DVD_NO_FP_PGC';
    $0110: Result:='EC_DVD_PLAYBACK_RATE_CHANGE';
    $0111: Result:='EC_DVD_PARENTAL_LEVEL_CHANGE';
    $0112: Result:='EC_DVD_PLAYBACK_STOPPED';
    $0113: Result:='EC_DVD_ANGLES_AVAILABLE';
    $0114: Result:='EC_DVD_PLAYPERIOD_AUTOSTOP';
    $0115: Result:='EC_DVD_BUTTON_AUTO_ACTIVATED';
    $0116: Result:='EC_DVD_CMD_START';
    $0117: Result:='EC_DVD_CMD_END';
    $0118: Result:='EC_DVD_DISC_EJECTED';
    $0119: Result:='EC_DVD_DISC_INSERTED';
    $011A: Result:='EC_DVD_CURRENT_HMSF_TIME';
    $011B: Result:='EC_DVD_KARAOKE_MODE';
  else
    Result:=Format('$%x',[EvCode]);
  end;
end;

initialization

finalization

end.