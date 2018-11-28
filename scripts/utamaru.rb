#! /home/koheik/root/bin/ruby
# -*- coding: utf-8 -*-

require 'date'
require 'open-uri'
require 'cgi'

require 'rubygems'
require 'nokogiri'
require 'active_record'

# As of 2011/04/25
# should be 1058 entries
# new index 2 -> 223
# old index 2 -> 153

dbfile = 'utamaru.sqlite'
xmlfile = 'hustler.xml'

if (ENV['HOST'] =~ /sakura\.ne\.jp/)
  dbfile = '/home/koheik/db/utamaru.sqlite'
  xmlfile = '/home/koheik/www/podcast/hustler.xml'
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => dbfile
)

class Entry < ActiveRecord::Base
  has_many :podcasts

  def self.normalize(str)
    s = str.dup
    s.gsub!("\t", '')
    s.gsub!("\n", '')
    s
  end

  def self.parse_and_add(urlstr)

     begin
       doc = Nokogiri::HTML(open(urlstr))
     rescue OpenURI::HTTPError
       puts "Error url=#{urlstr}"
       return false
     end
     doc.xpath("//div[@class='entry']").each do |ent|
       # fetch entry id
       eid = ent.attr('id').gsub('entry-', '').to_i
       ehd = Entry.normalize(ent.xpath("h3[@class='entry-header']").first.to_s)
       ebd = Entry.normalize(ent.xpath(".//div[@class='entry-body']").first.to_s)

       # fetch date
       dtime = ent.xpath("p[@class='entry-footer']/span[@class='post-footers']").first.to_s
       dtime.gsub!("\346\227\245\346\231\202", "日時")
       dtime.gsub!("\345\271\264", "年")
       dtime.gsub!("\346\234\210", "月")
       dtime.gsub!("\346\227\245", "日")

       #   broken entry
       if (eid == 23864)
         edt = DateTime.civil(2009, 6, 1, 0, 0, 0, Rational(9, 24))
         elk = "http://www.tbsradio.jp/utamaru/2009/06/post_456.html"
       else
         if (dtime =~ /\s+日時:\s*(\d+)年\s*(\d+)月\s*(\d+)日 (\d+):(\d+)/)
           edt = DateTime.civil($1.to_i, $2.to_i, $3.to_i, $4.to_i, 
                                $5.to_i, 0, Rational(9, 24))
         else
           puts "Error: url=#{urlstr}, eid=#{eid}, dtime=#{dtime}"
           return false
         end
         # fetch link
         elk = ent.xpath(".//a[@class='permalink']").first.attr('href')
       end

       nuent = Entry.new(:eid => eid, :dtime => edt, 
                         :link => elk, :head => ehd, :body => ebd);
       nu = true;
       Entry.find_all_by_eid(eid).each do |old|
         nu &= !nuent.wequal(old)
       end
       nuent.save if nu
     end
     true
   end

   def self.update_db
     if (true)
       urlstr = "http://www.tbsradio.jp/utamaru/podcast/index_pod.html"
       parse_and_add(urlstr)
     end
     if (true)
       urlstr = "http://www.tbsradio.jp/utamaru/podcast/index.html"
       parse_and_add(urlstr)
     end


