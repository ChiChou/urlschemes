# LookForSchemes

## macOS

Compile from console, or use Xcode.

```
➜  /tmp clang -fmodules schemes.m -o schemes
➜  /tmp ./schemes
2018-01-25 19:13:16.187 scheme[49119:8943832] ical:
2018-01-25 19:13:16.188 scheme[49119:8943832] 	com.apple.iCal (/Applications/Calendar.app)
2018-01-25 19:13:16.188 scheme[49119:8943832] twitter:
2018-01-25 19:13:16.189 scheme[49119:8943832] 	com.apple.AddressBook.UrlForwarder (/System/Library/CoreServices/AddressBookUrlForwarder.app)
2018-01-25 19:13:16.189 scheme[49119:8943832] ichat:
2018-01-25 19:13:16.189 scheme[49119:8943832] 	com.apple.iChat (/Applications/Messages.app)
2018-01-25 19:13:16.189 scheme[49119:8943832] dash:
2018-01-25 19:13:16.189 scheme[49119:8943832] 	com.kapeli.dashdoc (/Applications/Dash.app)
...
```

## Windows

You may need a Visual Studio, or rewrite the code with jscript
