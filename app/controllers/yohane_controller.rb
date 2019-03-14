require 'line/bot'
require 'net/http'
require 'uri'
require 'tradsim'
class YohaneController < ApplicationController
	protect_from_forgery with: :null_session

def webhook
	params['events'].each do |event|
	#取得訊息
	received_text = get_received_text(event)
	#取得reply token
	reply_token = event['replyToken']
	#取得頻道ID
	channel_id = get_channel_id(event)
	#紀錄頻道id
	save_to_channel_id(channel_id)
	#加入群組
	reply_text = join(event)
	reply_text = upload_to_imgur(event) if reply_text.nil?
	#測試後門
	backdoor(received_text, channel_id, event)
	#學說話
	reply_text = learn(channel_id, received_text, event) if reply_text.nil?
	#學說話(include
	reply_text = learn_include(channel_id, received_text, event) if reply_text.nil?
	#學說話(貼圖
	reply_text = learn_sticker(channel_id, received_text, event) if reply_text.nil?
	#忘記說話
	reply_text = forgot(channel_id, received_text) if reply_text.nil?
	#忘記說話(include
	reply_text = frogot_include(channel_id, received_text) if reply_text.nil?
	#忘記說話（貼圖
	reply_text = forgot_sticker(channel_id, received_text) if reply_text.nil?
	#關鍵字回復
	reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?
	#關鍵字回復(貼圖
	reply_text = keyword_reply_sticker(channel_id, event) if reply_text.nil?
	#關鍵字開關
	reply_text = switch(channel_id, received_text) if reply_text.nil?
	#nhentai
	reply_text = nhentai(received_text) if reply_text.nil?
	#抽
	reply_text = draw(received_text) if reply_text.nil?
	#查指令
	reply_text = command(received_text) if reply_text.nil?
	#查關鍵字
	reply_text = keywords(channel_id, received_text) if reply_text.nil?
	#查關鍵字(include
	reply_text = keywords_include(channel_id, received_text) if reply_text.nil?
	#查關鍵字(貼圖
	reply_text = keyword_include_sticker(channel_id, received_text) if reply_text.nil?
	#關鍵字回復(include
	reply_text = keyword_reply_include(channel_id, received_text) if reply_text.nil?
	#XXX是什麼
	reply_text = wiki(received_text) if reply_text.nil?
	#查貼圖
	reply_text = find_sticker(event) if reply_text.nil?
	#樓下保持隊形
	reply_text = follow(channel_id, received_text) if reply_text.nil?
	#半次元
	reply_text = bcy(received_text) if reply_text.nil?
	#記錄對話
	save_to_received(channel_id, received_text)
	save_to_reply(channel_id, reply_text)
	#傳送圖片到line
	reply_image_to_line(reply_token)
	#傳送訊息到line
	reply_to_line(reply_text, reply_token)

 end
	#回應200
	head :ok
