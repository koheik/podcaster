require 'open-uri'

head =<<"EOS"
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
	<channel>
		<title>Sail Racing Magazine Podcast</title>
		<link>http://www.sailracingmagazine.com/</link>
		<description>Podcast versions of Sail Racing Magazine's interviews with the world's best professional racing sailors. Also check out our free monthly iPad magazine at sailracingmagazine.com or in the Apple App Store.</description>
		<language>en</language>
		<lastBuildDate>Sun, 08 February 2015 06:29:00 +0900</lastBuildDate>
		<copyright>
		Sail Racing Magazine
		</copyright>
		<category>Podcast</category>
		<itunes:category text="Podcast"/>
		<itunes:subtitle>Sail Racing Magazine Podcast</itunes:subtitle>
		<image>
		<url>http://static1.squarespace.com/static/518aa3eee4b04323d507b898/t/5478bcabe4b097668b21a585/1417203508026/SRM+LOGO+June+2013+black+and+red.png?format=1500w</url>
		<link>http://www.sailracingmagazine.com/</link>
		<title>Sail Racing Magazine Podcast</title>
		</image>
		<itunes:author>Sail Racing Magazine</itunes:author>
		<itunes:summary/>
		<generator>http://www.sixapart.com/movabletype/</generator>
		<itunes:owner>
		<itunes:name>TSail Racing Magazine Podcast</itunes:name>
		<itunes:email/>
		</itunes:owner>
		<itunes:image href="http://static1.squarespace.com/static/518aa3eee4b04323d507b898/t/5478bcabe4b097668b21a585/1417203508026/SRM+LOGO+June+2013+black+and+red.png?format=1500w"/>
EOS

foot =<<"EOS"
	</channel>
</rss>
EOS

print head
Dir.glob("files/*.mp3").each do |fn|
	name = File.basename(fn, ".mp3");
	fname = File.basename(fn);
	link = URI::encode("http://koheik.sakura.ne.jp/podcast/files/#{fname}")
	print "\t\t<item>\n";
	print "\t\t\t<title>#{name}</title>\n"
	print "\t\t\t<link>#{link}</link>\n"
	print "\t\t\t<description></description>\n"
	print "\t\t\t<guid>#{fname}</guid>\n"
	print "\t\t\t<enclosure url=\"#{link}\" type=\"audio/mpeg\" />\n"
	print "\t\t\t<category>Podcast</category>\n"
	print "\t\t\t<pubDate>Tue, 03 February 2015 00:00:05 +0900</pubDate>\n"
	print "\t\t\t<dc:creator>Sail Racing Magazine</dc:creator>\n"
	print "\t\t\t<itunes:author>Sail Racing Magazine</itunes:author>\n"
	print "\t\t\t<itunes:category text=\"Podcast\" />\n"
	print "\t\t\t<itunes:explicit>no</itunes:explicit>\n"
	print "\t\t</item>\n";
end
print foot
