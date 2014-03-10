%ifdef TARGET_WINDOWS_WIN16
 %define CLI_IS_ALLOWED
%endif
%ifdef TARGET_WINDOWS_WIN386
 %define CLI_IS_ALLOWED
%endif
%ifdef TARGET_MSDOS
 %define CLI_IS_ALLOWED
%endif

%ifdef CLI_IS_ALLOWED
 %define cli_if_allowed cli
 %define sti_if_allowed sti
%else
 %define cli_if_allowed
 %define sti_if_allowed
%endif

