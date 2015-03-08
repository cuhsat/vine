
                        ; The MIT License (MIT)
                        ; 
                        ; Copyright (c) 2015 Christian Uhsat <christian@uhsat.de>
                        ; 
                        ; Permission is hereby granted, free of charge, to any person obtaining a copy
                        ; of this software and associated documentation files (the "Software"), to deal
                        ; in the Software without restriction, including without limitation the rights
                        ; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                        ; copies of the Software, and to permit persons to whom the Software is
                        ; furnished to do so, subject to the following conditions:
                        ; 
                        ; The above copyright notice and this permission notice shall be included in all
                        ; copies or substantial portions of the Software.
                        ; 
                        ; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                        ; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                        ; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                        ; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                        ; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                        ; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                        ; SOFTWARE.

                        Format Binary as "exe"
                        org 0x00400000
                        use32

                        ; PE Header (Collapsed)

                        dw "MZ"                         ; e_magic
                        dw 0                            ; e_cblp
                        dd "PE"                         ; e_cp, e_crlc          ; PE Signature
                        dw 0x014C                       ; e_cparhdr             ; Machine (Intel 386)
                        dw 0                            ; e_minalloc            ; NumberOfSections
                        dd 0                            ; e_maxalloc, e_ss      ; TimeDateStamp
                        dd 0                            ; e_sp, e_csum          ; PointerToSymbolTable
                        dd 0                            ; e_ip, e_cs            ; NumberOfSymbols
                        dw 0                            ; e_lsarlc              ; SizeOfOptionalHeader
                        dw 0x010F                       ; e_ovno                ; Characteristics
                        dw 0x010B                       ; e_res                 ; Magic (PE32)
                        db 0                            ; e_res                 ; MajorLinkerVersion
                        db 0                            ; e_res                 ; MinorLinkerVersion
                        dd 0                            ; e_res                 ; SizeOfCode
                        dd 0                            ; e_oemid, e_oeminfo    ; SizeOfInitializedData
                        dd 0                            ; e_res2                ; SizeOfUninitializedData
                        dd 0x00000080                   ; e_res2                ; AddressOfEntryPoint
                        dd 0                            ; e_res2                ; BaseOfCode
                        dd 0                            ; e_res2                ; BaseOfData
                        dd 0x00400000                   ; e_res2                ; ImageBase
                        dd 0x00000004                   ; e_lfanew              ; SectionAlignment
                        dd 0x00000004                                           ; FileAlignment
                        dw 0                                                    ; MajorOperatingSystemVersion
                        dw 0                                                    ; MinorOperatingSystemVersion
                        dw 0                                                    ; MajorImageVersion
                        dw 0                                                    ; MinorImageVersion
                        dw 0x04                                                 ; MajorSubsystemVersion
                        dw 0                                                    ; MinorSubsystemVersion
                        dd 0                                                    ; Win32VersionValue
                        dd 0x00000081                                           ; SizeOfImage
                        dd 0x00000080                                           ; SizeOfHeaders
                        dd 0                                                    ; CheckSum
                        dw 0x0002                                               ; Subsystem
                        dw 0                                                    ; DllCharacteristics
                        dd 0                                                    ; SizeOfStackReserve
                        dd 0                                                    ; SizeOfStackCommit
                        dd 0                                                    ; SizeOfHeapReserve
                        dd 0                                                    ; SizeOfHeapCommit
                        dd 0                                                    ; LoaderFlags
                        dd 0                                                    ; NumberOfRvaAndSizes
                
                        dd 0                                                    ; Align Code
                
                        ; Entry Point               
                
                        call    CODE                                            ; Execute
                
                        ; Import Hash Table             
                
BASE                    dd      0x00000000                                      ; Image Base
                
LoadLibraryA            dd      0xA412FD89              
ExitProcess             dd      0xE6FF2CB9              
Sleep                   dd      0x0005F218              
                
USER32                  db      "USER32", 0                                     ; Filename User32.dll

