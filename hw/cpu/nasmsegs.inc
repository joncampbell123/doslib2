%if TARGET_BITS == 16
 %macro CODE_SEGMENT 0
segment _TEXT class=CODE use16
bits 16
 %endmacro

 %macro DATA_SEGMENT 0
segment _DATA class=DATA use16
bits 16
 %endmacro
%endif

%if TARGET_BITS == 32
 %ifdef TARGET_LINUX
  %macro CODE_SEGMENT 0
section .text
bits 32
  %endmacro

  %macro DATA_SEGMENT 0
section .data
bits 32
  %endmacro
 %else
  %macro CODE_SEGMENT 0
section .text class=CODE use32
bits 32
  %endmacro

  %macro DATA_SEGMENT 0
section .data class=DATA use32
bits 32
  %endmacro
 %endif
%endif

%ifdef TARGET_LINUX
 %macro EXTERN_C_FUNCTION 1
global %1
%1:
 %endmacro
%else
 %macro EXTERN_C_FUNCTION 1
global _%1
_%1:
 %endmacro
%endif

