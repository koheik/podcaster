#!/usr/bin/ruby

require 'date'
require 'uri'
require 'net/http'

require 'rubygems'
require 'hpricot'
require 'active_record'

debug = false
overwrite = true
startpage = 1
dbfile = (debug)? "KenMovieReview.db" : "/home/koheik/www/KenMovieReview/KenMovieReview.db"

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => dbfile)

class Review < ActiveRecord::Base; end

class Rv
	def initialize(*arg)
	  ary = arg[0]
	  @title = ary[:title]
	  @date  = ary[:date]
	  @rid   = ary[:rid]
	  @url   = ary[:url]
	  @short = ary[:short]
	  @score = ary[:score]
	end
	attr_accessor :title, :date, :rid, :url, :short, :score
end

# load top page and get the total number of summary pages
urlstr = "http://www.cinemaonline.jp/category/review/ken"
url = URI.parse(urlstr)
res = Net::HTTP.get(url)
doc = Hpricot(res)
num = doc.at('span[@class="pages"]').inner_text.gsub("1/", "").to_i

reviews = []
# walk through all summary pages
(startpage..num).each do |i|
  urlstr = "http://www.cinemaonline.jp/category/review/ken/page/#{i}"
  url = URI.parse(urlstr)
  res = Net::HTTP.get(url)
  doc = Hpricot(res)

  title = ""
  rvid = 0
  rvdate = Date.today
  
# search child elements
  doc.search('//div[@id="content"]/').each do |par|
    next if par.class == Hpricot::Text
    cls = par.attributes['class']

    if (cls == "date" )
      par.inner_text =~ /(\d+)\345\271\264(\d+)\346\234\210(\d+)\346\227\245/
      rvdate = Date.parse([$1, $2, $3].join("-"))
      next
    elsif (cls == "review-title")
      urlstr = par.at('//a').attributes['href']
      urlstr =~ /\/(\d+)\.html/
      rvid = $1.to_i
      title = par.at('//a').inner_text
      next
    elsif (cls == "score")
      score_text = par.inner_text
	  if ( score_text =~ /(.+)\s*(\357\274\210|\()(\d+)\347\202\271/ ) then
        short = $1
        score = $3.to_i
      end
    else
      next
    end

	wdash = "\357\274\215"
	wtild = "\357\275\236"
    if (rvid ==  1322) then; title.gsub!("?", wdash); end # ベクシル
    if (rvid ==  1354) then; title.gsub!("?", wtild); end # 未来予想図
    if (rvid ==  1390) then; title.gsub!("?", wtild); end # ウェイトレス
    if (rvid ==  2957) then; title.gsub!("?", wtild); end # Mr.ブルックス
    if (rvid ==  3040) then; title.gsub!("?", wdash); end # 1000の言葉よりも
    if (rvid ==  3495) then; title.gsub!("?", wtild); end # 敵こそ、我が友
    if (rvid ==  4887) then; title.gsub!("?", wtild); end # ラット・フィンク
    if (rvid ==  5929) then; title.gsub!("?", wtild); end # 我が至上の愛
    if (rvid ==  7273) then; title.gsub!("?", wtild); end # ワイライト
    if (rvid ==  7523) then; title.gsub!("?", wtild); end # デュプリシティ
    if (rvid ==  8042) then; title.gsub!("?", wdash); end # サガン
    if (rvid ==  9264) then; title.gsub!("?", wtild); end # キャデラック・レコード
    if (rvid ==  9965) then; title.gsub!("?", wtild); end # テイルズ オブ ヴェスペリア
    if (rvid ==  9966) then; title.gsub!("?", wtild); end # キッチン
    if (rvid == 10053) then; title.gsub!("?", wtild); end # ヴィヨンの妻
  
    reviews << Rv.new(:title => title, :date => rvdate, :rid => rvid,
                      :url => urlstr, :short => short, :score => score)

    if (debug)
      print "-------\n"
      print "  Title: #{title}[#{rvid}]\n"
	  print "  Score: #{score}\n"
      print "  Date : " + rvdate.strftime("%Y-%m-%d") + "\n"
      print "  URL  : #{urlstr}\n"
    end
  end
end

reviews.sort {|a, b| a.rid <=> b.rid }.each do |rv|

  rc = Review.find(:first, :conditions => ["title = ?", rv.title])

  if (rc.nil?) then
    rc = Review.new
  else
    if (overwrite)
	else
	  next if (rv.date == rc.date)
	end
  end

  res = Net::HTTP.get( URI.parse(rv.url) )
  doc = Hpricot(res)

# check title and short review
  title2 = doc.at('h2[@class="top-title"]').inner_text
  score_text2 = doc.at('//div[@class="entry"]/p[@class="score"]')
  if ( score_text2 =~ /(.+)\s*(\357\274\210|\()(\d+)\347\202\271/ ) then
    short2 = $1
    score2 = $2.to_i
  end

  if (rv.title != title2) then
    "Error:\n  1. #{rv.title}\n  2. #{title2}\n"
  end
  if (rv.score != score2) then
    "Error:\n  1. #{rv.score}\n  2. #{score2}\n"
  end
  if (rv.short != short2) then
    "Error:\n  1. #{rv.short}\n  2. #{short2}\n"
  end

  long = []
  doc.search('//div[@class="entry"]/p[@class=""]').each do |el|
    long << el.inner_text
  end

  rc.review_id    = rv.rid
  rc.review_date  = rv.date
  rc.title        = rv.title
  rc.url          = rv.url
  rc.score        = rv.score
  rc.short_review = rv.short
  rc.long_review  = long.join("\n")
  rc.save
end

