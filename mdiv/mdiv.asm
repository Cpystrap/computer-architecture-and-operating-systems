section	.text
    global mdiv     
	
mdiv:	                          
    mov r8, rdx                   ; I store divider (y) in r8,
                                  ; given before in rdx
    mov r9, 1                     ; will tell me if dividend is negative
    ; 0 - negative, 1 - positive, when y = 0 we've got a special case
    mov r10, 1                    ; will tell me if divider is negative

    ; first bit (of the last cell) will tell me if the whole is positive
    ; or negative
    mov r11, [rdi + rsi*8 - 8]
    test r11, r11                 ; if dividend is negative,
    js negation_array             ; else continue

check_divisor:
    ; I check first bit of divider whether it's negative or positive (the sign)
    test r8, r8
    js negation_divisor           ; if the divisor is negative, otherwise: 
	; now it’s time to set rcx and rdx, and then move on to the main algorithm.

loop_main_prepair:
    mov rcx, rsi                  ; the number n is in rsi, 
								  ; move it to rcx for the loop
    mov rdx, 0                    ; initially the remainder is 0
	; what does “remainder” mean? My algorithm works in such a way that it divides
	; consecutive cells of the array — it stores the quotient in the array as required,
	; and places the remainder in rdx. Then it loads the next array element into rax
	; and performs the division again: the remainder goes to rdx, the next cell to rax, and so on.
	; When dividing the first element, of course, there is no remainder from any previous division.

loop_main:
    mov rax, [rdi + rcx*8 - 8]    ; put the array element into rax
	; initially the last one, then the second to last, and so on.
    div r8                        ; divide the pair rdx:rax by y
	; the remainder is stored in rdx, and the quotient in rax
    mov [rdi + rcx*8 - 8], rax    ; store the quotient into the array x, in the current cell

    dec rcx                       ; decrease the loop counter
    jnz loop_main                 ; and so the loop is executed n times
	; as long as rcx != 0

    cmp r9, 1 
    je check_second_condition     ; dividend is positive

    cmp r10, 1  
    je negation_array             ; r9 was equal to 0, therefore if r10 = 1
	; the quotient must be negated (changed to its opposite sign)

    ; r9 = 0 and r10 = 0, therefore the remainder should be negative, and the quotient positive
    jmp negation_rest

negation_array:                   ; negates the number (changes it to its opposite)
	; starts from the first array cell, the least significant bits
	; it’s important to understand that this label is called in two cases:
	; first, at the beginning when the given dividend is negative, it must be changed to positive
	; (so that div works correctly), and second, when the quotient stored in x should be negative.
	; In the first case, r9 is set to 1 and must be changed to 0 because the dividend is negative.
	; In the second case, before outputting the result, if it turns out that the quotient should be negative,
	; then at least one of the registers r9 or r10 must be 0
	; (because the divisor XOR dividend was negative).
    not qword [rdi]               ; negacja bitow
    add qword [rdi], 1            ; zwieksz o 1
    setc r11b                     ; r11b = 1 gdy nastapilo przeniesienie 
    mov rcx, 1                    ; sprawdzilem 0. el tablicy, teraz 1. itd.
    cmp rcx, rsi
    jne loop_opposite

    cmp r9, 0                     ; przeczytaj dlugi komentarz wyzej 
    je negation_rest              ; gdy dzielna jest ujemna to i reszta
    cmp r10, 0
    je end                        ; skoro r9 = 1 to reszta dodatnia     

    xor r9, r9                    ; skoro ta petla sie "odpalila"
    ; znaczy ze dzielna jest ujemna, wiec r9 ustawiam na 0 
    ; dzielna ustawiona, teraz kolei na dzielnik
    jmp is_minimal

loop_opposite:
    not qword [rdi + rcx*8]       ; neguje bity w kolejnej komorce
    add [rdi + rcx*8], r11b       ; jesli nastapilo przeniesienie to zwieksz
                                  ; liczbe w tej komorce o 1
    setc r11b                     ; r11b = 0 gdy nie nastapilo przeniesienie 
    inc rcx                       ; zwiekszam loop countera      
    cmp rcx, rsi                  ; chce aby petla wykonala sie rsi razy
    ; w rsi trzymam n oczywiscie
    jne loop_opposite 

    cmp r9, 0                ; przeczytaj dlugi komentarz z negation_array
    je negation_rest         ; gdy dzielna jest ujemna to na pewno i reszta
    cmp r10, 0
    je end                   ; skoro r9 = 1 to reszta dodatnia i mozna konczyc     
    
    xor r9, r9               ; patrz komentarz z negation_array
    jmp is_minimal

negation_divisor: 
    neg r8
    
    xor r10, r10                  ; dzielnik jest negatywny
    ; mamy ustalona reszte, teraz glowny algorytm:
    jmp loop_main_prepair         ; nalezy odpowiednio ustawic rdx i rcx

check_second_condition:
    ; r9 = 1:
    cmp r10, 0
    je negation_array             ; trzeba zamienic iloraz na przeciwny

    ; r9 = 1 i r10 = 1, zatem mozemy juz zwrocic wynik
    jmp end

negation_rest:
    neg rdx                    

end:
    mov rax, rdx                  ; reszta jest wynikiem funkcji
    ret

is_minimal:
    mov r11, [rdi + rsi*8 - 8]    ; r11 nie jest juz 
    ; potrzebny, bo jest juz po negacji dzielnej do ktorej byl potrzebny
    test r11, r11                 ; gdy najwazniejszy bit 
    ; nadal jest zapalony oznacza to ze dzielna jest najmniejsza liczba
    ; ujemna, jesli dzielnik jest wtedy = -1 to mamy SIGFPE
    jns check_divisor

    ; gdy mamy dzielenie najmniejszej
    ; dzielnej przez dzielnik rowny -1 to chcemy wyslac SIGFPE
    cmp r8, 0xFFFFFFFFFFFFFFFF 
    jne check_divisor

    xor r8, r8                    ; zwykle dzielenie przez 0 zeby dostac

    div r8                        ; SIGFPE