CreateWindowExA         dd      0x73AD3F4D
GetWindowRect           dd      0xDD604A89
GetDC                   dd      0x0004A563
FillRect                dd      0x09547E2C
ShowCursor              dd      0xFC1A2BC8
GetAsyncKeyState        dd      0x5BC4096E

GDI32                   db      "GDI32", 0                                      ; Filename GDI32.dll
                
StretchDIBits           dd      0xD1E60854              
CreateSolidBrush        dd      0xBB1B46D3              
                
Class                   db      "static", 0                                     ; Window Class
                
CODE:                   pop     ebp                                             ; Get Return Address
                        sub     ebp, 5                                          ; Calc Image Base
                        mov     [BASE], ebp                                     ; Save Image Base
                
                        ; Find KERNEL32.dll             
                
                        mov     ebx, [fs:0x18]                                  ; Goto linear TIB
                        mov     ebx, [ebx + 0x30]                               ; Goto linear PEB
                        mov     ebx, [ebx + 0x0C]                               ; Goto PEB_LDR_DATA
                        mov     ebx, [ebx + 0x14]                               ; Goto Init LIST_ENTRY
                        mov     ebx, [ebx]                                      ; Goto Next LIST_ENTRY
                        mov     ebx, [ebx]                                      ; Goto Next LIST_ENTRY
                        mov     ebx, [ebx + 0x10]                               ; Goto DllBase

                        ; Import KERNEL32.dll

                        push    LoadLibraryA
                        push    USER32
                        call    IMPORT                                          ; Import Functions

                        ; Import USER32.dll

                        push    USER32
                        call    [LoadLibraryA]
                        mov     ebx, eax

                        push    CreateWindowExA
                        push    GDI32
                        call    IMPORT                                          ; Import Functions

                        ; Import GDI32.dll

                        push    GDI32
                        call    [LoadLibraryA]
                        mov     ebx, eax

                        push    StretchDIBits
                        push    Class
                        call    IMPORT                                          ; Import Functions

                        ; Create Color Table

                        xor     eax, eax                                        ; Zero Register
                        xor     ebx, ebx                                        ; Zero Register
                        xor     ecx, ecx                                        ; Zero Register
                        mov     edi, Colors                                     ;
                        mov     ecx, 256                                        ;
@@:                     stosb                                                   ; Save A
                        stosb                                                   ; Save R
                        stosb                                                   ; Save G
                        stosb                                                   ; Save B
                        inc     eax                                             ; Next Color
                        loopnz  @B                                              ; Next Color
                
                        mov     eax, Class                                      ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    0x97800000                                      ; WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_MAXIMIZE | WS_POPUP | WS_VISIBLE | WS_BORDER
                        push    eax                                             ;
                        push    eax                                             ;
                        push    0x00040000                                      ; WS_EX_APPWINDOW (| WS_EX_TOPMOST 0x00040008)
                        call    [CreateWindowExA]                               ;
                        push    eax                                             ;
                        push    Window                                          ;
                        push    eax                                             ;
                        call    [GetWindowRect]                                 ;   
                        call    [GetDC]                                         ;
                        mov     esi, eax                                        ;
                        push    ebx                                             ;
                        call    [CreateSolidBrush]                              ;
                        push    eax                                             ;
                        push    Window                                          ;
                        push    esi                                             ;
                        call    [FillRect]                                      ;
                        push    ebx                                             ; Hide Cursor
                        call    [ShowCursor]                                    ; Call ShowCursor
                
