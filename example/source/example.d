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
	//systemDLog.addMatch("_COMM=sshd");
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

