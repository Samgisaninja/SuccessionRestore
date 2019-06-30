//
//  OZZipFile+NSError.h
//  Objective-Zip v. 1.0.5
//
//  Created by Gianluca Bertani on 09/09/15.
//  Copyright 2009-2017 Gianluca Bertani. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//  * Neither the name of Gianluca Bertani nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "OZZipFile.h"


/**
 @brief Indicates the file could not be located in the zip file.
 */
static const NSInteger OZLocateFileResultNotFound= -1;

/**
 @brief Indicates the file has been successfully located in the zip file.
 */
static const NSInteger OZLocateFileResultFound= 1;


@interface OZZipFile (NSError)


#pragma mark -
#pragma mark Initialization (NSError variants)

/**
 @brief Creates a OZZipFile with the specified zip file name and access mode.
 <p>The access mode specifies if the zip is being created, appended, or
 unzipped.</p>
 <p>Note: the zip file is opened in 64-bit mode.</p>
 @param fileName File name of the zip file.
 @param mode Access mode, can be:<ul>
 <li>OZZipFileModeUnzip: the zip file is opened for reading.
 <li>OZZipFileModeCreate: the zip file is opened for creation.
 <br/>Note: if the file already exists the behavior is unspecified.
 <li>OZZipFileModeAppend: the zip file is opened for writing.
 </ul>
 @param error If passed, may be filled with an NSError is case the file
 can't be opened.
 @throws OZZipException If the access mode is invalid.
 */
- (nullable instancetype) initWithFileName:(nonnull NSString *)fileName mode:(OZZipFileMode)mode error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Creates a OZZipFile with the specified zip file name, access mode and
 legacy 32-bit mode compatibility.
 <p>The access mode specifies if the zip is being created, appended, or
 unzipped.</p>
 @param fileName File name of the zip file.
 @param mode Access mode, can be:<ul>
 <li>OZZipFileModeUnzip: the zip file is opened for reading.
 <li>OZZipFileModeCreate: the zip file is opened for creation.
 <br/>Note: if the file already exists the behavior is unspecified.
 <li>OZZipFileModeAppend: the zip file is opened for writing.
 </ul>
 @param legacy32BitMode If set, the zip file is opened in 32-bit mode to
 provide compatibility with older operating systems (such as some
 version of Android).
 @param error If passed, may be filled with an NSError is case the file
 can't be opened.
 @throws OZZipException If the access mode is invalid.
 */
- (nullable instancetype) initWithFileName:(nonnull NSString *)fileName mode:(OZZipFileMode)mode legacy32BitMode:(BOOL)legacy32BitMode error:(NSError * __autoreleasing __nullable * __nullable)error;


#pragma mark -
#pragma mark File writing (NSError variants)

/**
 @brief Creates a new OZZipWriteStream for adding a new file in the zip file
 content.
 <p>The returned write stream can be used to write data to the new file.</p>
 <p>Note: the new file is added with the current date/time.</p>
 @param fileNameInZip Name of the new file that must be added to the zip file
 content.
 <br/>Note: to structure the zip file with directories and subdirectories,
 ensure to prepend them in the file name, e.g. "docs/html/index.html"
 @param compressionLevel The compression level that must be used to compress
 the new file added to the zip file content. Can be:<ul>
 <li>OZZipCompressionLevelNone: does not compress the new file, it is stored
 as is.
 <li>OZZipCompressionLevelFastest: uses the fastest compression level, which
 also compresses the least.
 <li>OZZipCompressionLevelBest: uses the best compression level, which is also
 the slowest.
 <li>OZZipCompressionLevelDefault: uses the default compression level,
 somewhere inbetween OZZipCompressionLevelBest and
 OZZipCompressionLevelFastest.
 </ul>
 @param error If passed, may be filled with an NSError is case the write
 stream can't be opened.
 @return A new OZZipWriteStream for writing data to the new file in the zip
 file content, or <code>nil</code> if an error occurs.
 @throws OZZipException If the zip file has been opened in unzip mode.
 */