end
def backdoor(received_text, channel_id, event)
	return nil unless channel_id == 'U693cf83bb807d39abb88e724d8afa002'
	return nil if received_text.nil?
	return nil unless received_text[0..6] == '學說話*隨機='

	content = received_text[7..-1]
  seperater_index = content.index('=
')

	keyword = content[0..seperater_index-1]
	list = content[seperater_index+3..-1].split('
').to_a
	p '============================'
	p keyword
	p '=============================='
	p list
	p '=============================='
	nil
end

def 指令列表
"指令列表；

新增關鍵字：
學說話=<關鍵字>=<回應>

新增「包含」關鍵字：
學說話*=<關鍵字>=<回應>

刪除關鍵字：
忘記=<關鍵字>

刪除「包含」關鍵字：
忘記*=<關鍵字>

開啟或關閉「使用其他聊天室設定的關鍵字」功能：
全域關鍵字=<開/關>

抽獎：
抽*<數量>

查詢關鍵字：
關鍵字列表

查詢「包含」關鍵字：
關鍵字列表*

查詢指令：
指令

功能；
用私訊傳圖片給機器人，機器人會回傳圖片連結"
end
	#加入群組
def join(event)
	if event['type'] == 'join'
	return "感謝將本機加入群組～\n以下是指令\n\n" + 指令列表
	end
end
	#頻道ID
def get_channel_id(event)
	source = event['source']
	source['groupId']  ||source['roomId'] ||source['userId']
end
	#儲存對話
def save_to_received(channel_id, received_text)
	return if received_text.nil?
	Received.create(channel_id: channel_id, text: received_text)
	Received.order(:created_at).first.destroy
end
	#儲存回覆
def save_to_reply(channel_id, reply_text)
	return if reply_text.nil?
	Reply.create(channel_id: channel_id, text: reply_text)
	Reply.order(:created_at).first.destroy
end
	#儲存頻道id
def save_to_channel_id(channel_id)
	KeywordSwitch.find_or_create_by(channel_id: channel_id)
end
	#取得收到的訊息
def get_received_text(event)
	message = event['message']
	message['text'] unless message.nil?
end
	#學說話
def learn(channel_id, received_text, event)
	return nil if received_text.nil?
	return nil unless received_text[0..3] == '學說話='

	received_text = received_text[4..-1]
	semicolon_index = received_text.index('=')

	return nil if semicolon_index.nil?

	keyword = received_text[0..semicolon_index-1]
	message = received_text[semicolon_index+1..-1]

	user_id = event['source']['userId']
	response = line.get_profile(user_id)
	user = JSON.parse(response.body)['displayName']

	KeywordMapping.where(channel_id: channel_id, keyword: keyword).destroy_all unless KeywordMapping.where(channel_id: channel_id, keyword: keyword).nil
	KeywordMapping.create(channel_id: channel_id, keyword: keyword, message: message, user_id: user)

	'ok 記住囉！'
end

	#學說話(include
def learn_include(channel_id, received_text, event)
	return nil if received_text.nil?
	received_content = received_text[5..-1]
	return nil unless received_text[0..4] == '學說話*='
	semicolon_index = received_content.index('=')
	return nil if semicolon_index.nil?

	keyword = received_content[0..semicolon_index-1]
	message = received_content[semicolon_index+1..-1]
	message = "https://i.imgur.com/"+message[-7..-1]+".jpg" if message[0..16] == "http://imgur.com/"

	user_id = event['source']['userId']
	response = line.get_profile(user_id)
	user = JSON.parse(response.body)['displayName']

	KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).destroy_all unless KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).nil?
	KeywordMappingInclude.create(channel_id: channel_id, keyword: keyword, message: message, user_id: user)
	'ok 記住囉！'
end
	#學說話（貼圖
def learn_sticker(channel_id, received_text, event)
	return nil if received_text.nil?
	return nil unless received_text[0..6] =='學說話*貼圖='
	content = received_text[7..-1]
	semicolon_index = content.index('=')

	keyword = content[0..semicolon_index-1]
	message = content[semicolon_index+1..-1]

	user_id = event['source']['userId']
	response = line.get_profile(user_id)
	user = JSON.parse(response.body)['displayName']
	KeywordMappingSticker.where(channel_id: channel_id, keyword: keyword).destroy_all unless KeywordMappingSticker.where(channel_id: channel_id, keyword: keyword).nil?
	KeywordMappingSticker.create(channel_id: channel_id, keyword: keyword, message: message, user: user)

	"嗯嗯"
end
	#學說話（隨機
def learn_random(channel_id, received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..6] == '學說話*隨機='

	content = received_text[7..-1]
  seperater_index = content.index('=\n')

	keyword = content[0..seperater_index-1]
	list = content[seperater_index+3..-1].split('\n').to_a

end
	#忘記說話(include
def frogot_include(channel_id, received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..3] == '忘記*='
	keyword = received_text[4..-1]
	if KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).to_a == []
	'查無關鍵字'
	else
	KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).destroy_all
	"忘記啦！"
	end
end
	#忘記說話
def forgot(channel_id, received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..2] == "忘記="
	keyword = received_text[3..-1]
	if KeywordMapping.where(channel_id: channel_id, keyword: keyword).to_a == []
	'查無關鍵字'
	else
	KeywordMapping.where(channel_id: channel_id, keyword: keyword).destroy_all
	"忘記啦！"
	end
end
	#忘記說話（貼圖
