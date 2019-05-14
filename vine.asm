                        ; The MIT License (MIT)
                        ;
                        ; Copyright (c) 2019 Christian Uhsat <christian@uhsat.de>
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

                        ; PE Header (collapsed)

                        dw "MZ"                         ; e_magic
                        dw 0                            ; e_cblp
                        dd "PE"                         ; e_cp, e_crlc          ; PE signature
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

                        dd 0                                                    ; Align code

                        ; Entry Point

                        call    CODE                                            ; Execute

                        ; Import hash table

BASE                    dd      0x00000000                                      ; Image base

LoadLibraryA            dd      0xA412FD89
ExitProcess             dd      0xE6FF2CB9
Sleep                   dd      0x0005F218

USER32                  db      "USER32", 0                                     ; user32.dll

CreateWindowExA         dd      0x73AD3F4D
GetWindowRect           dd      0xDD604A89
GetDC                   dd      0x0004A563
FillRect                dd      0x09547E2C
ShowCursor              dd      0xFC1A2BC8
GetAsyncKeyState        dd      0x5BC4096E

GDI32                   db      "GDI32", 0                                      ; gdi32.dll

StretchDIBits           dd      0xD1E60854
CreateSolidBrush        dd      0xBB1B46D3

Class                   db      "static", 0                                     ; Window class

CODE:                   pop     ebp                                             ; Get return address
                        sub     ebp, 5                                          ; Calc image base
                        mov     [BASE], ebp                                     ; Save image base

                        ; Find kernel32.dll

                        mov     ebx, [fs:0x18]                                  ; Goto linear TIB
                        mov     ebx, [ebx + 0x30]                               ; Goto linear PEB
                        mov     ebx, [ebx + 0x0C]                               ; Goto PEB_LDR_DATA
                        mov     ebx, [ebx + 0x14]                               ; Goto init LIST_ENTRY
                        mov     ebx, [ebx]                                      ; Goto next LIST_ENTRY
                        mov     ebx, [ebx]                                      ; Goto next LIST_ENTRY
                        mov     ebx, [ebx + 0x10]                               ; Goto DllBase

                        ; Load user32.dll

                        push    LoadLibraryA
                        push    USER32
                        call    IMPORT

                        ; Import from user32.dll

                        push    USER32
                        call    [LoadLibraryA]
                        mov     ebx, eax

                        push    CreateWindowExA
                        push    GDI32
                        call    IMPORT

                        ; Load gdi32.dll

                        push    GDI32
                        call    [LoadLibraryA]
                        mov     ebx, eax

                        ; Import from gdi32.dll

                        push    StretchDIBits
                        push    Class
                        call    IMPORT

                        ; Create color table

                        xor     eax, eax                                        ; Zero register
                        xor     ebx, ebx                                        ; Zero register
                        xor     ecx, ecx                                        ; Zero register
                        mov     edi, Colors                                     ;
                        mov     ecx, 256                                        ;
@@:                     stosb                                                   ; Save A
                        stosb                                                   ; Save R
                        stosb                                                   ; Save G
                        stosb                                                   ; Save B
                        inc     eax                                             ; Next color
                        loopnz  @B                                              ; Next color

                        mov     eax, Class                                      ; Class / Window name
                        push    ebx                                             ; lpParam
                        push    ebx                                             ; hInstance
                        push    ebx                                             ; hMenu
                        push    ebx                                             ; hWndParent
                        push    ebx                                             ; nHeight
                        push    ebx                                             ; nWidth
                        push    ebx                                             ; Y
                        push    ebx                                             ; X
                        push    0x97800000                                      ; WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_MAXIMIZE | WS_POPUP | WS_VISIBLE | WS_BORDER
                        push    eax                                             ; lpWindowName
                        push    eax                                             ; lpClassName
                        push    0x00040000                                      ; WS_EX_APPWINDOW (| WS_EX_TOPMOST 0x00040008)
                        call    [CreateWindowExA]
                        push    eax                                             ; hWnd
                        push    Window                                          ; lpRect
                        push    eax                                             ; hWnd
                        call    [GetWindowRect]
                        call    [GetDC]
                        mov     esi, eax                                        ;
                        push    ebx                                             ; color
                        call    [CreateSolidBrush]
                        push    eax                                             ; hbr
                        push    Window                                          ; lprc
                        push    esi                                             ; hDC
                        call    [FillRect]
                        push    ebx                                             ; Hide cursor
                        call    [ShowCursor]