- (nullable OZZipWriteStream *) writeFileInZipWithName:(nonnull NSString *)fileNameInZip compressionLevel:(OZZipCompressionLevel)compressionLevel error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Creates a new OZZipWriteStream for adding a new file in the zip file
 content.
 <p>The returned write stream can be used to write data to the new file.</p>
 @param fileNameInZip Name of the new file that must be added to the zip file
 content.
 <br/>Note: to structure the zip file with directories and subdirectories,
 ensure to prepend them in the file name, e.g. "docs/html/index.html"
 @param fileDate The date/time of the new file that must be added to the zip
 file content.
 @param compressionLevel The compression level that must be used to compress
 the new file added to the zip file content. Can be:<ul>
 <li>OZZipCompressionLevelNone: does not compress the new file, it is stored
 as is.
 <li>OZZipCompressionLevelFastest: uses the fastest compression level, which
 also compresses the least.
 <li>OZZipCompressionLevelBest: uses the best compression level, which is also
 the slowest.
 <li>OZZipCompressionLevelDefault: uses the default compression level,
 somewhere inbetween OZZipCompressionLevelBest and
 OZZipCompressionLevelFastest.
 </ul>
 @param error If passed, may be filled with an NSError is case the write
 stream can't be opened.
 @return A new OZZipWriteStream for writing data to the new file in the zip
 file content, or <code>nil</code> if an error occurs.
 @throws OZZipException If the zip file has been opened in unzip mode.
 */