def forgot_sticker(channel_id, received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..5] == '忘記*貼圖='
	keyword = received_text[6..-1]
	if KeywordMappingSticker.where(channel_id: channel_id, keyword: keyword).to_a == []
		'查無關鍵字'
	else
		KeywordMappingSticker.where(channel_id: channel_id, keyword: keyword).destroy_all
		"忘記啦！"
	end
end
	#關鍵字回復
def keyword_reply(channel_id, received_text)
	reply = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last&.message

	if reply.nil? && KeywordSwitch.where(channel_id: channel_id).last&.switch == 'on'
		reply = KeywordMapping.where(keyword: received_text).last&.message
	end
	return nil if reply.nil?
	if reply[0..19] == "https://i.imgur.com/"
	@previewImageUrl = reply
	@originalContentUrl = reply
	reply = nil
	end
	reply
end
	#關鍵字回復(貼圖
def keyword_reply_sticker(channel_id, event)
	return nil unless event['message']['type'] == 'sticker'
	packageId = event['message']['packageId']
	stickerId = event['message']['stickerId']
	key = 'packageId：' + packageId + "\n" + 'stickerId：' + stickerId
	reply = KeywordMappingSticker.where(channel_id: channel_id, keyword: key).last&.message
	return nil if reply.nil?
	if reply[0..19] == "https://i.imgur.com/"
	@previewImageUrl = reply
	@originalContentUrl = reply
	reply = nil
	end
	reply
end
	#關鍵字回復(include
def keyword_reply_include(channel_id, received_text)
	return nil if received_text.nil?
	reply = nil
	KeywordMappingInclude.where(channel_id: channel_id).pluck(:keyword).each do |keyword|
	reply = KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).last&.message if received_text.include?(keyword)
	end
	return nil if reply.nil?
	if reply[0..19] == "https://i.imgur.com/"
	@previewImageUrl = reply
	@originalContentUrl = reply
	reply = nil
	end
	reply
end
	#關鍵字開關
def switch(channel_id, received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..5] == '全域關鍵字='
	if received_text == '全域關鍵字=開'
		KeywordSwitch.where(channel_id: channel_id).update(channel_id: channel_id, switch: 'on')
	end
	if received_text == '全域關鍵字=關'
		KeywordSwitch.where(channel_id: channel_id).update(channel_id: channel_id, switch: 'off')
	end
	'ok'
end
	#查指令
def command(received_text)
	if received_text == "指令" || received_text == "指令列表"
	return 指令列表
	else return nil
	end
end
	#查關鍵字
def keywords(channel_id, received_text)
	return nil if received_text.nil?
	if received_text == '關鍵字列表'

		keyword = KeywordMapping.where(channel_id: channel_id).pluck(:keyword).to_a
		message = KeywordMapping.where(channel_id: channel_id).pluck(:message).to_a
		editor = KeywordMapping.where(channel_id: channel_id).pluck(:user_id).to_a
		return "沒有關鍵字喔" if keyword == [] || message == []

		reply_arr = Array.new
		number = keyword.size.to_i
		0.upto(number-1) do |i|
		reply_arr << keyword[i].to_s + "：\n" + message[i].to_s + "\nBy：" + editor[i]
		end
		reply_arr.join("\n\n")
	end

end
	#查關鍵字(include)
def keywords_include(channel_id, received_text)
	return nil if received_text.nil?
	if received_text == '關鍵字列表*'

		keyword = KeywordMappingInclude.where(channel_id: channel_id).pluck(:keyword).to_a
		message = KeywordMappingInclude.where(channel_id: channel_id).pluck(:message).to_a
		editor = KeywordMappingInclude.where(channel_id: channel_id).pluck(:user_id).to_a
		return "沒有關鍵字喔" if keyword == [] || message == []

		reply_arr = Array.new
		number = keyword.size.to_i
		0.upto(number-1) do |i|
		reply_arr << keyword[i].to_s + "：\n" + message[i].to_s + "\nBy：" + editor[i]
		end
		reply_arr.join("\n\n")
	end
end
	#查關鍵字(貼圖
