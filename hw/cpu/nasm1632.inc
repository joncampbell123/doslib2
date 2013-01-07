
%if TARGET_BITS == 16
 %ifndef MMODE
  %error You must specify MMODE variable (memory model) for 16-bit real mode code
 %endif

 %ifidni MMODE,l
  %define retnative retf
  %define TARGET16_DEF_FARCALL 1
  %define retnative_stack_size 4
  %define stack_argv_ptr_size 4
 %else
  %ifidni MMODE,m
   %define retnative retf
   %define TARGET16_DEF_FARCALL 1
   %define retnative_stack_size 4
   %define stack_argv_ptr_size 4
  %else
   %define retnative ret
   %define TARGET16_DEF_NEARCALL 1
   %define retnative_stack_size 2
   %define stack_argv_ptr_size 2
  %endif
 %endif
 %define nsi si
 %define nbp bp
 %define nsp sp
 %define nbx bx
 %define pushan pusha
 %define popan popa
 %define stackbase bp
 %define stackpointer sp
 %define pusha_stack_size 16
%endif
%if TARGET_BITS == 32
 %define retnative ret
 %define TARGET16_DEF_NEARCALL 1
 %define retnative_stack_size 4
 %define nsi esi
 %define nbp ebp
 %define nsp esp
 %define nbx ebx
 %define pushan pushad
 %define popan popad
 %define stackbase ebp
 %define stackpointer esp
 %define pusha_stack_size 32
 %define stack_argv_ptr_size 4
%endif

%if TARGET_BITS == 16
 %ifidni MMODE,l
  %define stack_argv_ptr_load(srg,a,b)   l%+srg a,[b]
  %define push_if_far_argv(x)            push x
  %define pop_if_far_argv(x)             pop x
 %endif
 %ifidni MMODE,c
  %define stack_argv_ptr_load(srg,a,b)   l%+srg a,[b]
  %define push_if_far_argv(x)            push x
  %define pop_if_far_argv(x)             pop x
 %endif
 %ifidni MMODE,h
  %define stack_argv_ptr_load(srg,a,b)   l%+srg a,[b]
  %define push_if_far_argv(x)            push x
  %define pop_if_far_argv(x)             pop x
 %endif
 %ifidni MMODE,m
  %define stack_argv_ptr_load(srg,a,b)   mov a,[b]
  %define push_if_far_argv(x)
  %define pop_if_far_argv(x)
 %endif
 %ifidni MMODE,s
  %define stack_argv_ptr_load(srg,a,b)   mov a,[b]
  %define push_if_far_argv(x)
  %define pop_if_far_argv(x)
 %endif
%endif
%if TARGET_BITS == 32
 %define push_if_far_argv(x)
 %define pop_if_far_argv(x)
 %define stack_argv_ptr_load(srg,a,b)   mov a,[b]
%endif

