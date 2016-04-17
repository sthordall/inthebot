crypto = require('crypto')

apikey = "00in3i9s2f1qngk66j1v5xfkzeh7vywd"
apisecret = "00in3i9s2fjcr1xaurbvtg7znj1fwn6o"
apiurl = "https://api.etilbudsavis.dk/v2"
token = "00in3mypu6orsn3x"

module.exports = (robot) ->
	getToken = (success, err) ->
		credentials = JSON.stringify({ api_key: apikey })
		robot.http(apiurl + "/sessions")
			.header('Content-Type', 'application/json')
			.header('Accept', 'application/json')
			.post(credentials) (err, resp, body) ->
				data = JSON.parse body
				if err
					err "My shopping assistant is on leave"
				else
					token = JSON.stringify(data.token)
					clientid = JSON.stringify(data.client_id)
					signature = crypto.createHash('sha256').update(apisecret+token).digest('hex')
					success(token, signature, clientid)
		
	robot.hear /shop offer (.*)/i, (res) ->
		offerReq = res.match[1]
		robot.http(apiurl + '/offers/search?' +
			"_token=" + token +
			"&query=" + offerReq +
			"&limit=" + 3)
			.header('Content-Type', 'application/json')
			.header('Accept', 'application/json')
			.header('Origin', 'localhost')
			.get() (err, resp, body) ->
				if err
					res.send "My shopping assistant is sick :("
				else
					response = "I've found a couple of offers on #{offerReq}:\n"
					offers = JSON.parse body
					if offers.length < 1
						res.send "I didn't find any offers on #{offerReq}"
					else
						for offer in offers
							do (offer) ->
								response += "\t#{offer.branding.name} has #{offer.heading}"
								response += " for #{offer.pricing.price},- (#{offer.images.zoom})\n"
						res.send response
					
