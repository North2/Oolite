//	
//	OOErrorDescription.m
//	
/*

Copyright © 2005, Jens Ayton
All rights reserved.

This work is licensed under the Creative Commons Attribution-ShareAlike License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/2.0/
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

You are free:

•	to copy, distribute, display, and perform the work
•	to make derivative works

Under the following conditions:

•	Attribution. You must give the original author credit.

•	Share Alike. If you alter, transform, or build upon this work,
you may distribute the resulting work only under a license identical to this one.

For any reuse or distribution, you must make clear to others the license terms of this work.

Any of these conditions can be waived if you get permission from the copyright holder.

Your fair use and other rights are in no way affected by the above.

*/

#import "OOErrorDescription.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Carbon/Carbon.h>


#define CASE(foo) case foo: return @#foo


#ifndef NDEBUG
static NSString *GetGenericOSStatusString(OSStatus inCode);
#endif


NSString *OSStatusErrorNSString(OSStatus inCode)
{
	NSString					*result = nil;
	
	#ifndef NDEBUG
		result = GetGenericOSStatusString(inCode);
	#else
		if (noErr == inCode) result = @"no error";
	#endif
	
	if (nil == result) result = [NSString stringWithFormat:@"%i", (int)inCode];
	
	return result;
}


NSString *AudioErrorNSString(ComponentResult inCode)
{
	#ifndef NDEBUG
		switch (inCode)
		{
			CASE(kAudioConverterErr_FormatNotSupported);
			CASE(kAudioConverterErr_OperationNotSupported);
			CASE(kAudioConverterErr_PropertyNotSupported);
			CASE(kAudioConverterErr_InvalidInputSize);
			CASE(kAudioConverterErr_InvalidOutputSize);
			CASE(kAudioConverterErr_UnspecifiedError);
			CASE(kAudioConverterErr_BadPropertySizeError);
			CASE(kAudioConverterErr_RequiresPacketDescriptionsError);
			CASE(kAudioConverterErr_InputSampleRateOutOfRange);
			CASE(kAudioConverterErr_OutputSampleRateOutOfRange);
			
			CASE(kAudioCodecUnknownPropertyError);
			CASE(kAudioCodecIllegalOperationError);
			CASE(kAudioCodecUnsupportedFormatError);
			CASE(kAudioCodecStateError);
			CASE(kAudioCodecNotEnoughBufferSpaceError);
			
			CASE(kAudioUnitErr_InvalidProperty);
			CASE(kAudioUnitErr_InvalidParameter);
			CASE(kAudioUnitErr_InvalidElement);
			CASE(kAudioUnitErr_NoConnection);
			CASE(kAudioUnitErr_FailedInitialization);
			CASE(kAudioUnitErr_TooManyFramesToProcess);
			CASE(kAudioUnitErr_IllegalInstrument);
			CASE(kAudioUnitErr_InstrumentTypeNotFound);
			CASE(kAudioUnitErr_InvalidFile);
			CASE(kAudioUnitErr_UnknownFileType);
			CASE(kAudioUnitErr_FileNotSpecified);
			CASE(kAudioUnitErr_FormatNotSupported);
			CASE(kAudioUnitErr_Uninitialized);
			CASE(kAudioUnitErr_InvalidScope);
			CASE(kAudioUnitErr_PropertyNotWritable);
			CASE(kAudioUnitErr_CannotDoInCurrentContext);
			CASE(kAudioUnitErr_InvalidPropertyValue);
			CASE(kAudioUnitErr_PropertyNotInUse);
			CASE(kAudioUnitErr_Initialized);
			CASE(kAudioUnitErr_InvalidOfflineRender);
			CASE(kAudioUnitErr_Unauthorized);
			
			CASE(kAUGraphErr_NodeNotFound);
			CASE(kAUGraphErr_InvalidConnection);
			CASE(kAUGraphErr_OutputNodeErr);
			CASE(kAUGraphErr_InvalidAudioUnit);
			
			default:
			{
				NSString *result = GetGenericOSStatusString(inCode);
				if (nil != result) return result;
			}
		}
	#else
		if (noErr == inCode) return @"no error";
	#endif
	
	return AudioErrorShortNSString(inCode);
}


NSString *AudioErrorShortNSString(OSStatus inCode)
{
	#define PRINTABLE(x) (!((x) < ' ') && !((x) == 0x7F))
	
	if (!(inCode & 0x80000000) &&
		PRINTABLE(inCode >> 24) &&
		PRINTABLE((inCode >> 16) & 0xFF) &&
		PRINTABLE((inCode >> 8) & 0xFF) &&
		PRINTABLE(inCode & 0xFF))
	{
		// Assume a four-char code
		return [NSString stringWithFormat:@"\'%@\'", FourCharCodeToNSString(inCode)];
	}
	else
	{
		return [NSString stringWithFormat:@"%i", (int)inCode];
	}
}


