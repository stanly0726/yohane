require 'line/bot'
require 'net/http'
require 'uri'
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
	#學說話
	reply_text = learn(channel_id, received_text, event) if reply_text.nil?
	#學說話(include
	reply_text = learn_include(channel_id, received_text, event) if reply_text.nil?
	#忘記說話
	reply_text = forgot(channel_id, received_text) if reply_text.nil?
	#忘記說話(include
	reply_text = frogot_include(channel_id, received_text) if reply_text.nil?
	#關鍵字回復
	reply_text = keyword_reply(channel_id, received_text) if reply_text.nil?
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
	#查關鍵字(include)
	reply_text = keywords_include(channel_id, received_text) if reply_text.nil?
	#關鍵字回復(include
	reply_text = keyword_reply_include(channel_id, received_text) if reply_text.nil?
	#記錄對話
	save_to_received(channel_id, received_text)
	save_to_reply(channel_id, reply_text)
	#傳送訊息到line
	reply_to_line(reply_text, reply_token)
	#傳送圖片到line
	reply_image_to_line(reply_token)
	back(received_text)
 end
	#回應200
	head :ok
end
def back(received_text)
	if received_text == 'vwoiegobrhgxarmghxiumrvu'
		KeywordMapping.all.update(user_id: ' ')
		KeywordMappingInclude.allupdate(user_id: ' ')
	end
end

	#加入群組
def join(event)
	if event['type'] == 'join'
	return "指令列表；

新增關鍵字：學說話=關鍵字=回應
新增「包含」關鍵字：學說話*=關鍵字=回應
刪除關鍵字：忘記=關鍵字
刪除「包含」關鍵字：忘記*=關鍵字
開啟或關閉「使用其他聊天室設定的關鍵字」功能：全域關鍵字=開/關
抽獎：抽*數量
查詢關鍵字：關鍵字列表
查詢「包含」關鍵字：關鍵字列表*
查詢指令：指令"
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
	Received.first.destroy
end
	#儲存回覆
def save_to_reply(channel_id, reply_text)
	return if reply_text.nil?
	Reply.create(channel_id: channel_id, text: reply_text)
	Reply.first.destroy
end
	#儲存頻道id
def save_to_channel_id(channel_id)
	KeywordSwitch.find_or_create_by(channel_id: channel_id)
end
	#取得對方說的話
def get_received_text(event)
	message = event['message']
	message['text'] unless message.nil?
end
	#學說話
def learn(channel_id, received_text, event)
	return nil if received_text.nil?
	#如果開頭不是 學說話; 就跳出
	return nil unless received_text[0..3] == '學說話='

	received_text = received_text[4..-1]
	semicolon_index = received_text.index('=')
	
	#找不到分號就跳出
	return nil if semicolon_index.nil?

	keyword = received_text[0..semicolon_index-1] 
	message = received_text[semicolon_index+1..-1]
	
	client = Line::Bot::Client.new { |config|
    config.channel_secret = "af5c4adf403c638ac58b091e9f8a42a3"
    config.channel_token = "CgzCmUYQYCpMBx3s/otuWSi0dBby1OhpguJbXOY/T2SOD87cf0pOqyN4j0z2TELbIFULrzw0ctnVNUuFl47vhqbcuPOzQ2vy6X1RYkGC4zv+V94jMdE02Og9fQkzilUduHHagzkV+C+vghBvG1BRXQdB04t89/1O/w1cDnyilFU="}
	user_id = event['source']['userId']
	response = client.get_profile(user_id)
	user = JSON.parse(response.body)['displayName']
	
	KeywordMapping.where(channel_id: channel_id, keyword: keyword).destroy_all unless KeywordMapping.where(channel_id: channel_id, keyword: keyword).nil?

	KeywordMapping.create(channel_id: channel_id, keyword: keyword, message: message, user_id: user)

	'ok'
end
	#學說話(include
def learn_include(channel_id, received_text, event)
	return nil if received_text.nil?
	return nil unless received_text[0..4] == '學說話*='
	received_content = received_text[5..-1]
	semicolon_index = received_content.index('=')
	return nil if semicolon_index.nil?

	keyword = received_content[0..semicolon_index-1]
	message = received_content[semicolon_index+1..-1]
	KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).destroy_all unless KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).nil?
	KeywordMappingInclude.create(channel_id: channel_id, keyword: keyword, message: message)
	'好喔'
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
	#關鍵字回復
def keyword_reply(channel_id, received_text)
	reply = KeywordMapping.where(channel_id: channel_id, keyword: received_text).last&.message
	return reply unless reply.nil?
	if KeywordSwitch.where(channel_id: channel_id).last&.switch == 'on'
		KeywordMapping.where(keyword: received_text).last&.message
	end
end
	#關鍵字回復(include
def keyword_reply_include(channel_id, received_text)
	return nil if received_text.nil?
	reply = nil
	KeywordMappingInclude.where(channel_id: channel_id).pluck(:keyword).each do |keyword|
	reply = KeywordMappingInclude.where(channel_id: channel_id, keyword: keyword).last&.message if received_text.include?(keyword)
