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
const
   LAC_VERSION                 = 000;

   LAC_FILE_OPEN               = 050;
   LAC_FILE_INFO               = 051;
   LAC_FILE_INFO_PLAYLIST      = 080;
   LAC_FILE_OSD_INFO           = 052;
   LAC_FILE_OPENURL            = 053;

   LAC_CD_PLAYDISC_A           = 054;
   LAC_CD_PLAYDISC_B           = 055;
   LAC_CD_PLAYDISC_C           = 056;
   LAC_CD_PLAYDISC_D           = 057;
   LAC_CD_PLAYDISC_E           = 058;
   LAC_CD_PLAYDISC_F           = 059;
   LAC_CD_PLAYDISC_G           = 060;
   LAC_CD_PLAYDISC_H           = 061;
   LAC_CD_PLAYDISC_I           = 062;
   LAC_CD_PLAYDISC_J           = 063;
   LAC_CD_PLAYDISC_K           = 064;
   LAC_CD_PLAYDISC_L           = 065;
   LAC_CD_PLAYDISC_M           = 066;
   LAC_CD_PLAYDISC_N           = 067;
   LAC_CD_PLAYDISC_O           = 068;
   LAC_CD_PLAYDISC_P           = 069;
   LAC_CD_PLAYDISC_Q           = 070;
   LAC_CD_PLAYDISC_R           = 071;
   LAC_CD_PLAYDISC_S           = 072;
   LAC_CD_PLAYDISC_T           = 073;
   LAC_CD_PLAYDISC_U           = 074;
   LAC_CD_PLAYDISC_V           = 075;
   LAC_CD_PLAYDISC_W           = 076;
   LAC_CD_PLAYDISC_X           = 077;
   LAC_CD_PLAYDISC_Y           = 078;
   LAC_CD_PLAYDISC_Z           = 079;

   LAC_PLAYBACK_REAL_STOP      = 100;
   LAC_PLAYBACK_PLAY           = 101;
   LAC_PLAYBACK_STOP_PLAY      = 102;
   LAC_PLAYBACK_SPEED_PLAY     = 103;
   LAC_PLAYBACK_FILTERS        = 104;
   LAC_PLAYBACK_STOP           = 105;
   LAC_PLAYBACK_DISK           = 106;

   LAC_SEEK_FRAME_STEP         = 150;
   LAC_SEEK_FRAME_BACK         = 151;
   LAC_SEEK_FORWARD            = 152;
   LAC_SEEK_BACKWARD           = 153;
   LAC_SEEK_JUMP_FORWARD       = 154;
   LAC_SEEK_JUMP_BACKWARD      = 155;
   LAC_SEEK_REWIND             = 156;
   LAC_SEEK_SET_BOOKMARK       = 157;
   LAC_SEEK_SET_OE_OFFSET      = 158;
   LAC_SEEK_LAST_POS           = 159;
   LAC_SEEK_A_B                = 160;

   LAC_WINDOW_CONTROL_PANEL    = 200;
   LAC_WINDOW_PLAYLIST         = 201;
   LAC_WINDOW_FULLSCREEN       = 202;
   LAC_WINDOW_ORIGINAL         = 203;
   LAC_WINDOW_STAY_ON_TOP      = 204;
   LAC_WINDOW_MINIMIZE         = 205;
   LAC_WINDOW_MAXIMIZE         = 206;
   LAC_WINDOW_EX_PLAYLIST      = 207;
   LAC_WINDOW_HIDE_FROM_BOSS   = 208;

   LAC_PLAYLIST_NEXT           = 250;
   LAC_PLAYLIST_PREV           = 251;
   LAC_PLAYLIST_PLAY           = 252;
   LAC_PLAYLIST_ADD_FILES      = 253;
   LAC_PLAYLIST_ADD_FOLDER     = 254;
   LAC_PLAYLIST_DELETE         = 255;
   LAC_PLAYLIST_CLEAR          = 256;
   LAC_PLAYLIST_SAVE           = 257;
   LAC_PLAYLIST_MOVE_UP        = 258;
   LAC_PLAYLIST_MOVE_DOWN      = 259;
   LAC_PLAYLIST_SHUFFLE        = 260;
   LAC_PLAYLIST_SORT           = 261;
   LAC_PLAYLIST_REPORT         = 262;
   LAC_PLAYLIST_REPEAT         = 263;
   LAC_PLAYLIST_BOOKMARKS      = 264;
   LAC_PLAYLIST_JUMP           = 265;
   LAC_PLAYLIST_SEARCH_FILE    = 266;
   LAC_PLAYLIST_DELETE_FILE    = 267;
   LAC_PLAYLIST_REPEAT_FILE    = 268;
   LAC_PLAYLIST_VISUALSHUFFLE  = 269;
   LAC_PLAYLIST_MOVE_FILE      = 270;

   LAC_VIDEO_PROPERTIES        = 300;
   LAC_VIDEO_SCREENSHOT        = 301;
   LAC_VIDEO_SCALE_50          = 302;
   LAC_VIDEO_SCALE_100         = 303;
   LAC_VIDEO_SCALE_200         = 304;
   LAC_VIDEO_RATIO_ASIS        = 305;
   LAC_VIDEO_RATIO_16_9        = 306;
   LAC_VIDEO_RATIO_4_3         = 307;
   LAC_VIDEO_RATIO_WIDTH       = 308;
   LAC_VIDEO_RATIO_HEIGHT      = 309;
   LAC_VIDEO_RATIO_CUSTOM      = 310;
   LAC_VIDEO_RATIO_FREE        = 311;
   LAC_VIDEO_ZOOM_IN           = 312;
   LAC_VIDEO_ZOOM_OUT          = 313;
   LAC_VIDEO_BRIGHTNESS_INC    = 314;
   LAC_VIDEO_BRIGHTNESS_DEC    = 315;
   LAC_VIDEO_CONTRAST_INC      = 316;
   LAC_VIDEO_CONTRAST_DEC      = 317;
   LAC_VIDEO_SATURATION_INC    = 318;
   LAC_VIDEO_SATURATION_DEC    = 319;
   LAC_VIDEO_COLOR_RESET       = 320;
   LAC_VIDEO_CCLIPBOARD        = 321;

   LAC_SUBTITLES_LOAD          = 350;
   LAC_SUBTITLES_SHOW          = 351;
   LAC_SUBTITLES_PROPERTIES    = 352;
   LAC_SUBTITLES_VPOS_INC      = 353;
   LAC_SUBTITLES_VPOS_DEC      = 354;
   LAC_SUBTITLES_TS_INC        = 355;
   LAC_SUBTITLES_TS_DEC        = 356;
   LAC_SUBTITLES_SWITCH_STREAM = 357;

   LAC_SOUND_PROPERTIES        = 400;
   LAC_SOUND_VOLUME_INC        = 401;
   LAC_SOUND_VOLUME_DEC        = 402;
   LAC_SOUND_MUTE              = 403;
   LAC_SOUND_ADD               = 404;
   LAC_SOUND_SWITCH_STREAM     = 405;

   LAC_APPLICATION_PREFERENCES = 450;
   LAC_APPLICATION_HELP        = 451;
   LAC_APPLICATION_ABOUT       = 452;
   LAC_APPLICATION_EXIT        = 453;
   LAC_APPLICATION_POWER_OFF   = 454;
   LAC_APPLICATION_HIBERNATE   = 455;
   LAC_APPLICATION_MONITOR_OFF = 456;
   LAC_APPLICATION_HIB_ONPLDONE= 457;
   LAC_APPLICATION_POW_ONPLDONE= 458;
   LAC_APPLICATION_HIDEFROMBOSS= 459;

   LAC_DVD_PLAY_DISC           = 500;
   LAC_DVD_MAIN_MENU           = 501;
   LAC_DVD_OPEN_FOLDER         = 502;

   LAC_SYSTEM_CPU             = 1000;
   LAC_SYSTEM_CRC             = 1001;