NSString *KernelResultNSString(kern_return_t inCode)
{
	#ifndef NDEBUG
		switch (inCode)
		{
			CASE(KERN_INVALID_ADDRESS);
			CASE(KERN_PROTECTION_FAILURE);
			CASE(KERN_NO_SPACE);
			CASE(KERN_INVALID_ARGUMENT);
			CASE(KERN_FAILURE);
			CASE(KERN_RESOURCE_SHORTAGE);
			CASE(KERN_NOT_RECEIVER);
			CASE(KERN_NO_ACCESS);
			CASE(KERN_MEMORY_FAILURE);
			CASE(KERN_MEMORY_ERROR);
			CASE(KERN_ALREADY_IN_SET);
			CASE(KERN_NOT_IN_SET);
			CASE(KERN_NAME_EXISTS);
			CASE(KERN_ABORTED);
			CASE(KERN_INVALID_NAME);
			CASE(KERN_INVALID_TASK);
			CASE(KERN_INVALID_RIGHT);
			CASE(KERN_INVALID_VALUE);
			CASE(KERN_UREFS_OVERFLOW);
			CASE(KERN_INVALID_CAPABILITY);
			CASE(KERN_RIGHT_EXISTS);
			CASE(KERN_INVALID_HOST);
			CASE(KERN_MEMORY_PRESENT);
			CASE(KERN_MEMORY_DATA_MOVED);
			CASE(KERN_MEMORY_RESTART_COPY);
			CASE(KERN_INVALID_PROCESSOR_SET);
			CASE(KERN_POLICY_LIMIT);
			CASE(KERN_INVALID_POLICY);
			CASE(KERN_INVALID_OBJECT);
			CASE(KERN_ALREADY_WAITING);
			CASE(KERN_DEFAULT_SET);
			CASE(KERN_EXCEPTION_PROTECTED);
			CASE(KERN_INVALID_LEDGER);
			CASE(KERN_INVALID_MEMORY_CONTROL);
			CASE(KERN_INVALID_SECURITY);
			CASE(KERN_NOT_DEPRESSED);
			CASE(KERN_TERMINATED);
			CASE(KERN_LOCK_SET_DESTROYED);
			CASE(KERN_LOCK_UNSTABLE);
			CASE(KERN_LOCK_OWNED);
			CASE(KERN_LOCK_OWNED_SELF);
			CASE(KERN_SEMAPHORE_DESTROYED);
			CASE(KERN_RPC_SERVER_TERMINATED);
			CASE(KERN_RPC_TERMINATE_ORPHAN);
			CASE(KERN_RPC_CONTINUE_ORPHAN);
			CASE(KERN_NOT_SUPPORTED);
			CASE(KERN_NODE_DOWN);
			CASE(KERN_NOT_WAITING);
			CASE(KERN_OPERATION_TIMED_OUT);
			CASE(MACH_MSG_IPC_SPACE);
			CASE(MACH_MSG_VM_SPACE);
			CASE(MACH_MSG_IPC_KERNEL);
			CASE(MACH_MSG_VM_KERNEL);
			CASE(MACH_SEND_IN_PROGRESS);
			CASE(MACH_SEND_INVALID_DATA);
			CASE(MACH_SEND_INVALID_DEST);
			CASE(MACH_SEND_TIMED_OUT);
			CASE(MACH_SEND_INTERRUPTED);
			CASE(MACH_SEND_MSG_TOO_SMALL);
			CASE(MACH_SEND_INVALID_REPLY);
			CASE(MACH_SEND_INVALID_RIGHT);
			CASE(MACH_SEND_INVALID_NOTIFY);
			CASE(MACH_SEND_INVALID_MEMORY);
			CASE(MACH_SEND_NO_BUFFER);
			CASE(MACH_SEND_TOO_LARGE);
			CASE(MACH_SEND_INVALID_TYPE);
			CASE(MACH_SEND_INVALID_HEADER);
			CASE(MACH_SEND_INVALID_TRAILER);
			CASE(MACH_SEND_INVALID_RT_OOL_SIZE);
			CASE(MACH_RCV_IN_PROGRESS);
			CASE(MACH_RCV_INVALID_NAME);
			CASE(MACH_RCV_TIMED_OUT);
			CASE(MACH_RCV_TOO_LARGE);
			CASE(MACH_RCV_INTERRUPTED);
			CASE(MACH_RCV_PORT_CHANGED);
			CASE(MACH_RCV_INVALID_NOTIFY);
			CASE(MACH_RCV_INVALID_DATA);
			CASE(MACH_RCV_PORT_DIED);
			CASE(MACH_RCV_IN_SET);
			CASE(MACH_RCV_HEADER_ERROR);
			CASE(MACH_RCV_BODY_ERROR);
			CASE(MACH_RCV_INVALID_TYPE);
			CASE(MACH_RCV_SCATTER_SMALL);
			CASE(MACH_RCV_INVALID_TRAILER);
			CASE(MACH_RCV_IN_PROGRESS_TIMED);
			
			case 0: return @"no error";
		}
	#else
		if (0 == inCode) return @"no error";
	#endif
	
	return [NSString stringWithFormat:@"0x%.8X", (unsigned)inCode];
}