- (nullable OZZipWriteStream *) writeFileInZipWithName:(nonnull NSString *)fileNameInZip fileDate:(nonnull NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Creates a new OZZipWriteStream for adding a new encrypted file in the
 zip file content.
 <p>The returned write stream can be used to write data to the new file.</p>
 @param fileNameInZip Name of the new file that must be added to the zip file
 content.
 <br/>Note: to structure the zip file with directories and subdirectories,
 ensure to prepend them in the file name, e.g. "docs/html/index.html"
 @param fileDate The date/time of the new file that must be added to the zip
 file content.
 @param compressionLevel The compression level that must be used to compress
 the new file added to the zip file content. Can be:<ul>
 <li>OZZipCompressionLevelNone: does not compress the new file, it is stored
 as is.
 <li>OZZipCompressionLevelFastest: uses the fastest compression level, which
 also compresses the least.
 <li>OZZipCompressionLevelBest: uses the best compression level, which is also
 the slowest.
 <li>OZZipCompressionLevelDefault: uses the default compression level,
 somewhere inbetween OZZipCompressionLevelBest and
 OZZipCompressionLevelFastest.
 </ul>
 @param password The password that must be used to encrypt the new file data.
 @param crc32 A precomputed CRC32 of the new file data (needed for crypting).
 @param error If passed, may be filled with an NSError is case the write
 stream can't be opened.
 @return A new OZZipWriteStream for writing data to the new file in the zip
 file content, or <code>nil</code> if an error occurs.
 @throws OZZipException If the zip file has been opened in unzip mode.
 */
- (nullable OZZipWriteStream *) writeFileInZipWithName:(nonnull NSString *)fileNameInZip fileDate:(nonnull NSDate *)fileDate compressionLevel:(OZZipCompressionLevel)compressionLevel password:(nonnull NSString *)password crc32:(uint32_t)crc32 error:(NSError * __autoreleasing __nullable * __nullable)error;


#pragma mark -
#pragma mark File seeking and info (NSError variants)

/**
 @brief Moves selection to the first file contained in the zip file.
 <p>The selected file may then be read by obaining a OZZipReadStream with
 <code>readCurrentFileInZip</code>.</p>
 @param error If passed, may be filled with an NSError is case the first file
 can't be selected.
 @return <code>YES</code> if the first file has been selected, <code>NO</code>
 if it could not select the first file due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (BOOL) goToFirstFileInZipWithError:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Moves selection to the next file contained in the zip file.
 <p>The selected file may then be read by obaining a OZZipReadStream with
 <code>readCurrentFileInZip</code>.</p>
 @param error If passed, may be filled with an NSError is case the next file
 can't be selected.
 @return <code>YES</code> if the next file has been selected, <code>NO</code>
 if there were no more files to select in the zip file, or the next file could
 not be selected due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (BOOL) goToNextFileInZipWithError:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Locates a file by name in the zip file and selects it.
 <p>The selected file may then be read by obaining a OZZipReadStream with
 <code>readCurrentFileInZip</code>.</p>
 @param error If passed, may be filled with an NSError is case the file can't
 be located.
 @return <code>OZLocateFileResultFound</code> if the file has been located
 and selected, <code>OZLocateFileResultNotFound</code> if the specified
 file name is not present in the zip file, or <code>0</code> if the file could
 not be located due to an error.
 <br/>NOTE: return value convention is different in the standard (non-NSError
 compliant) interface.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (NSInteger) __attribute__((swift_error(nonnull_error))) locateFileInZip:(nonnull NSString *)fileNameInZip error:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Returns the number of files contained in the zip file.
 @param error If passed, may be filled with an NSError is case the number of
 files could not be obtained.
 @return The number of files contained in the zip file, 0 if the number of
 files could not be obtained due to an error.
 @throws OZZipException If the zip file has been opened with a mode other
 than Unzip.
 */
- (NSUInteger) __attribute__((swift_error(nonnull_error))) numFilesInZipWithError:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Returns a list of OZFileInZipInfo with the information on all the files
 contained in the zip file.
 @param error If passed, may be filled with an NSError is case the list of
 file info could not be obtained.
 @return The list of OZFileInZipInfo with the information on all the files
 contained in the zip file, <code>nil</code> if the list of file info could
 not be obtained due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (nullable NSArray *) listFileInZipInfosWithError:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Returns an OZFileInZipInfo with the information on the currently
 selected file in the zip file.
 @param error If passed, may be filled with an NSError is case the file info
 could not be obtained.
 @return An OZFileInZipInfo with the information on the currently
 selected file in the zip file, <code>nil</code> if the file info could not be
 obtained due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (nullable OZFileInZipInfo *) getCurrentFileInZipInfoWithError:(NSError * __autoreleasing __nullable * __nullable)error;


#pragma mark -
#pragma mark File reading (NSError variants)

/**
 @brief Creates a OZZipReadStream for reading the currently selected file in
 the zip file.
 <p>A file in the zip file can be selected using
 <code>goToFirstFileInZip</code>, <code>goToNextFileInZip</code> and
 <code>locateFileInZip:</code>.</p>
 @param error If passed, may be filled with an NSError is case the read stream
 could not be created.
 @return The OZZipReadStream to be used for reading the currently selected file
 in the zip file, <code>nil</code> if the read stream could not be created
 due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (nullable OZZipReadStream *) readCurrentFileInZipWithError:(NSError * __autoreleasing __nullable * __nullable)error;

/**
 @brief Creates a OZZipReadStream for reading the currently selected file in
 the zip file, if it is encrypted.
 <p>A file in the zip file can be selected using
 <code>goToFirstFileInZip</code>, <code>goToNextFileInZip</code> and
 <code>locateFileInZip:</code>.</p>
 @param password The password that must be used to decrypt the file data.
 @param error If passed, may be filled with an NSError is case the read stream
 could not be created.
 @return The OZZipReadStream to be used for reading the currently selected file
 in the zip file, <code>nil</code> if the read stream could not be created
 due to an error.
 @throws OZZipException If the zip file has been opened with a mode other than
 Unzip.
 */
- (nullable OZZipReadStream *) readCurrentFileInZipWithPassword:(nonnull NSString *)password error:(NSError * __autoreleasing __nullable * __nullable)error;


#pragma mark -
#pragma mark Closing (NSError variants)

/**
 @brief Closes the zip file and releases its resources.
 <p>Once you have finished working with the zip file (e.g. all files have been
 unzipped, or all files have been added), it is important to close it so system
 resources may be freed.</p>
 <p>Note: after the zip file has been closed any subsequent call will result in an
 error.</p>
 @param error If passed, may be filled with an NSError is case the zip file
 could not be closed.
 @return <code>YES</code> if the zip file has been closed, <code>NO</code> if
 the zip file could not be closed due to an error.
 */
- (BOOL) closeWithError:(NSError * __autoreleasing __nullable * __nullable)error;


@end