def keyword_include_sticker(channel_id, received_text)
	return nil if received_text.nil?
	if received_text == '關鍵字列表*貼圖'
		keyword = KeywordMappingSticker.where(channel_id: channel_id).pluck(:keyword).to_a
		message = KeywordMappingSticker.where(channel_id: channel_id).pluck(:message).to_a
		editor = KeywordMappingSticker.where(channel_id: channel_id).pluck(:user).to_a
		return "沒有關鍵字喔" if keyword == [] || message == []

		reply_arr = Array.new
		number = keyword.size.to_i
		0.upto(number-1) do |i|
		reply_arr << keyword[i].to_s + "：\n" + message[i].to_s + "\nBy：" + editor[i]
		end
		reply_arr.join("\n\n")
	end
end
def follow(channel_id, received_text)
	received = 	Received.where(channel_id: channel_id).order(:created_at).pluck(:text).to_a
	if received[-1] == received_text && !(Reply.where(channel_id: channel_id).order(:created_at).pluck(:text).to_a[-1] == received[-1])
	return received[-1]
	else
	return nil
	end
end
def wiki(received_text)
	return nil if received_text.nil?
	tag4 = received_text[-4..-1]
	tag3 = received_text[-3..-1]
	tag2 = received_text[-2..-1]
	return unless tag4 =='是什麼?'||tag3 == '是啥?'||tag3 == '是什麼'||tag2 == '是啥'
	index_is = received_text.index('是')
	keyword = received_text[0...index_is]
	return nil if keyword == "那"
	url = 'https://zh.wikipedia.org/w/api.php?action=opensearch&search='+keyword.to_s+'&limit=1&utf8'
	url_encode = URI.encode(url)
	uri = URI(url_encode)
	res = Net::HTTP.get(uri).to_s.force_encoding("UTF-8")

	start_index = res.index('"],["')+5
	end_index = res.index('"],["http')
	url_end_index = res.index('"]]')-1

	return nil if start_index.nil?||end_index.nil?||url_end_index.nil?
	page_url = URI.decode(res[end_index+5..url_end_index].to_s)
	Tradsim::to_trad(res[start_index..end_index-1].to_s.gsub('\"','"')+"\n\n\n"+page_url)
end
	#抽
def draw(received_text)
	return nil if received_text.nil?
	received_text = "抽*1" if received_text == "抽"
	if received_text[0..1] == '抽*'
	number = received_text[2..-1].to_i
	else
	return nil
	end

	return nil if number == 0

	number = 10000 if number > 10000

	times = 0
	ur = 0
	ssr = 0
	sr = 0
	r = 0

	until times == number do

	result = rand(1..100)

	ur += 1 if result == 100
	ssr += 1 if (96..99).include?(result)
	sr += 1 if (81..95).include?(result)
	r += 1 if (1..80).include?(result)
	times += 1
	end

	arr = Array.new
	arr << 'UR：'+ur.to_s unless ur == 0
	arr << 'SSR：'+ssr.to_s unless ssr == 0
	arr << 'SR：'+sr.to_s unless sr == 0
	arr << 'R：'+r.to_s unless r == 0
	arr.join("\n")
end

	#nhentai
def nhentai(received_text)
	return nil if received_text.nil?
	return nil unless received_text[0..7] == 'nhentai=' ||received_text[0..10] == 'nhentai 日期=' ||received_text[0..10] == 'nhentai 中文='
	keyword = nil
	url = nil

	if received_text[0..7] == 'nhentai='
	keyword = received_text[8..-1]
	url = "https://nhentai.net/search/?q="+keyword+'&sort=popular'
	end

	case received_text[0..10]
	when 'nhentai 日期='
	keyword = received_text[11..-1]
	url = "https://nhentai.net/search/?q="+keyword
	when 'nhentai 中文='
	keyword = received_text[11..-1]
	url = "https://nhentai.net/search/?q="+keyword+' language:chinese&sort=popular'
	end

	url_encode = URI.encode(url)
	uri = URI(url_encode)
	res = Net::HTTP.get(uri).to_s

	reply_arr = Array.new
	title_arr = Array.new
	url_arr = Array.new

	title_start_index = (0 ... res.length).find_all { |i| res[i,21] == '<div class="caption">' }
	title_end_index = (0 ... res.length).find_all { |i| res[i,16] == '</div></a></div>' }

	url_start_index = (0 ... res.length).find_all { |i| res[i,12] == '<a href="/g/' }
	url_end_index = (0 ... res.length).find_all { |i| res[i,16] == '/" class="cover"' }

	(0..9).each do |i|
		title_arr << res[title_start_index[i]+21..title_end_index[i]-1] unless title_start_index[i].nil?
		url_arr << res[url_start_index[i]+12..url_end_index[i]-1] unless url_start_index[i].nil?
	end

	(0..9).each do |i|
		reply_arr << title_arr[i] + "\n" + "https://nhentai.net/g/" + url_arr[i] + "\n" unless title_arr[i].nil? ||url_arr[i].nil?
	end

	"搜尋頁面：\n".force_encoding("UTF-8") + url_encode.to_s.force_encoding("UTF-8") + "\n\n" + reply_arr.join("\n").to_s.force_encoding("UTF-8")
