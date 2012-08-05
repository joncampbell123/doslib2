#if defined(TARGET_WINDOWS) && defined(TARGET_WINDOWS_GUI)
# include <windows.h>

int WINAPI WinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPSTR lpCmdLine,int nCmdShow) {
	MessageBox(NULL,"Hello","",MB_OK);
	return 0;
}
#else
# include <stdio.h>
# include <stdlib.h>
# include <string.h>

int main() {
	printf("Hello\n");
	return 0;
}
#endif

