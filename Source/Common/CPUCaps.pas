///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// CPUCaps.pas                                                               //
// Detects cpu capabilities.                                                 //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// 28.10.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit CPUCaps;
// -----------------------------------------------------------------------------

// ------
INTERFACE
// ------

// 'Type' section.
type
   // Structure with CPU features.
   vtCPUCaps = packed record
       hasMMX      : Boolean;
       hasMMX2     : Boolean;
       hasSSE      : Boolean;
       hasSSE2     : Boolean;
       hasSSE3     : Boolean;
       has3DNow    : Boolean;
       has3DNowExt : Boolean;
       has64       : Boolean;
   end;

// Global variable definition.
var
   stCPUCaps: vtCPUCaps;   

///////////////////////////////////////////////////////////////////////////////
// --- START! GLOBAL FUNCTIONS DEFENITION ---
///////////////////////////////////////////////////////////////////////////////

procedure sys_checkCPUID;
procedure sys_checkMMX;
procedure sys_checkMMX2;
procedure sys_checkSSE;
procedure sys_checkSSE2;
procedure sys_checkSSE3;
procedure sys_check64;
procedure sys_checkCPU;

///////////////////////////////////////////////////////////////////////////////
// --- END! GLOBAL FUNCTIONS DEFENITION ---
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// --- START! IMPLEMENTATION ---
///////////////////////////////////////////////////////////////////////////////
IMPLEMENTATION

procedure sys_checkCPUID;
asm
        pushfd
        pop       eax
        mov       ecx, eax
        xor       eax, $200000
        push      eax
        popfd
        pushfd
        pop       eax
        cmp       eax,ecx
end;

// -----------------------------------------------------------------------------

procedure sys_checkMMX;
asm
        pushad
        mov       eax, $1
        db        $0F,$A2            // CPUID
        test      edx, $800000
        jz        @@End
        mov       stCPUCaps.hasMMX, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_checkMMX2;
asm
        pushad
        mov       eax, $1
        db        $0F,$A2            // CPUID
        test      edx, $400000
        jz        @@CheckAMD
        mov       stCPUCaps.hasMMX2, 1
        jmp       @@End
@@CheckAMD:
        mov       eax, $80000000
        db        $0F,$A2            // CPUID
        cmp       eax, $80000000
        jbe       @@End
        mov       eax, $80000001
        db        $0F,$A2            // CPUID
        test      edx, $400000
        jz	  @@End
        mov       stCPUCaps.hasMMX2, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_checkSSE;
asm
        pushad
        mov       eax, $1
        db        $0F,$A2            // CPUID
        test      edx, $2000000
        jz        @@End
        mov       stCPUCaps.hasSSE, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_checkSSE2;
asm
        pushad
        mov       eax, $1
        db        $0F,$A2            // CPUID
        test      edx, $4000000
        jz        @@End
        mov       stCPUCaps.hasSSE2, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_checkSSE3;
asm
        pushad
        mov       eax, $1
        db        $0F,$A2            // CPUID
        test      ecx, $1
        jz        @@End
        mov       stCPUCaps.hasSSE3, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_check64;
asm
        pushad
        mov       eax, $80000000
        db        $0F,$A2            // CPUID
        cmp       eax, $80000000
        jbe       @@End
        mov       eax, $80000001
        db        $0F,$A2            // CPUID
        test      edx, $20000000
        jz	      @@End
        mov       stCPUCaps.has64, 1
@@End:
        popad
        xor       eax,eax
end;

// -----------------------------------------------------------------------------

procedure sys_checkCPU;
asm
        mov       ecx, eax
        mov       stCPUCaps.hasMMX, 0
        mov       stCPUCaps.hasMMX2, 0
        mov       stCPUCaps.hasSSE, 0
        mov       stCPUCaps.hasSSE2, 0
        mov       stCPUCaps.hasSSE3, 0
        mov       stCPUCaps.has64, 0
        call      sys_checkCPUID
        jz        @@END
        Call      sys_checkMMX
        Call      sys_checkMMX2
        Call      sys_checkSSE
        Call      sys_checkSSE2
        Call      sys_checkSSE3
        Call      sys_check64
@@End:
end;

// -----------------------------------------------------------------------------

initialization
   sys_checkCPU;

///////////////////////////////////////////////////////////////////////////////
// --- END! IMPLEMENTATION ---
///////////////////////////////////////////////////////////////////////////////
END.
