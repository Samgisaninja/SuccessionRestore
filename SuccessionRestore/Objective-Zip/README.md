

Objective-Zip
=============


Introduction
------------

Objective-Zip is a small Objective-C library that wraps ZLib and MiniZip in
an object-oriented friendly way.


What is contained here
----------------------

The source repository contains full sources for ZLib, MiniZip and
Objective-Zip, together with some unit tests. The versions included are:

- 1.2.8 for [ZLib](http://zlib.net).
- 1.1 (as of 13/5/2017) for [MiniZip](https://github.com/nmoinvaz/minizip).
- latest version for Objective-Zip.

Please note that ZLib and MiniZip are included here only to provide a
complete and self-contained package, but they are copyrighted by their
respective authors and redistributed on respect of their software
license. Please refer to their websites (linked above) for more
informations.


Getting started
===============

Objective-Zip exposes basic functionalities to read and write zip files,
encapsulating both ZLib for the compression mechanism and MiniZip for
the zip wrapping.


Adding Objective-Zip to your project
------------------------------------

The library is distributed via CocoaPods, you can add a dependency in you pod
file with the following line:

pod 'objective-zip', '~> 1.0'

You can then access Objective-Zip classes with the following import
statement if you plan to use exception handling:

```objective-c
#import "Objective-Zip.h"
```

Alternatively you can use the following import statement if you plan to use
Apple's NSError pattern:

```objective-c
#import "Objective-Zip+NSError.h"
```

More on error handling at the end of this document.


Main concepts
-------------

Objective-Zip is centered on a class called (with a lack of fantasy)
OZZipFile. It can be created with the common Objective-C procedure of an
alloc followed by an init, specifying in the latter if the zip file is
being created, appended or unzipped:

```objective-c
OZZipFile *zipFile= [[OZZipFile alloc] initWithFileName:@"test.zip"
    mode:OZZipFileModeCreate];
```

Creating and appending are both write-only modalities, while unzipping
is a read-only modality. You can not request reading operations on a
write-mode zip file, nor request writing operations on a read-mode zip
file.


Adding a file to a zip file
---------------------------

The ZipFile class has a couple of methods to add new files to a zip
file, one of which keeps the file in clear and the other encrypts it
with a password. Both methods return an instance of a OZZipWriteStream
class, which will be used solely for the scope of writing the content of
the file, and then must be closed:

```objective-c
OZZipWriteStream *stream= [zipFile writeFileInZipWithName:@"abc.txt"
    compressionLevel:OZZipCompressionLevelBest];

[stream writeData:abcData];
[stream finishedWriting];
```


Adding a file to a zip file using encryption
--------------------------------------------

Objective-Zip supports only traditional PKWare encryption, which is also the
format most widely supported by common unzip utilities.

To add a file with encryption, it is necessary to precompute a CRC32 of
the file being added. This is needed by traditional PKWare encryption 
to later verify that the password provided for decryption is correct.

The library includes a handy crc32 method as an NSData category 
(automatically imported under the umbrella header): 

```objective-c
NSData *fileData= // Your file data
uint32_t crc= [fileData crc32];

OZZipWriteStream *stream= [zipFile writeFileInZipWithName:@"abc.txt"
    compressionLevel:OZZipCompressionLevelBest
    password:@"password"
    crc32:crc];

[stream writeData:fileData];
[stream finishedWriting];
```

Note that passing 0 (or any other non-CRC32 number) as the crc32 argument will make
the decryption fail, even if the correct password is specified.

Note also that if your file is too large to be stored in a single NSData, you
can still compute the CRC32 progressively by using a loop:

```objective-c
NSFileHandle *fileHandle= // Your file handle

uint32_t crc= 0;
do {

    // Read a chunk of the file in data buffer 
    NSData *data= [fileHandle readDataOfLength:BUFFER_SIZE];
    if ([data length] == 0)
        break;

    crc= [data crc32withInitialCrc32:crc];

} while (YES);
```


Reading a file from a zip file
------------------------------

The OZZipFile class, when used in unzip mode, must be treated like a
cursor: you position the instance on a file at a time, either by
step-forwarding or by locating the file by name. Once you are on the
correct file, you can obtain an instance of a OZZipReadStream that will
let you read the content (and then must be closed).

Since the file may not fit into memory, you can read it block by block using
a buffer:

```objective-c
OZZipFile *unzipFile= [[OZZipFile alloc] initWithFileName:@"test.zip"
    mode:OZZipFileModeUnzip];

[unzipFile goToFirstFileInZip];

OZZipReadStream *read= [unzipFile readCurrentFileInZip];
NSMutableData *data= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];

do {

    // Reset buffer length
    [data setLength:BUFFER_SIZE];

    // Read bytes and check for end of file
    int bytesRead= [read readDataWithBuffer:data];
    if (bytesRead <= 0)
        break;

    [data setLength:bytesRead];

    // Do something with data

} while (YES);

[read finishedReading];
```

Alternatively, if you know in advance the file will fit into memory, you may
preallocate a buffer big enough and read the all file at once. In the example
below the buffer is preallocated with precisely the uncompressed size of the
file:

```objective-c
OZZipFile *unzipFile= [[OZZipFile alloc] initWithFileName:@"test.zip"
    mode:OZZipFileModeUnzip];

[unzipFile goToFirstFileInZip];
OZFileInZipInfo *info= [unzipFile getCurrentFileInZipInfo];

OZZipReadStream *read= [unzipFile readCurrentFileInZip];
NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
[read readDataWithBuffer:data];

// Do something with data

[read finishedReading];
```

Note that the NSMutableData instance that acts as the read buffer must
have been set with a length greater than 0: the `readDataWithBuffer` API
will use that length to know how many bytes it can fetch from the zip
file.


Listing files in a zip file
---------------------------

When the ZipFile class is used in unzip mode, it can also list the files
contained in zip by filling an NSArray with instances of FileInZipInfo
class. You can then use its name property to locate the file inside the
zip and expand it:

```objective-c
OZZipFile *unzipFile= [[OZZipFile alloc] initWithFileName:@"test.zip"
    mode:OZZipFileModeUnzip];

NSArray *infos= [unzipFile listFileInZipInfos];
for (OZFileInZipInfo *info in infos) {
    NSLog(@"- %@ %@ %llu (%d)", info.name, info.date, info.size, info.level);

    // Locate the file in the zip
    [unzipFile locateFileInZip:info.name];

    // Expand the file in memory
    OZZipReadStream *read= [unzipFile readCurrentFileInZip];
    NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
    int bytesRead= [read readDataWithBuffer:data];
    [read finishedReading];
}
```

Note that the OZFileInZipInfo class provide two sizes:

- **length** is the original (uncompressed) file size, while
- **size** is the compressed file size.


Closing the zip file
--------------------

Remember, when you are done, to close your OZZipFile instance to avoid
file corruption problems:

```objective-c
[zipFile close];
```


File/folder hierarchy inide the zip
-----------------------------------

Please note that inside the zip files there is no representation of a
file-folder hierarchy: it is simply embedded in file names (i.e.: a file
with a name like "x/y/z/file.txt"). It is up to the program that
extracts files to consider these file names as expressing a structure and
rebuild it on the file system (and viceversa during creation). Common
zippers/unzippers simply follow this rule.


Error handling
--------------

Objective-Zip provides two kinds of error handling:

- standard exception handling;
- Apple's NSError pattern.

With standard exception handling, Objective-Zip will throw an exception of
class OZZipException any time an error occurs (programmer or runtime errors).

To use standard exception handling import Objective-Zip in your project with
this statement:

```objective-c
#import "Objective-Zip.h"
```

With Apple's NSError pattern, Objective-Zip will expect a NSError
pointer-to-pointer argument and will fill it with an NSError instance
whenever a runtime error occurs. Will revert to throwing an exception (of
OZZipException class) in case of programmer errors.

To use Apple's NSError pattern import Objective-Zip in your project with this
statement:

```objective-c
#import "Objective-Zip+NSError.h"
```

Apple's NSError pattern is of course mandatory with Swift programming
language, since it does not support exception handling.


Differences in the interface
----------------------------

Note that a few minor differences exist in the standard interface vs. the
NSError pattern interface. Specifically:

* `[OZZipFile locateFileInZip:error:]` returns a `NSInteger` in place of a
`BOOL`. Here the special values `OZLocateFileResultNotFound` and
`OZLocateFileResultNotFound`, respectively `1` and `-1`, are used in place of
`YES` and `NO`, since `0` is reserved for the case where an error occurred.
* `[OZZipReadStream readDataWithBuffer:error:]` similarly returns a
`NSInteger` in place of a `NSUInteger`. Here the special value
`OZReadStreamResultEndOfFile`, corresponding to `-1`, is used for the
end-of-file case, since `0` is again reserved for error occurrence.


License
=======

The library is distributed under the New BSD License.


Version history
===============

Version 1.0.5:

- Improved support for computation of CRC32

Version 1.0.4:

- Updated to latest version of MiniZip (as of 13/5/2017)
- Added unit tests for 32/64 cross compatibility
- Added unit tests for encryption/decryption with password

Version 1.0.3:

- Fixed some memory leaks in MiniZip (contributed by @SheffieldKevin)
- Silenced a warning about shifting a negative value in ZLib (contributed by Martin Winter)
- Fixed throwing of errors so that it is compatible with Swift 3 (contributed by @andyj-at-aspin)
- Fixed typos and errors in README (contributed by @deni2s)

Version 1.0.2:

- Fixed interface for `locateFileInZip` and `readDataWithBuffer` in NSError
  version so that they correctly support Swift error handling.

Version 1.0.1:

- Fixed compatibility bugs with Swift
- Added Swift unit tests
- Merged back GETTING STARTED in README

Version 1.0.0:

- Added official podspec to distribute via CocoaPods.
- Added API docs.
- Added nullability annotations.
- Refactored DIY tests as unit tests.
- Added targets for static libraries.
- Added alternative interfaces with NSError pattern in place of exceptions.
- Added support for legacy 32-bit zip files.
- Added class prefix "OZ" to make Objective-Zip a good citizen.
- Fully ARC-ified (removed ARCHelper)
- Some code clean-up.

Version 0.8.3:

- Finally used correctly the 64 bit APIs. Thanks to Nathan Moinvaziri for advicing.
- Updated test code to zip & unzip up to 5 GB.
- Added tests with unzip & check of zip files create with Mac OS X 10.8 and Windows 7.

Version 0.8.2:

- Updated ZLib to 1.2.8
- Updated MiniZip to Nathan Moinvaziri's Version (thanks [Sergio](http://mrsergio.com) for the suggestions)
- Added test code to zip & unzip up to (slighlty less than) 4 GB:
  the library is able to create and expand files up to
  4,293,387,000 bytes (compressed); use the test with caution,
  requires 4 GB of free space and around 10 minutes on the
  iOS simulator

Version 0.8.1:

- Added support for ARC through Nick Lockwood's [ARC Helper](https://gist.github.com/1563325)

Version 0.8:

- Updated ZLib to 1.2.7
- Updated MiniZip to 1.1
- Added method to get file name from a ZipFile instance

Version 0.7.3:

- Fixed memory leak in test app

Version 0.7.2:

- Added variant of writeFileInZipWithName that accepts also a file date
- Fixed bug with date handling

Version 0.7.1:

- Fixed a bug in creation of an encrypted zip file

Version 0.7.0:

- Initial public beta release


Compatibility
=============

Version 1.0.5 has been tested with iOS up to 10.3 and OS X up to 10.12, but
should be compatible with earlier versions too, down to iOS 8.0 and OS X 10.7.
Le me know of any issues that should arise.

