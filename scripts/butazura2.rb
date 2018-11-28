#! /usr/local/bin/ruby

require 'date'
require 'net/http'
require 'uri'

debug=false

dnames = ["butazura", "files"]
bdir = "/home/koheik/www/podcast"
fout  = "butazura.xml"
urlbase = "http://koheik.sakura.ne.jp/podcast/"
if (debug)
  bdir = "/Users/Shared/Audio/junk"
  dnames = ["butazura"]
  fout ="butazura.xml"
end
Dir.chdir(bdir)

hustler = true
f = File.open(fout, "w+")
f.print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
f.print "<rss \n"
f.print "  xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n"
f.print "  xmlns:content=\"http://purl.org/rss/1.0/modules/content/\"\n"
f.print "  xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\"\n"
f.print "  version=\"2.0\">\n"
f.print "<channel>\n"
f.print "<title>JUNK 伊集院光 深夜の馬鹿力</title>\n"
f.print <<"EOF1"
  <link>http://www.tbsradio.jp/ijuin/</link>
  <description>毎週月曜日 深夜1時～放送中！</description>
  <language>ja</language>
EOF1
f.print "<lastBuildDate>" + Time.now.strftime("%a, %d %B %Y %X %z") + "</lastBuildDate>\n"
f.print <<"EOF2"
  <copyright>Tokyo Broadcasting System, Inc. All Rights Reserved.</copyright>
  <category>Music</category>
  <itunes:category text="Music"></itunes:category>
  <itunes:subtitle>毎週月曜日 深夜1時～放送中！</itunes:subtitle>
  <image>
    <url>http://www.tbsradio.jp/ijuin/300_300.jpg</url>
    <link>http://www.tbsradio.jp/ijuin/</link>
    <title>JUNK 伊集院光 深夜の馬鹿力</title>
  </image>
  <itunes:author>TBS RADIO 954kHz</itunes:author>
  <itunes:summary></itunes:summary>
  <generator>http://www.sixapart.com/movabletype/</generator>
  <itunes:owner>
    <itunes:name>TBS RADIO 954kHz</itunes:name>
    <itunes:email></itunes:email>
  </itunes:owner>
  <itunes:image href="http://www.tbsradio.jp/ijuin/300_300.jpg" />
EOF2

list = []
dnames.each do |dname|
  Dir.glob("#{dname}/*.mp3").each do |fn|
    if (fn =~ /ButaZura_(\d+)_(\d+)_(\d+).mp3/)
      y = $1.to_i
      m = $2.to_i
      d = $3.to_i
      t = 100*(100*y + m) + d
      dt = DateTime.parse([y, m, d].join("-") + "T00:00:05")
      dtstr = dt.strftime("%a, %d %B %Y %X +0900")
      dstr  = dt.strftime("%Y/%m/%d")
      title = "深夜の馬鹿力"
      list << {:file => fn, :dtstr => dtstr, :dstr => dstr, :title => title, :order => t}
    end
  end
end

list.sort{|a,b| b[:order] <=> a[:order]}.each do |itm|
  dstr  = itm[:dstr]
  dtstr = itm[:dtstr]
  title = itm[:title]
  file  = itm[:file]
  urlstr = urlbase + file

  f.print "  <item>\n"
  f.print "    <title>#{dstr} #{title}</title>\n"
  f.print "    <link>#{urlstr}</link>\n"
  f.print "    <description></description>\n"
  f.print "    <guid>#{file}</guid>\n"
  f.print "    <enclosure url=\"#{urlstr}\" type=\"audio/mpeg\" />\n"
  f.print "    <category>Music</category>\n"
  f.print "    <pubDate>#{dtstr}</pubDate>\n"

  f.print "    <dc:creator>TBS RADIO 954kHz</dc:creator>\n"

  f.print "    <itunes:author>TBS RADIO 954kHz</itunes:author>\n"
  f.print "    <itunes:category text=\"Music\" />\n"
  f.print "    <itunes:explicit>no</itunes:explicit>\n"
      
  f.print "  </item>\n"
end
f.print "</channel>\n"
f.print "</rss>\n"

