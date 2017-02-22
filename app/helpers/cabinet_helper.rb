module CabinetHelper

	def sec2days(sec)
		time = sec.round
		time /= 60
		time /= 60
		time /= 24
		time+=2
	end

	def panel_gen
    content = ''
    content += image_tag 'teamspeak/16x16_server_green.png'
    content += @info['virtualserver_name']
		content += renderChannels 0
	end

	def renderChannels channelID
			content = ''
			@channel.each do |channel|
				if channel['pid'] == channelID
						name = channel['channel_name'].to_s
						icon = '16x16_channel_green.png'
						if channel['channel_maxclients'] > -1 and channel['total_clients'] >= channel['channel_maxclients']
							icon = '16x16_channel_red.png'
						elsif channel['channel_maxfamilyclients'] > -1 and channel['total_clients_family'] >= channel['channel_maxfamilyclients']
							icon = '16x16_channel_red.png'
						elsif channel['channel_flag_password'] == 1
							icon = '16x16_channel_yellow.png'
						end

						flags = Array.new
						flags << '16x16_default.png' if channel['channel_flag_default'] == 1
						flags << '16x16_moderated.png' if channel['channel_needed_talk_power'] > 0
						flags << '16x16_register.png' if channel['channel_flag_password'] == 1
						flags = renderFlags flags

						users = renderUsers channel['cid'] unless @client.blank?
						childs = renderChannels(channel['cid'])
						cid = channel['cid']



					content += "<div class='tsstatusItem'>"
					content += image_tag "teamspeak/#{icon}"
					content += name
					content += "<div class='tsstatusFlags'>"
					content += flags
					content += "</div> #{users} #{childs} </div>"
				end
			end
			return content
	end

	def renderFlags flags
		content = ''
		flags.each do |flag|
			content += image_tag "teamspeak/#{flag}"
		end
		return content
	end

	def renderUsers channelID
		content=''

    @client.each do |user|
      if user['cid']==channelID
				if user['client_type'] == 0
					name = user['client_nickname']
					icon = '16x16_player_off.png'
					if(user['client_away'] == 1) then icon = '16x16_away.png'
					elsif(user['client_flag_talking'] == 1) then icon = '16x16_player_on.png'
					elsif(user['client_output_hardware'] == 0) then icon = '16x16_hardware_output_muted.png'
					elsif(user['client_output_muted'] == 1) then icon = '16x16_output_muted.png'
					elsif(user['client_input_hardware'] == 0) then icon = '16x16_hardware_input_muted.png'
					elsif(user['client_input_muted'] == 1) then icon = '16x16_input_muted.png'
					end


					content += "<div class='tsstatusItem'>"
					content += image_tag "teamspeak/#{icon}"
					content += name
					content += "</div>"
				end

			end
		end
		return content
	end







end
