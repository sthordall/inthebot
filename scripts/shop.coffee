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
          signature = crypto.createHash('sha256')
                            .update(apisecret+token)
                            .digest('hex')
          success(token, signature, clientid)
    
  robot.hear /offers on (.*)/i, (res) ->
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
                response += "#{offer.branding.name} has #{offer.heading} "
                response += "for #{offer.pricing.price},- #{offer.images.zoom}"
                response += "\n"
            res.send response

  robot.hear /offers in (.*) on (.*)/i, (res) ->
    offerShop = res.match[1]
    offerProd = res.match[2]
    robot.http(apiurl + '/dealers/search?' +
      "_token=" + token +
      "&query=" +  offerShop +
      "&limit=" + 3)
      .header('Content-Type', 'application/json')
      .header('Accept', 'application/json')
      .header('Origin', 'localhost')
      .get() (err, resp, body) ->
        if err
          res.send "My shopping assistant is sick :("
        else
          dealers = JSON.parse body
          if dealers.length < 1
            res.send "I didn't find any dealers with the name #{offerShop}"
          else
            dealerQuery = ""
            for dealer in dealers
              do (dealer) ->
                dealerQuery += "#{dealer.id},"
            robot.http(apiurl + "/offers/search?" +
              "_token=" + token +
              "&query=" + offerProd +
              "&dealer_ids=" + dealerQuery)
            .header('Content-Type', 'application/json')
            .header('Accept', 'application/json')
            .header('Origin', 'localhost')
            .get() (err, resp, body) ->
              if err
                res.send "My shopping assistant is sick :("
              else
                offers = JSON.parse body
                response = "I've found #{offers.length} offer(s) in #{offerShop} on #{offerProd}:\n"
                if offers.length < 1
                  res.send "I didn't find any offers on #{offerProd}"
                else
                  for offer in offers
                    do (offer) ->
                      response += "#{offer.heading} for #{offer.pricing.price},- "
                      response += "#{offer.images.zoom}\n"
                  res.send response