RENDER:                 ; Main Loop

                        mov     edx, 64 * 8
                        push    0x00CC0020                                      ; rop
                        push    ebx                                             ; iUsage
                        push    Header                                          ; lpbmi
                        push    [BASE]                                          ; lpBits
                        push    64                                              ; SrcHeight
                        push    64                                              ; SrcWidth
                        push    ebx                                             ; ySrc
                        push    ebx                                             ; xSrc
                        push    edx                                             ; DestHeight
                        push    edx                                             ; DestWidth

                        mov     eax, [Height]                                   ;
                        sub     eax, edx                                        ;
                        shr     eax, 1                                          ;
                        push    eax                                             ; yDest

                        mov     eax, [Width]                                    ;
                        sub     eax, edx                                        ;
                        shr     eax, 1                                          ;
                        push    eax                                             ; xDest

                        push    esi                                             ; hDC
                        call    [StretchDIBits]                                 ;

                        ; Idle

                        push    1                                               ; Millisecond
                        call    [Sleep]                                         ; Sleep

                        push    0x1B                                            ; VK_ESCAPE
                        call    [GetAsyncKeyState]                              ; Check key state

                        cmp     eax, 0                                          ; Next frame
                        je      RENDER                                          ; Next frame

                        ; Exit

                        push    ebx                                             ; Stack 0
                        call    [ExitProcess]                                   ; Call ExitProcess
                        ret                                                     ; Exit

IMPORT:                 ; Find EXPORT directory

                        mov     eax, [ebx + 0x3C]                               ; Goto e_lfanew
                        mov     eax, [ebx + eax + 0x78]                         ; Goto EXPORT directory
                        mov     edi, [ebx + eax + 0x20]                         ; Load base of EXPORT names
                        mov     ebp, eax                                        ; Load base of EXPORT directory
                        add     ebp, ebx                                        ; RVA to fix
                        add     edi, ebx                                        ; RVA to fix

                        ; Import functions

I1:                     xor     ecx, ecx                                        ; Zero EXPORT name
I2:                     inc     ecx                                             ; Next EXPORT name
                        mov     esi, [edi + ecx * 4]                            ; Load EXPORT name
                        add     esi, ebx                                        ; RVA to fix

                        ; Generate hash

                        xor     eax, eax                                        ; Init hash function
                        xor     edx, edx                                        ; Init hash function

                        ; Generate hash round

@@:                     rol     edx, 3                                          ; Round
                        xor     edx, eax                                        ; Round
                        lodsb                                                   ; Round
                        cmp     al, 0                                           ; Round
                        jne     @B                                              ; Round

                        mov     eax, [esp + 0x08]                               ; Load function hash
                        cmp     edx, [eax]                                      ; Test function hash
                        jne     I2                                              ; Next EXPORT name

                        mov     edx, [ebp + 0x24]                               ; Load base of EXPORT ordinals
                        add     edx, ebx                                        ; RVA to fix
                        mov      cx, [edx + ecx * 2]                            ; Load EXPORT ordinal

                        mov     edx, [ebp + 0x1C]                               ; Load base of EXPORT functions
                        add     edx, ebx                                        ; RVA to fix
                        mov     edx, [edx + ecx * 4]                            ; Load EXPORT function

                        add     edx, ebx                                        ; RVA to fix
                        mov     [eax], edx                                      ; Save EXPORT function
                        add     eax, 4                                          ; Next EXPORT function
                        mov     [esp + 0x08], eax                               ; Next EXPORT function
                        cmp     eax, [esp + 0x04]                               ; End of import
                        jb      I1                                              ; End of import

                        ret     8                                               ; End of function

Window:                 ; RECT structure

                        dd      0                                               ; left
                        dd      0                                               ; top
Width:                  dd      0                                               ; right
Height:                 dd      0                                               ; bottom

Header:                 ; BITMAPINFOHEADER structure

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

Colors:                 ; <Build at runtime>
