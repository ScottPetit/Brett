# Brett

**Untar .tar and .tar.gz (.tgz) files on iOS.**

> Brett is named after [George Howard Brett](http://en.wikipedia.org/wiki/George_Brett),  a retired American Major League Baseball third baseman who spent his entire 21-year baseball career playing for the Kansas City Royals. Brett's 3,154 career hits are the most by any third baseman in major league history and 16th all-time.  During his career he was a core player in the [‘Pine Tar Incident’](http://en.wikipedia.org/wiki/George_Brett#Pine_Tar_Incident).

## Usage

Brett provides two class methods to untar a file given a file path as either a NSURL or an NSString.

General usage would something like this.

```objective-c
NSString *destinationPath = nil;
[Brett untarFileAtURL:filePath withError:&error destinationPath:&destinationPath];
            
if (error)            
{
	NSLog(@“%@“, error);
}
else
{
	NSLog(@“%@“, destinationPath);
 }
```

It’s that easy.
