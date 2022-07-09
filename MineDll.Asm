.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include msvcrt.inc

includelib user32.lib
includelib kernel32.lib
includelib msvcrt.lib

.data
    g_hwnd HWND 0
    g_windowtitle db "扫雷", 0
    g_newwindowtitle db "扫雪", 0
    g_dProcessId dd 0
    g_dThreadId dd 0
    g_hHook HHOOK 0
    
    g_sz db "钩子", 0
    g_szMine db 1024 dup(0)
    
.code 
GetMessageProc proc uses ebx nCode:dword, wParam:WPARAM, lParam:LPARAM

    LOCAL mouse_x:DWORD
    LOCAL mouse_y:DWORD
    LOCAL mouse_Row:DWORD
    LOCAL mouse_Col:DWORD
    LOCAL hProcess:DWORD
    LOCAL dwReaded:DWORD
    
    .if nCode < 0
        invoke CallNextHookEx, g_hHook, nCode, wParam, lParam
		ret
		
	.endif

    mov eax, lParam
    assume eax:ptr MSG
    
    ;起点12,55  12-27(15)   55-70(15)   横有30个    竖有16个
    .if [eax].message == WM_MOUSEMOVE
        mov ebx, [eax].lParam
        and ebx, 0ffffh
        mov mouse_x, ebx
        mov ebx, [eax].lParam
        shr ebx, 16
        mov mouse_y, ebx
        
        
        ;先判断当前鼠标在第几行第几列
        sub mouse_x, 12
        sub mouse_y, 55
        xor edx, edx
        mov eax, mouse_x
        mov ebx, 16
        div ebx
        mov mouse_Col, eax
        
        xor edx, edx
        mov eax, mouse_y
        mov ebx, 16
        div ebx
        mov mouse_Row, eax
        
        ;获取雷区内存0x100535f
        invoke OpenProcess, PROCESS_ALL_ACCESS, FALSE, g_dProcessId
        mov hProcess, eax
        invoke ReadProcessMemory, hProcess, 100535fh, offset g_szMine, 200h, addr dwReaded
        
        ;如果鼠标所在的方块值为0x8F，则为雷
        mov eax, 20h
        mul mouse_Row
        add eax, mouse_Col
        add eax, 2
        
        mov ebx, offset g_szMine
        add ebx, eax
        .if byte ptr [ebx] == 8fh
            
            invoke SetWindowText, g_hwnd, offset g_newwindowtitle
            
        .else
            invoke SetWindowText, g_hwnd, offset g_windowtitle
        .endif
        
        
        
        
    .endif
    
    
    invoke CallNextHookEx, g_hHook, nCode, wParam, lParam
    ret
GetMessageProc endp


DllMain proc hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
    ;给扫雷安装消息钩子
    invoke FindWindow, offset g_windowtitle, NULL
    mov g_hwnd, eax
    invoke GetWindowThreadProcessId, g_hwnd, offset g_dProcessId
	mov g_dThreadId, eax
    invoke SetWindowsHookEx, WH_GETMESSAGE, GetMessageProc, NULL, g_dThreadId
    
    ret

DllMain endp

end DllMain