#     (2..153).each do |i|
#       urlstr = "http://www.tbsradio.jp/utamaru/podcast/index#{i}.html"
#       break unless parse_and_add(urlstr)
#     end
   end

   def self.update_index(fname)
     File.open(fname, "w+") { |f|
       Entry.print_podcast_header(f)
       Entry.find_hustler.each do |ent|
         ent.print_podcast_item(f)
       end
       Entry.print_podcast_footer(f)
     }
   end

   def self.find_hustler()
     keywords = [
                 "hustler",
                 "シネマハスラー",
                 "映画", # eiga
                 "町山",  # machiyama
                 "高橋ヨシキ", #takahashi yoshiki
                 "シネマ・ランキング", # cinema ranking
                 "ソフト化希望", # 
                 "シンプソンズ", #simpsons
                 "ヤッターマン", #yattaman
                 "20071229", #tamademy
                 "20080308podcast", #machiyama 1
                 "20080419_podcast", #hosoda
                 "20080419_hosoda", #hosoda
                 "20080524_rambo", #rambo
                 "ENDMARK"
                ]
     ary = []
     find(:all, :order => "eid asc").each do |entry|
       idx = -1
       (0...keywords.length).each do |i|
         if (entry.body.to_s.include?(keywords[i])) 
           idx = i
           break
         elsif (entry.head.to_s.include?(keywords[i]))
           idx = i
           break
         end
       end
       ary << entry if idx >= 0
     end
     ary
   end # self.find_hustler

   def wequal rhs
     r = (eid == rhs.eid)
     r &= (dtime.strftime("%Y-%m-%d %X") == rhs.dtime.strftime("%Y-%m-%d %X"))
     r &= (link == rhs.link)
     r &= (head == rhs.head)
     r &= (body == rhs.body)
     r
   end

   def file_name
     fname = ""
     Nokogiri::HTML.parse(body).xpath("//a").each do |at|
       link = at.attr("href").gsub("%20", "")
       if (link =~ /\.mp3$/)
         fname = link
         break
       end
     end
     fname
   end

   def title
     title = ''
     hd = Nokogiri::HTML.parse(head).xpath("//h3[@class='entry-header']/a").text

     open_fmt = "オープニング・トーク「%s」"
     hust_fmt = "ザ・シネマハスラー「%s」"

     eiddic = {
       "2910"  => "宇田丸の映画トーク「キサラギ」＆「ホステル」",
       "4212"  => sprintf(open_fmt, "シンプソンズ問題で再炎上！！！」"),
       "4296"  => sprintf(open_fmt, "椿三十郎"),
       "4531"  => sprintf(open_fmt, "劇場版シンプソンズ"),
       "4765"  => sprintf(open_fmt, "ヤッターマン"),
       "20234" => sprintf(hust_fmt, "私は貝になりたい"),
       "27387" => sprintf(hust_fmt, "ATOM＆カイジ 人生逆転ゲーム"),
       "27242" => sprintf(hust_fmt, "狼の死刑宣告＆さまよう刃")
     }

     eiddic.each do |k,v|
       if (eid == k.to_i)
         title = v
         break
       end
     end

     if (title == "")
       if (hd =~ /(ザ・シネマハスラー|ザ・シネマ・ハスラー)「(.+)」」/)
         title = sprintf(hust_fmt, $2)
       elsif (hd =~ /(ザ・シネマハスラー|ザ・シネマ・ハスラー|町山智浩のザ・邦画・ハスラー！)「(.+)」/)
         title = sprintf(hust_fmt, $2)
       elsif (hd =~ /ザ・シネマ・ハスラー/)
         bdy = body.to_s
         if (bdy =~ /第一回目は『(.+)』！/)
           title = sprintf(hust_fmt, $1)
         elsif (body.to_s =~ /今夜は『(.+)』を(|ようやく)評論！/)
           title = sprintf(hust_fmt, $1)
         elsif (bdy =~ /今週評論する映画は『(.+)』！/)
           title = sprintf(hust_fmt, $1)
         elsif (bdy =~ /サイの目映画は・・・<span[^>]*>『(.+)』/)
           title = sprintf(hust_fmt, $1)
         elsif (bdy =~ /サイの目映画は(|・・・)『(.+)』！/)
           title = sprintf(hust_fmt, $2)
         elsif (bdy =~ /二本目のサイの目映画は・・・『(.+)』/)
           title = sprintf(hust_fmt, $1)
         elsif (bdy =~/大林宣彦監督『(.+)』/)
           title = sprintf(hust_fmt, $1)
         elsif (bdy =~/まずは『(.+)』/)
           title = sprintf(hust_fmt, $1)
         else
           title = bdy
          end
       end
     end
     if (title == "")
         title = hd
     end
     title
   end

   def title_clean
     CGI::escapeHTML(title)
   end

  def title_itunes
    hd = Nokogiri::HTML.parse(head).xpath("//h3[@class='entry-header']/a").text
    hd.gsub!("“", "_")
    hd.gsub!("”", "_")
    hd.gsub!("/", "_")
    hd.gsub!("\"", "_")

    base = [hd, title_clean]
    pfix = [dtime.strftime("%Y_%m_%d")]
    if (file_name =~ /files\/(\d{4})(\d{2})(\d{2})/)
      pfix << [$1, $2, $3].join("_")
    end

    if (eid ==  20234)
      base << "ザ・TBSシネマハスラー「私は貝になりたい」"
      pfix << "2008_12_13"
    elsif (eid == 4773 || eid == 4774);  pfix << "2008_01_19"
    elsif (eid ==  5356); pfix << "2008_02_23"
    elsif (eid ==  5658); pfix << "2008_03_15"
    elsif (eid ==  9444)
      base << "ザ・シネマ・ハスラー「おろち」"
    elsif (eid ==  9741)
      base << "ちょこっとラボ「LISTEN AND VOTE」キャンペーン続報"
      pfix << "2008_10_11"
    elsif (eid ==  16749)
      base << "ちょこっとラボ「LISTEN AND VOTE」キャンペーン続報"
      pfix << "2008_10_18"
    elsif (eid == 20876)
      base << "サタデーナイトラボ「雑誌・トゥ・ザ・フィーチャー！俺たち未来人！！」」"
      pfix << "2009_01_17"
    elsif (eid == 24592)
      base << "緊急追悼特集：西寺郷太のマイケル・ジャクソン語り＜第一部＞"
    elsif (eid == 24595)
      base << "サタデーナイトラボ" +
        "「緊急追悼特集：決定版！西寺郷太のマイケル・ジャクソン語り」【前編】"
    elsif (eid ==  24596)
      base <<  "サタデーナイトラボ" +
        "「緊急追悼特集：決定版！西寺郷太のマイケル・ジャクソン語り」【後編】"
    elsif (eid == 24598)
      base << "配信限定！放課後DA★話（7_4）【前編】"
    elsif (eid == 24599)
      base << "配信限定！放課後DA★話（7_4）【中編】"
    elsif (eid == 24600)
      base << "配信限定！放課後DA★話（7_4）【後編】"
    elsif (eid == 26233); pfix << "2009_08_29"
    elsif (eid == 29467); pfix << "2010_02_01"
    elsif (eid == 29530); pfix << "2010_02_01"
    elsif (eid == 29364); pfix << "2010_02_01"
    elsif (eid == 29694); pfix << "2010_02_01"
    elsif (eid == 29866); pfix << "2010_02_09"
    elsif (eid == 30351)
      base << "サタデーナイトラボ「【へドラ】特集！」"
    elsif (eid == 30513); pfix << "2010_03_09"
    elsif (eid == 30682); pfix << "2010_03_16"
    elsif (eid == 30854); pfix << "2010_03_27"
    elsif (eid == 31353); pfix << "2010_04_13"
    elsif (eid == 31899); pfix << "2010_05_05"
    elsif (eid == 32073); pfix << "2010_05_13"
    elsif (eid == 32243); pfix << "2010_05_18"
    elsif (eid == 32614); pfix << "2010_06_02"
    elsif (eid == 32783); pfix << "2010_06_10"
    elsif (eid == 33148); pfix << "2010_06_25"
    elsif (eid == 34182); pfix << "2010_08_06"
    elsif (eid == 34693); pfix << "2010_08_25"
    elsif (eid == 39872); pfix << "2011_02_24"
    elsif (eid == 40070); pfix << "2011_03_03"
    elsif (eid == 40279); pfix << "2011_03_10"
    elsif (eid == 41394); pfix << "2011_04_21"
    end

    if (title_clean =~ /ザ・シネマハスラー(.+)/)
      base << "ザ・シネマ・ハスラー"
      base << "ザ・シネマ・ハスラー" + $1
    end

    titles = []
    pfix.each do |a|
      base.each do |b|
        [".mp3", " 1.mp3"].each do |c|
          titles << a + " " + b + c
        end
      end
    end
    titles << File.basename(file_name) if (file_name != "")
    titles
  end

  def body_clean
    bdy = Nokogiri::HTML.parse(body).xpath("//div[@class='entry-body']").text
    CGI::escapeHTML(bdy)
  end

  PODCAST_KEYWORDS = [
                      "ライムスター宇多丸",
                      "ライムスター宇多丸のウィークエンド・シャッフル",
                      "ラジオ",
                      "Podcast"
                     ]

  def self.print_podcast_header(f)
    last_build = DateTime.now.strftime("%a, %d %b %Y %X %z")
    f.print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    f.print "<rss\n"
    f.print "  xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n"
    f.print "  xmlns:content=\"\http://purl.org/rss/1.0/modules/content/\"\n"
    f.print "  xmlns:itunes=\"http://www.itunes.com/DTDs/Podcast-1.0.dtd\"\n"
    f.print "  version=\"2.0\">\n"
    f.print "<channel>\n"
    f.print "<ttl>60</ttl>\n"