NSString *FourCharCodeToNSString(FourCharCode inCode)
{
	return [[[NSString alloc] initWithBytes:&inCode length:4 encoding:NSMacOSRomanStringEncoding] autorelease];
}


#ifndef NDEBUG
static NSString *GetGenericOSStatusString(OSStatus inCode)
{
	switch (inCode)
	{
		case noErr: return @"no error";
		
		CASE(paramErr);
		CASE(memFullErr);
		CASE(unimpErr);
		CASE(userCanceledErr);
		CASE(dskFulErr);
		CASE(fnfErr);
		CASE(errFSBadFSRef);
		CASE(gestaltUnknownErr);
	}
	
	return nil;
}
#endif


NSString *ErrnoToNSString(int inErrno)
{
	#ifndef NDEBUG
		switch (inErrno)
		{
			CASE(EPERM);
			CASE(ENOENT);
			CASE(ESRCH);
			CASE(EINTR);
			CASE(EIO);
			CASE(ENXIO);
			CASE(E2BIG);
			CASE(ENOEXEC);
			CASE(EBADF);
			CASE(ECHILD);
			CASE(EDEADLK);
			CASE(ENOMEM);
			CASE(EACCES);
			CASE(EFAULT);
			CASE(EBUSY);
			CASE(EEXIST);
			CASE(EXDEV);
			CASE(ENODEV);
			CASE(ENOTDIR);
			CASE(EISDIR);
			CASE(EINVAL);
			CASE(ENFILE);
			CASE(EMFILE);
			CASE(ENOTTY);
			CASE(ETXTBSY);
			CASE(EFBIG);
			CASE(ENOSPC);
			CASE(ESPIPE);
			CASE(EROFS);
			CASE(EMLINK);
			CASE(EPIPE);
			CASE(EDOM);
			CASE(ERANGE);
			CASE(EWOULDBLOCK);
			CASE(EINPROGRESS);
			CASE(EALREADY);
			CASE(ENOTSOCK);
			CASE(EDESTADDRREQ);
			CASE(EMSGSIZE);
			CASE(EPROTOTYPE);
			CASE(ENOPROTOOPT);
			CASE(EPROTONOSUPPORT);
			CASE(EAFNOSUPPORT);
			CASE(EADDRINUSE);
			CASE(EADDRNOTAVAIL);
			CASE(ENETDOWN);
			CASE(ENETUNREACH);
			CASE(ENETRESET);
			CASE(ECONNABORTED);
			CASE(ECONNRESET);
			CASE(ENOBUFS);
			CASE(EISCONN);
			CASE(ENOTCONN);
			CASE(ETIMEDOUT);
			CASE(ECONNREFUSED);
			CASE(ELOOP);
			CASE(ENAMETOOLONG);
			CASE(EHOSTUNREACH);
			CASE(ENOTEMPTY);
			CASE(EDQUOT);
			CASE(ESTALE);
			CASE(ENOLCK);
			CASE(ENOSYS);
			CASE(EOVERFLOW);
			CASE(ECANCELED);
			CASE(EIDRM);
			CASE(ENOMSG);
			CASE(EILSEQ);
		/*
			CASE(EBADMSG);
			CASE(EMULTIHOP);
			CASE(ENODATA);
			CASE(ENOLINK);
			CASE(ENOSR);
			CASE(ENOSTR);
			CASE(EPROTO);
			CASE(ETIME);
		*/
		
		#ifndef _POSIX_C_SOURCE
			CASE(ENOTBLK);
			CASE(ESOCKTNOSUPPORT);
			CASE(EPFNOSUPPORT);
			CASE(ESHUTDOWN);
			CASE(ETOOMANYREFS);
			CASE(EHOSTDOWN);
			CASE(EPROCLIM);
			CASE(EUSERS);
			CASE(EREMOTE);
			CASE(EBADRPC);
			CASE(ERPCMISMATCH);
			CASE(EPROGUNAVAIL);
			CASE(EPROGMISMATCH);
			CASE(EPROCUNAVAIL);
			CASE(EFTYPE);
			CASE(EAUTH);
			CASE(ENEEDAUTH);
			CASE(EPWROFF);
			CASE(EDEVERR);
			CASE(EBADEXEC);
			CASE(EBADARCH);
			CASE(ESHLIBVERS);
			CASE(EBADMACHO);
			CASE(ENOATTR);
		#endif
		}
	#endif
	
	return [NSString stringWithFormat:@"%i", (int)inErrno];
}
