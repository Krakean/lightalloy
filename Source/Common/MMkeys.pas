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

unit MMkeys;

interface

const
  WM_APPCOMMAND = $0319;

  // Windows keys
  VK_SLEEP = $5F;

  VK_BROWSER_BACK = $A6;      //Browser Back key
  VK_BROWSER_FORWARD = $A7;	  //Browser Forward key
  VK_BROWSER_REFRESH = $A8;	  //Browser Refresh key
  VK_BROWSER_STOP = $A9;      //Browser Stop key
  VK_BROWSER_SEARCH = $AA;	  //Browser Search key
  VK_BROWSER_FAVORITES= $AB;  //Browser Favorites key
  VK_BROWSER_HOME = $AC;      //Browser Start and Home key

  VK_VOLUME_MUTE = $AD;       //Volume Mute key
  VK_VOLUME_DOWN = $AE;       //Volume Down key
  VK_VOLUME_UP = $AF;         //Volume Up key

  VK_MEDIA_NEXT_TRACK = $B0;	//Next Track key
  VK_MEDIA_PREV_TRACK = $B1;	//Previous Track key
  VK_MEDIA_STOP = $B2;	      //Stop Media key
  VK_MEDIA_PLAY_PAUSE = $B3;	//Play/Pause Media key

  VK_LAUNCH_MAIL = $B4;	      //Start Mail key
  VK_LAUNCH_MEDIA_SELECT = $B5;//Select Media key
  VK_LAUNCH_APP1 = $B6;	      //Start Application 1 key
  VK_LAUNCH_APP2 = $B7;	      //Start Application 2 key

  VK_OEM_1 = $BA;             // Used for miscellaneous characters; it can vary by keyboard.For the US standard keyboard, the ';:' key
  VK_OEM_PLUS = $BB;          //For any country/region, the '+' key
  VK_OEM_COMMA = $BC;         //For any country/region, the ',' key
  VK_OEM_MINUS = $BD;         //For any country/region, the '-' key
  VK_OEM_PERIOD = $BE;        //For any country/region, the '.' key
  VK_OEM_2 = $BF;             //Used for miscellaneous characters; it can vary by keyboard.For the US standard keyboard, the '/?' key
  VK_OEM_3 = $C0;             //Used for miscellaneous characters; it can vary by keyboard.For the US standard keyboard, the '`~' key

  VK_ATTN = $F6;	            //Attn key
  VK_CRSEL = $F7;	            //CrSel key
  VK_EXSEL = $F8;	            //ExSel key
  VK_EREOF = $F9;	            //Erase EOF key
  VK_PLAY = $FA;	            //Play key
  VK_ZOOM = $FB;	            //Zoom key
  VK_NONAME = $FC;	          //Reserved
  VK_PA1 = $FD;	              //PA1 key
  VK_OEM_CLEAR = $FE;	        //Clear key

  // Internal opcodes
  APPCOMMAND_BROWSER_BACKWARD = $01;
  APPCOMMAND_BROWSER_FORWARD = $02;
  APPCOMMAND_BROWSER_REFRESH = $03;
  APPCOMMAND_BROWSER_STOP = $04;
  APPCOMMAND_BROWSER_SEARCH = $05;
  APPCOMMAND_BROWSER_FAVORITES = $06;
  APPCOMMAND_BROWSER_HOME = $07;
  APPCOMMAND_VOLUME_MUTE = $08;
  APPCOMMAND_VOLUME_DOWN = $09;
  APPCOMMAND_VOLUME_UP = $0A;
  APPCOMMAND_MEDIA_NEXTTRACK = $0B;
  APPCOMMAND_MEDIA_PREVIOUSTRACK = $0C;
  APPCOMMAND_MEDIA_STOP = $0D;
  APPCOMMAND_MEDIA_PLAY_PAUSE = $0E;
  APPCOMMAND_LAUNCH_MAIL = $0F;
  APPCOMMAND_LAUNCH_MEDIA_SELECT = $10;
  APPCOMMAND_LAUNCH_APP1 = $11;
  APPCOMMAND_LAUNCH_APP2 = $12;
  APPCOMMAND_BASS_DOWN = $13;
  APPCOMMAND_BASS_BOOST = $14;
  APPCOMMAND_BASS_UP = $15;
  APPCOMMAND_TREBLE_DOWN = $16;
  APPCOMMAND_TREBLE_UP = $17;
  APPCOMMAND_MICROPHONE_VOLUME_MUTE = $18;
  APPCOMMAND_MICROPHONE_VOLUME_DOWN = $19;
  APPCOMMAND_MICROPHONE_VOLUME_UP = $1A;
  APPCOMMAND_HELP = $1B;
  APPCOMMAND_FIND = $1C;
  APPCOMMAND_NEW = $1D;
  APPCOMMAND_OPEN = $1E;
  APPCOMMAND_CLOSE = $1F;
  APPCOMMAND_SAVE = $20;
  APPCOMMAND_PRINT = $21;
  APPCOMMAND_UNDO = $22;
  APPCOMMAND_REDO = $23;
  APPCOMMAND_COPY = $24;
  APPCOMMAND_CUT = $25;
  APPCOMMAND_PASTE = $26;
  APPCOMMAND_REPLY_TO_MAIL = $27;
  APPCOMMAND_FORWARD_MAIL = $28;
  APPCOMMAND_SEND_MAIL = $29;
  APPCOMMAND_SPELL_CHECK = $2A;
  APPCOMMAND_DICTATE_OR_COMMAND_CONTROL_TOGGLE = $2B;
  APPCOMMAND_MIC_ON_OFF_TOGGLE = $2C;
  APPCOMMAND_CORRECTION_LIST = $2D;
  APPCOMMAND_MEDIA_PLAY = $2E;
  APPCOMMAND_MEDIA_PAUSE = $2F;
  APPCOMMAND_MEDIA_RECORD = $30;
  APPCOMMAND_MEDIA_FAST_FORWARD = $31;
  APPCOMMAND_MEDIA_REWIND = $32;
  APPCOMMAND_MEDIA_CHANNEL_UP = $33;
  APPCOMMAND_MEDIA_CHANNEL_DOWN = $34;

  FAPPCOMMAND_MOUSE = $8000;
  FAPPCOMMAND_KEY = $00;
  FAPPCOMMAND_OEM = $1000;
  FAPPCOMMAND_MASK = $F000;

implementation  

end.