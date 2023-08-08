#include "stdafx.h"
#include <tchar.h>
#include <windows.h>
#include <locale.h>


#define MAX_KEY_LENGTH 255
#define MAX_VALUE_NAME 16383


int main()
{
	TCHAR achCommandKey[MAX_KEY_LENGTH];
	TCHAR achKey[MAX_KEY_LENGTH];
	DWORD cbName;
	TCHAR achClass[MAX_PATH] = _T("");
	DWORD cchClassName = MAX_PATH;
	DWORD cSubKeys = 0;
	DWORD cbMaxSubKey;
	DWORD cchMaxClass;
	DWORD cValues;
	DWORD cchMaxValue;
	DWORD cbMaxValueData;
	DWORD cbSecurityDescriptor;
	FILETIME ftLastWriteTime;

	HKEY hKey;
	auto status = RegOpenKeyEx(HKEY_CLASSES_ROOT, NULL, NULL,
		KEY_QUERY_VALUE | KEY_READ, &hKey);
	 
	if (status != ERROR_SUCCESS) {
		_tprintf(_T("Failed to open key"));
		return -1;
	}

	// for Chinese locale
	_tsetlocale(LC_ALL, _T("chs"));

	TCHAR achValue[MAX_VALUE_NAME];
	DWORD cchValue = MAX_VALUE_NAME;

	status = RegQueryInfoKey(
		hKey,
		achClass,
		&cchClassName,
		NULL,
		&cSubKeys,
		&cbMaxSubKey,
		&cchMaxClass,
		&cValues,
		&cchMaxValue,
		&cbMaxValueData,
		&cbSecurityDescriptor,
		&ftLastWriteTime);

	if (!cSubKeys) {
		_tprintf(_T("Failed to enumerate sub keys"));
		return -1;
	}

	_tprintf(_T("Number of subkeys: %d \n"), cSubKeys);

	for (DWORD i = 0; i < cSubKeys; i++)
	{
		cbName = MAX_KEY_LENGTH;
		status = RegEnumKeyEx(hKey, i, achKey, &cbName, NULL, NULL, NULL, &ftLastWriteTime);

		cchValue = MAX_KEY_LENGTH;
		if (status == ERROR_SUCCESS && RegGetValue(HKEY_CLASSES_ROOT, achKey, _T("URL Protocol"),
			RRF_RT_REG_SZ, NULL, achValue, &cchValue) == 0) {
			_tprintf(_T("%ls: "), achKey);
			_sntprintf_s(achCommandKey, MAX_KEY_LENGTH, _T("%ls\\shell\\open\\command"), achKey);

			cchValue = MAX_KEY_LENGTH;
			status = RegGetValue(HKEY_CLASSES_ROOT, achCommandKey, _T(""), RRF_RT_REG_SZ, NULL, achValue, &cchValue);
			if (status == ERROR_SUCCESS) {
				_tprintf(_T("%ls"), achValue);
			}
			_tprintf(_T("\n"));
		}
	}

	RegCloseKey(hKey);
	return 0;
}