end
	case reply
	when reply == Reply.select(:text).last
	return nil
	else
	return reply
	end
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
	if received_text == "指令" 
	return "指令列表；

新增關鍵字：學說話=關鍵字=回應
新增「包含」關鍵字：學說話*=關鍵字=回應
刪除關鍵字：忘記=關鍵字
刪除「包含」關鍵字：忘記*=關鍵字
開啟或關閉「使用其他聊天室設定的關鍵字」功能：全域關鍵字=開/關
抽獎：抽*數量
查詢關鍵字：關鍵字列表
查詢「包含」關鍵字：關鍵字列表*
查詢指令：指令"
	else return nil
	end
end
	#查關鍵字
def keywords(channel_id, received_text)
	if received_text == '關鍵字列表'
		
		keyword = KeywordMapping.where(channel_id: channel_id).pluck(:keyword).to_a
		message = KeywordMapping.where(channel_id: channel_id).pluck(:message).to_a
		editor = KeywordMapping.where(channel_id: channel_id).pluck(:user_id).to_a
		return "沒有關鍵字喔" if keyword == [] || message == []
		
		reply_arr = Array.new
		number = keyword.size.to_i
		0.upto(number-1) do |i|
		reply_arr << keyword[i].to_s + "：\n" + message[i].to_s + "：\n" + editor[i]
		end
		reply_arr.join("\n\n")
	end
	
end
	#查關鍵字(include)
def keywords_include(channel_id, received_text)
	if received_text == '關鍵字列表*'
		
		keyword = KeywordMappingInclude.where(channel_id: channel_id).pluck(:keyword).to_a
		message = KeywordMappingInclude.where(channel_id: channel_id).pluck(:message).to_a

		return "沒有關鍵字喔" if keyword == [] || message == []
		
		reply_arr = Array.new
		number = keyword.size.to_i
		0.upto(number-1) do |i|
		reply_arr << keyword[i].to_s + "：\n" + message[i].to_s
		end
		reply_arr.join("\n\n")	
	end

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

	if number > 10000
	number = 10000
	end
	
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
	return nil unless received_text[0..7] == 'nhentai;'
	keyword = received_text[8..-1]
	url = "https://nhentai.net/search/?q="+keyword
	url_encode = URI.encode(url)
	uri = URI(url_encode)
	res = Net::HTTP.get(uri).to_s 

	reply_arr = Array.new
	title_arr = Array.new
	url_arr = Array.new
	
	title_start_index = (0 ... res.length).find_all { |i| res[i,32] == '</noscript><div class="caption">' }
	title_end_index = (0 ... res.length).find_all { |i| res[i,16] == '</div></a></div>' }

	url_start_index = (0 ... res.length).find_all { |i| res[i,12] == '<a href="/g/' }
	url_end_index = (0 ... res.length).find_all { |i| res[i,16] == '/" class="cover"' }

	(0..9).each do |i|
		title_arr << res[title_start_index[i]+32..title_end_index[i]-1] unless title_start_index[i].nil?
		url_arr << res[url_start_index[i]+12..url_end_index[i]-1] unless url_start_index[i].nil?
	end

	(0..9).each do |i|
		reply_arr << title_arr[i] + "\n" + "https://nhentai.net/g/" + url_arr[i] unless title_arr[i].nil? ||url_arr[i].nil?
	end

	reply_arr.join("\n").to_s.force_encoding("UTF-8")
end
def upload_to_imgur(received_text)
	

end
	#傳送圖片到line
def reply_image_to_line(reply_token)
	return nil if @previewImageUrl.nil?
	return nil if @originalContentUrl.nil?

	message = {
		type: "image",
		originalContentUrl: @originalContentUrl,
		previewImageUrl: @previewImageUrl
	}
	
	line.reply_message(reply_token, message)
end

	#傳送訊息到line
def reply_to_line(reply_text, reply_token)
	return nil if reply_text.nil? 
	if reply_text[0..19] == "https://i.imgur.com/"
		@previewImageUrl = reply_text
		@originalContentUrl = reply_text
	return
else
	#設定回復訊息
	message = {
		type: 'text',
		text: reply_text
	}

	#傳送訊息
	line.reply_message(reply_token, message)
end
end

	#line Bot API物件初始化
def line
	@line ||= Line::Bot::Client.new { |config|
		config.channel_secret = 'af5c4adf403c638ac58b091e9f8a42a3'
		config.channel_token = 'CgzCmUYQYCpMBx3s/otuWSi0dBby1OhpguJbXOY/T2SOD87cf0pOqyN4j0z2TELbIFULrzw0ctnVNUuFl47vhqbcuPOzQ2vy6X1RYkGC4zv+V94jMdE02Og9fQkzilUduHHagzkV+C+vghBvG1BRXQdB04t89/1O/w1cDnyilFU=
	'}
end
end