RENDER:                 ; Main Loop             
                
                        mov     edx, 64 * 8                 
                        push    0x00CC0020                                      ;
                        push    ebx                                             ;
                        push    Header                                          ;
                        push    [BASE]                                          ;
                        push    64                                              ;
                        push    64                                              ;
                        push    ebx                                             ;
                        push    ebx                                             ;
                        push    edx                                             ;
                        push    edx                                             ;
                
                        mov     eax, [Height]               
                        sub     eax, edx                
                        shr     eax, 1              
                        push    eax             
                
                        mov     eax, [Width]                
                        sub     eax, edx                
                        shr     eax, 1              
                        push    eax             
                
                        push    esi                                             ; hdc
                        call    [StretchDIBits]                                 ;
                
                        ; Idle              
                
                        push    1                                               ;
                        call    [Sleep]                                         ;
                                        
                        push    0x1B                                            ;
                        call    [GetAsyncKeyState]                              ;
                                        
                        cmp     eax, 0                                          ;
                        je      RENDER                                          ;
                
                        ; Exit              
                
                        push    ebx                                             ; Stack 0
                        call    [ExitProcess]                                   ; Call ExitProcess
                        ret                                                     ; End of Code
                
IMPORT:                 ; Find EXPORT Directory             
                
                        mov     eax, [ebx + 0x3C]                               ; Goto e_lfanew
                        mov     eax, [ebx + eax + 0x78]                         ; Goto EXPORT Directory
                        mov     edi, [ebx + eax + 0x20]                         ; Load Base of EXPORT Names
                        mov     ebp, eax                                        ; Load Base of EXPORT Directory
                        add     ebp, ebx                                        ; RVA to Fix
                        add     edi, ebx                                        ; RVA to Fix
                
                        ; Import Functions              
                
I1:                     xor     ecx, ecx                                        ; Zero EXPORT Name
I2:                     inc     ecx                                             ; Next EXPORT Name
                        mov     esi, [edi + ecx * 4]                            ; Load EXPORT Name
                        add     esi, ebx                                        ; RVA to Fix
                
                        ; Generate HASH             
                
                        xor     eax, eax                                        ; Init HASH Function
                        xor     edx, edx                                        ; Init HASH Function
                
                        ; Generate HASH Round               
                                    
@@:                     rol     edx, 3                                          ; Round
                        xor     edx, eax                                        ; Round
                        lodsb                                                   ; Round
                        cmp     al, 0                                           ; Round
                        jne     @B                                              ; Round
                                        
                        mov     eax, [esp + 0x08]                               ; Load Function HASH
                        cmp     edx, [eax]                                      ; Test Function HASH
                        jne     I2                                              ; Next EXPORT Name
                
                        mov     edx, [ebp + 0x24]                               ; Load Base of EXPORT Ordinals
                        add     edx, ebx                                        ; RVA to Fix
                        mov      cx, [edx + ecx * 2]                            ; Load EXPORT Ordinal
                
                        mov     edx, [ebp + 0x1C]                               ; Load Base of EXPORT Functions
                        add     edx, ebx                                        ; RVA to Fix
                        mov     edx, [edx + ecx * 4]                            ; Load EXPORT Function
                
                        add     edx, ebx                                        ; RVA to Fix                        
                        mov     [eax], edx                                      ; Save EXPORT Function
                        add     eax, 4                                          ; Next EXPORT Function
                        mov     [esp + 0x08], eax                               ; Next EXPORT Function
                        cmp     eax, [esp + 0x04]                               ; End of Import
                        jb      I1                                              ; End of Import
                
                        ret     8                                               ; End of Function
                
Window:                 ; RECT              
                
                        dd      0               
                        dd      0               
Width:                  dd      0               
Height:                 dd      0               
                
Header:                 ; BITMAPINFOHEADER              
                
                        dd      0x00000028                                      ; biSize
                        dd      0x00000040                                      ; biWidth
                        dd      0xFFFFFFC6                                      ; biHeight
                        dw      0x0001                                          ; biPlanes
                        dw      0x0008                                          ; biBitCount
                        dd      0x00000000                                      ; biCompression
                        dd      0x00000000                                      ; biSizeImage
                        dd      0x00000000                                      ; biXPelsPerMeter
                        dd      0x00000000                                      ; biYPelsPerMeter
                        dd      0x00000100                                      ; biClrUsed
                        dd      0x00000100                                      ; biClrImportant

Colors:                 ; <Patched by Code>
