section .text
;org 0x100

compute_md5:
    ; si --> input bytes, cx = input len, rdi --> 16-byte output buffer
    ; assumes all in the same segment
    cld
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi
    mov     [message_len], cx

    mov     rbx, rcx
    shr     rbx, 6
    mov     [ending_bytes_block_num], rbx
    mov     [num_blocks], rbx
    inc     qword [num_blocks]
    shl     rbx, 6
    add     rsi, rbx
    and     cx, 0x3f
    mov     rdi, ending_bytes
    rep movsb
    mov     al, 0x80
    stosb
    sub     cx, 55
    neg     cx
    jge     add_padding
    add     cx, 64
    inc     qword [num_blocks]
add_padding:
    xor     eax, eax
    mov     ax, [message_len]
    shl     rax, 3
    mov     rcx, 8
store_message_len:
    stosb
    shr     rax, 8
    dec     rcx
    jnz     store_message_len
    pop     rdi
    mov     rax, INIT_A
    mov     [md5_a], rax
    mov     rax, INIT_B
    mov     [md5_b], rax
    mov     rax, INIT_C
    mov     [md5_c], rax
    mov     rax, INIT_D
    mov     [md5_d], rax
block_loop:
    push    rcx
    cmp     cx, [ending_bytes_block_num]
    jne     backup_abcd
    ; switch buffers if towards the end where padding needed
    mov     rsi, ending_bytes
backup_abcd:
    push    qword [md5_d]
    push    qword [md5_c]
    push    qword [md5_b]
    push    qword [md5_a]
    xor     rcx, rcx
    xor     rax, rax
main_loop:
    push    rcx
    mov     ax, cx
    shr     ax, 4
    test    al, al
    jz      pass0
    cmp     al, 1
    je      pass1
    cmp     al, 2
    je      pass2
    ; pass3
    mov     rax, [md5_c]
    mov     rbx, [md5_d]
    not     rbx
    or      rbx, [md5_b]
    xor     rax, rbx
    jmp     do_rotate

pass0:
    mov     rax, [md5_b]
    mov     rbx, rax
    and     rax, [md5_c]
    not     rbx
    and     rbx, [md5_d]
    or      rax, rbx
    jmp     do_rotate

pass1:
    mov     rax, [md5_d]
    mov     rdx, rax
    and     rax, [md5_b]
    not     rdx
    and     rdx, [md5_c]
    or      rax, rdx
    jmp     do_rotate

pass2:
    mov     rax, [md5_b]
    xor     rax, [md5_c]
    xor     rax, [md5_d]

do_rotate:
    add     rax, [md5_a]
    mov     bx, cx
    shl     bx, 1
    mov     bx, [BUFFER_INDEX_TABLE + rbx]
    add     rax, [rsi + rbx]
    mov     bx, cx
    shl     bx, 2
    add     rax, qword [TABLE_T + rbx]
    mov     bx, cx
    ror     bx, 2
    shr     bl, 2
    rol     bx, 2
    mov     cl, [SHIFT_AMTS + rbx]
    rol     rax, cl
    add     rax, [md5_b]
    push    rax
    push    qword [md5_b]
    push    qword [md5_c]
    push    qword [md5_d]
    pop     qword [md5_a]
    pop     qword [md5_d]
    pop     qword [md5_c]
    pop     qword [md5_b]
    pop     rcx
    inc     cx
    cmp     cx, 64
    jb      main_loop
    ; add to original values
    pop     rax
    add     [md5_a], rax
    pop     rax
    add     [md5_b], rax
    pop     rax
    add     [md5_c], rax
    pop     rax
    add     [md5_d], rax
    ; advance pointers
    add     rsi, 64
    pop     rcx
    inc     cx
    cmp     cx, [num_blocks]
    jne     block_loop
    mov     cx, 4
    mov     rsi, md5_a
    pop     rdi
    rep movsq
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

section .data

; Définition des textes à mettre en MD5
test_input_1 db 'toto', 0
test_input_2 db 'tata2', 0
test_input_3 db 'test123', 0

; Calcul des longueurs des textes
test_input_1_len equ $ - test_input_1
test_input_2_len equ $ - test_input_2
test_input_3_len equ $ - test_input_3

; Constantes et tables nécessaires pour l'algorithme MD5
INIT_A equ 0x67452301
INIT_B equ 0xEFCDAB89
INIT_C equ 0x98BADCFE
INIT_D equ 0x10325476

SHIFT_AMTS db 7, 12, 17, 22, 5,  9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21

; implémentation basique de md5 en asm trouvable sur internet.

TABLE_T dq 0xD76AA478, 0xE8C7B756, 0x242070DB, 0xC1BDCEEE, 0xF57C0FAF, 0x4787C62A, 0xA8304613, 0xFD469501, 0x698098D8, 0x8B44F7AF, 0xFFFF5BB1, 0x895CD7BE, 0x6B901122, 0xFD987193, 0xA679438E, 0x49B40821, 0xF61E2562, 0xC040B340, 0x265E5A51, 0xE9B6C7AA, 0xD62F105D, 0x02441453, 0xD8A1E681, 0xE7D3FBC8, 0x21E1CDE6, 0xC33707D6, 0xF4D50D87, 0x455A14ED, 0xA9E3E905, 0xFCEFA3F8, 0x676F02D9, 0x8D2A4C8A, 0xFFFA3942, 0x8771F681, 0x6D9D6122, 0xFDE5380C, 0xA4BEEA44, 0x4BDECFA9, 0xF6BB4B60, 0xBEBFBC70, 0x289B7EC6, 0xEAA127FA, 0xD4EF3085, 0x04881D05, 0xD9D4D039, 0xE6DB99E5, 0x1FA27CF8, 0xC4AC5665, 0xF4292244, 0x432AFF97, 0xAB9423A7, 0xFC93A039, 0x655B59C3, 0x8F0CCC92, 0xFFEFF47D, 0x85845DD1, 0x6FA87E4F, 0xFE2CE6E0, 0xA3014314, 0x4E0811A1, 0xF7537E82, 0xBD3AF235, 0x2AD7D2BB, 0xEB86D391

BUFFER_INDEX_TABLE dw 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 4, 24, 44, 0, 20, 40, 60, 16, 36, 56, 12, 32, 52, 8, 28, 48, 20, 32, 44, 56, 4, 16, 28, 40, 52, 0, 12, 24, 36, 48, 60, 8, 0, 28, 56, 20, 48, 12, 40, 4, 32, 60, 24, 52, 16, 44, 8, 36

ending_bytes_block_num dq 0
ending_bytes times 128 db 0
message_len dq 0
num_blocks dq 0
md5_a dq 0
md5_b dq 0
md5_c dq 0
md5_d dq 0

