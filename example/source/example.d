import std.exception;
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import core.stdc.stdlib;
import std.datetime;
import d_sysdlog.wrap;
import d_sysdlog.bind;

string ZtoString(const char* c)
{
    if (c !is null)
      return to!string(fromStringz(c));
    else
      return null;
}

char* toZString(string s)
{
	char[] ret=cast(char[])s;
	if (ret[$-1]!='\0')
		ret~="\0";
	return ret.ptr;
}
string sanitize(string s)
{
	string ret;
	foreach(c;s)
	{
		if ((c<32)||(c>127))
			continue;
		ret~=c;
	}
	return ret;
}
enum labelMessage="MESSAGE";
enum labelTimestamp="_SOURCE_REALTIME_TIMESTAMP";
enum msgLoginFailure="failed password for ";
int main(string[] args)
{
	auto systemDLog = SystemDLog(0);
	//systemDLog.filter("_COMM=sshd");
	systemDLog.seekHead();
	writefln("number advanced: %s",systemDLog.seekNext());
	int numskip=0;
	string[] ips;
	do
	{
		auto ret=systemDLog.getRecord();
		auto message=(labelMessage in ret)?to!string(sanitize(ret["MESSAGE"])).toLower:null;
		if (labelTimestamp in ret)
		{
			auto timeStampString=ret[labelTimestamp];
			if (isNumeric(timeStampString))
			{
				auto timestamp=SysTime(unixTimeToStdTime(to!ulong(ret[labelTimestamp])/1000000));
				if ((message.indexOf("fail")!=-1) &&(message.indexOf("ssh")!=-1) &&(message.indexOf("gnome-shell")==-1) 
					&& (message.indexOf("you should report this")==-1))
				{
					writefln("Converted Time: %s,%s",timestamp,message);
					auto m=message.countUntil(msgLoginFailure);
					if (m!=-1)
					{
						auto n=indexOf(message[m+msgLoginFailure.length..$], " from ");
						auto iptokens=split(message[m+msgLoginFailure.length+n+" from ".length ..$]);
						if (iptokens.length>0)
						{
							auto ip=iptokens[0];
							ips~=ip;
						}
						foreach(item;ret.keys)
						{
							//writefln("%s:%s",item,ret[item]);
						}
					}
				}
			}
		}
		numskip=systemDLog.seekNext();
	} while (numskip>0);
	ips=array(ips.sort!"a<b".uniq!"a==b");
	foreach(ip;ips)
		writefln("IP: %s",ip);
	return 0;
}

struct SystemDLog
{
	char[1024*100] buf;
	void *cp;
	int ret;
	sd_journal* journal=null;

	this(int flags)
	{
		enforce((ret=sd_journal_open(&journal,flags))==0), // open all journal file types
			new Exception("Problem opening journal: error "~to!string(ret));
	}

	this(string directory)
	{
		enforce((ret=sd_journal_open_directory(&journal,toZString(directory),0))==0), // open all journal file types
			new Exception("Problem opening journal: error "~to!string(ret));
	}

	this(string[] files)
	{
		char*[] filelist;
		foreach(file;files)
			filelist~=toZString(file);
		filelist~=null;
		enforce((ret=sd_journal_open_files(&journal,cast(char**)&filelist,0))==0), // open all journal file types
			new Exception("Problem opening journal: error "~to!string(ret));
	}

	~this()
	{
		sd_journal_close(journal);
		journal=null;
	}

	void openContainer(string machine, int flags)
	{
		int err;
		if(journal !is null)
			sd_journal_close(journal);
		enforce((err=sd_journal_open_container(&journal,toZString(machine),flags))==0), // open all journal file types
			new Exception("Problem opening journal: error "~to!string(err));
		return;
	}

	void filter(string match)
	{
		int err;
		enforce((err=sd_journal_add_match(journal,toZString(match),match.length)==0),
		 	new Exception("Problem opening journal: error "~to!string(ret)));
	}

	void seekHead()
	{
		int err;
		enforce((err=sd_journal_seek_head(this.journal)==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
	}

	void seekTail()
	{
		int err;
		enforce((err=sd_journal_seek_tail(this.journal)==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
	}

	int seekNext()
	{
		int count;
		enforce(((count=sd_journal_next(this.journal))>=0),
	 		new Exception("Problem opening journal: error "~to!string(count)));
		return count;
	}

	int seekNextSkip(ulong skip)
	{
		int count;
		enforce(((count=sd_journal_next_skip(this.journal,skip))>=0),
	 		new Exception("Problem opening journal: error "~to!string(count)));
		return count;
	}

	int seekPrevious()
	{
		int count;
		enforce(((count=sd_journal_previous(this.journal))>=0),
	 		new Exception("Problem opening journal: error "~to!string(count)));
		return count;
	}

	void seekMonotonic(sd_id128_t bootId, ulong usec)
	{
		int err;
		enforce(((err=sd_journal_seek_monotonic_usec(this.journal,bootId,usec))==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
		return;
	}
	void seekRealtime(ulong usec)
	{
		int err;
		enforce(((err=sd_journal_seek_realtime_usec(this.journal,usec))==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
		return;
	}
	
	string getCursor()
	{
		int err;
		char *cursor;
		enforce(((err=sd_journal_get_cursor(this.journal,&cursor))==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
		auto ret=ZtoString(cursor);
		free(cursor);
		return ret;
	}
	void seekCursor(string cursor)
	{
		int err;
		enforce(((err=sd_journal_seek_cursor(this.journal,toZString(cursor)))==0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
		return;
	}

	bool testCursor(string cursor)
	{
		int err;
		enforce(((err=sd_journal_test_cursor(this.journal,toZString(cursor)))>=0),
	 		new Exception("Problem opening journal: error "~to!string(err)));
		return(err>0);
	}

	int seekPreviousSkip(ulong skip)
	{
		int count;
		enforce(((count=sd_journal_previous_skip(this.journal,skip))>=0),
	 		new Exception("Problem opening journal: error "~to!string(count)));
		return count;
	}


	string getFieldData(string field)
	{
		int err;
		ubyte[100*1024] buf;
		void *cp;
		size_t size=buf.sizeof;
		cp=cast(void*)buf.ptr;
		enforce((err=sd_journal_get_data(journal,toZString(field),cast(void**)&cp,&size))==0),
	 		new Exception("Problem opening journal: error "~to!string(err));
	 	return ZtoString(cast(const char*)((cast(char*)(cp))[0..size]~'\0'));
	 }

	string[string] getRecord()
	{
		string[string] ret;
		ubyte[100*1024] buf;
		void *cp;
		size_t size=buf.sizeof;
		cp=cast(void*)buf.ptr;
	         	size_t l=buf.sizeof;
	         	for (sd_journal_restart_data(journal); (sd_journal_enumerate_data(journal, cast(void**)&cp,&(l)) > 0); )
	         	{
	         		string s=ZtoString(cast(const char*)((cast(char*)(cp))[0..l]~'\0'));
	         		auto sSplit=split(s,"=");
	         		if (s.length>=2)
	         			ret[sSplit[0]]=join(sSplit[1..$],"=");
	         		l=buf.sizeof;
	         		cp=cast(void*)buf.ptr;
	         	}
	         	return ret;
	 }
}