#    f.print "<title>ライムスター宇多丸のウィークエンド・シャッフル</title>\n"
    f.print "<title>ライムスター宇多丸のザ・シネマハスラー</title>\n"
    f.print "<link>http://www.tbsradio.jp/utamaru/</link>\n"
    f.print "<description>TBSラジオで毎週土曜日21:30～「ライムスター宇多丸のウィークエンド・シャッフル」放送中！キラキラ＆グルーヴィな音楽とハジケるボンクラトーク。新感覚“土曜の夜”系エンターテインメント・プログラム！！</description>\n"
    f.print "<language>ja</language>\n"
    f.print "<lastBuildDate>#{last_build}</lastBuildDate>\n"
    f.print "<copyright>Tokyo Broadcasting System, Inc. All Rights Reserved.</copyright>\n"
    f.print "<category>Music</category>\n"
    f.print "<itunes:category text=\"Music\"></itunes:category>\n"
    f.print "<itunes:subtitle>毎週土曜日 21時30分～23:30</itunes:subtitle>\n"
    f.print "<image>\n"
    f.print "  <url>http://www.tbsradio.jp/utamaru/300_300.jpg</url>\n"
    f.print "  <link>http://www.tbsradio.jp/utamaru/</link>\n"
    f.print "  <title>ライムスター宇多丸のウィークエンド・シャッフル</title>\n"
    f.print "</image>\n"
    f.print "<itunes:author>TBS RADIO 954kHz</itunes:author>\n"
    f.print "<itunes:summary>TBSラジオで毎週土曜日21:30～「ライムスター宇多丸のウィークエンド・シャッフル」放送中！キラキラ＆グルーヴィな音楽とハジケるボンクラトーク。新感覚“土曜の夜”系エンターテインメント・プログラム！！</itunes:summary>\n"
    f.print "<generator>http://www.sixapart.com/movabletype/</generator>\n"
    f.print "<itunes:owner>\n"
    f.print "  <itunes:name>TBS RADIO 954kHz</itunes:name>\n"
    f.print "  <itunes:email>utamaru@tbs.co.jp</itunes:email>\n"
    f.print "</itunes:owner>\n"
    f.print "<itunes:image href=\"http://www.tbsradio.jp/utamaru/300_300.jpg\" />\n"
  end

  def self.print_podcast_footer(f)
    f.print "</channel>\n"
    f.print "</rss>\n"
  end

  def print_podcast_item(f)
    itm_date = dtime.strftime("%a, %d %b %Y %X %z")
    itm_titl = dtime.strftime("%Y/%m/%d") + " " + title_clean
    f.print "<item>\n"
    f.print "  <title>#{itm_titl}</title>\n"
    f.print "  <link>#{link}</link>\n"
    f.print "  <description></description>\n"
    f.print "  <itunes:author>TBS RADIO 954kHz</itunes:author>\n"
    f.print "  <guid>#{file_name}</guid>\n"
    f.print "  <dc:creator>TBS RADIO 954kHz</dc:creator>\n"
    f.print "  <pubDate>#{itm_date}</pubDate>\n"
    f.print "  <category>Music</category>\n"
    f.print "  <itunes:category text=\"Music\"></itunes:category>\n"
    f.print "  <itunes:summary>" + body_clean + "</itunes:summary>\n"
    f.print "  <itunes:keywords>" + PODCAST_KEYWORDS.join(", ") + "</itunes:keywords>\n"
    f.print "  <itunes:explicit>no</itunes:explicit>\n"
    f.print "  <enclosure url=\"#{file_name}\" type=\"audio/mpeg\" />\n"
    f.print "</item>\n" 
  end
end

class Podcast < ActiveRecord::Base
  belongs_to :entry
end

## main
if __FILE__ == $0
  Entry.update_db
  Entry.update_index(xmlfile)
end

# end of file

