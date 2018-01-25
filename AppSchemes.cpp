#include "stdafx.h"
#include <iostream>
#include <tchar.h>
#include <windows.h>

using namespace std;

#define MAX_KEY_LENGTH 255
#define MAX_VALUE_NAME 16383

int main()
{
	TCHAR    achCommandKey[MAX_KEY_LENGTH]; // shell/open/command
	TCHAR    achKey[MAX_KEY_LENGTH];   // buffer for subkey name
	DWORD    cbName;                   // size of name string 
	TCHAR    achClass[MAX_PATH] = TEXT("");  // buffer for class name 
	DWORD    cchClassName = MAX_PATH;  // size of class string 
	DWORD    cSubKeys = 0;               // number of subkeys 
	DWORD    cbMaxSubKey;            // longest subkey size 
	DWORD    cchMaxClass;              // longest class string 
	DWORD    cValues;              // number of values for key 
	DWORD    cchMaxValue;          // longest value name 
	DWORD    cbMaxValueData;       // longest value data 
	DWORD    cbSecurityDescriptor; // size of security descriptor 
	FILETIME ftLastWriteTime;      // last write time 

	HKEY hKey, hSubKey;
	auto status = RegOpenKeyEx(HKEY_CLASSES_ROOT, NULL, NULL,
		KEY_QUERY_VALUE | KEY_READ, &hKey);
	if (!SUCCEEDED(status)) {
		cout << "Failed to open key" << endl;
		return -1;
	}

	TCHAR achValue[MAX_VALUE_NAME];
	DWORD cchValue = MAX_VALUE_NAME;

	status = RegQueryInfoKey(
		hKey,                    // key handle 
		achClass,                // buffer for class name 
		&cchClassName,           // size of class string 
		NULL,                    // reserved 
		&cSubKeys,               // number of subkeys 
		&cbMaxSubKey,            // longest subkey size 
		&cchMaxClass,            // longest class string 
		&cValues,                // number of values for this key 
		&cchMaxValue,            // longest value name 
		&cbMaxValueData,         // longest value data 
		&cbSecurityDescriptor,   // security descriptor 
		&ftLastWriteTime);       // last write time 

	if (cSubKeys)
	{
		cout << "Number of subkeys: " << cSubKeys << endl;
		for (DWORD i = 0; i < cSubKeys; i++)
		{
			cbName = MAX_KEY_LENGTH;
			status = RegEnumKeyEx(hKey, i,
				achKey,
				&cbName,
				NULL,
				NULL,
				NULL,
				&ftLastWriteTime);

			cchValue = MAX_KEY_LENGTH;
			if (SUCCEEDED(status) && RegGetValue(HKEY_CLASSES_ROOT, achKey, L"URL Protocol",
				RRF_RT_REG_SZ, NULL, achValue, &cchValue) == 0) {
				_tprintf(L"%s: ", achKey);
				_sntprintf_s(achCommandKey, MAX_KEY_LENGTH, L"%s\\shell\\open\\command", achKey);

				status = RegOpenKeyEx(HKEY_CLASSES_ROOT, achCommandKey, NULL,
					KEY_QUERY_VALUE | KEY_READ, &hSubKey);
				cchValue = MAX_KEY_LENGTH;
				if (SUCCEEDED(status) && RegGetValue(HKEY_CLASSES_ROOT, achCommandKey,
					L"", RRF_RT_REG_SZ, NULL, achValue, &cchValue) == 0) {
					_tprintf(L"%s", achValue);
				}
				_tprintf(L"\n");
			}
		}
	}

	RegCloseKey(hKey);
	return 0;
}