end
def upload_to_imgur(event)
	return nil unless event['message']['type'] == 'image'
	return nil unless event['source']['groupId'].nil? && event['source']['roomId'].nil?
	messageId = event['message']['id']
	response = line.get_message_content(messageId)
	tf = response.body.force_encoding("UTF-8")

	 url = URI("https://api.imgur.com/3/image")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["authorization"] = 'Client-ID e0ee93758caf3d2'

    request.set_form_data({"image" => tf, "album" => "fItD7OI9i3KwnQ5"})
    response = http.request(request)

    json = JSON.parse(response.read_body)
    begin
      json['data']['link'].gsub("http:","https:")
    rescue
      nil
    end

end
   #半次元
def bcy(received_text)
	return nil if received_text.nil?
  return nil unless received_text.include?("bcy.net")
	url_encode = URI.encode(received_text)
	uri = URI(url_encode)
	res = Net::HTTP.get(uri).to_s.gsub('\\\\u002F','/').gsub('"','').gsub(']','')

	start_index = res.enum_for(:scan, /original_path\\:\\https:\/\/img-bcy-qn.pstatp.com\/(coser|user|illust|drawer)\/\w*\/(item|post|daily)(\/web)?\/\w*\/\w*.(jpg|png|gif)/).map { Regexp.last_match.begin(0) }

	end_index = res.enum_for(:scan, /\.jpg\\},{?\\/).map { Regexp.last_match.begin(0) }

	arr = Array.new
	(0..30).each do |i|
		arr << res[start_index[i]+16..end_index[i]+3] unless start_index[i].nil?
	end
	arr.join("\n").to_s
end
	#查貼圖ID
def find_sticker(event)
	return nil unless event['source']['groupId'].nil? && event['source']['roomId'].nil?
	return nil unless event['message']['type'] == 'sticker'
	packageId = event['message']['packageId']
	stickerId = event['message']['stickerId']
	'packageId：' + packageId + "\n" + 'stickerId：' + stickerId
end

	#傳送圖片到line
def reply_image_to_line(reply_token)
	return nil if @previewImageUrl.nil? || @originalContentUrl.nil?

	message = {
		type: "image",
		originalContentUrl: @originalContentUrl,
		previewImageUrl: @previewImageUrl
	}

	line.reply_message(reply_token, message)
end
	#傳送信息到line
def reply_to_line(reply_text, reply_token)
	return nil if reply_text.nil?

	#設定回復訊息
	message = {
		type: 'text',
		text: reply_text
	}

	#傳送訊息
	line.reply_message(reply_token, message)
end

	#line Bot API物件初始化
def line
	Line::Bot::Client.new { |config|
		config.channel_secret = 'af5c4adf403c638ac58b091e9f8a42a3'
		config.channel_token = 'CgzCmUYQYCpMBx3s/otuWSi0dBby1OhpguJbXOY/T2SOD87cf0pOqyN4j0z2TELbIFULrzw0ctnVNUuFl47vhqbcuPOzQ2vy6X1RYkGC4zv+V94jMdE02Og9fQkzilUduHHagzkV+C+vghBvG1BRXQdB04t89/1O/w1cDnyilFU=
	'}
end
end
