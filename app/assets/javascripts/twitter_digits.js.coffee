class App.TwitterDigits
  # The oauth token expires in 3600 seconds. We are giving our server atleast 5 minutes to use the token.
  OAUTH_EXPIRY_INTERVAL = 3300

  authenticate: ($form) ->
    $('#digits-sign-up').click ->
      if oauthTimestampAbsentOrExpired($form)
        requireDigitsLogin($form)
      else
        $form.submit()

  requireDigitsLogin = ($form) ->
    Digits.logIn()
      .done (loginResponse) ->
        oAuthHeaders = loginResponse.oauth_echo_headers
        $form = $('.digits-verification')
        authCredentials = oAuthHeaders['X-Verify-Credentials-Authorization']
        $form.find('#digits_credentials').val authCredentials
        $form.find('#digits_service_provider_url').val oAuthHeaders['X-Auth-Service-Provider']
        $form.find('#digits_oauth_timestamp').val authCredentials.match(/oauth_timestamp="(\d+)"/)[1]
        $form.submit()

  oauthTimestampAbsentOrExpired = ($form) ->
    timestamp = $form.find('#digits_oauth_timestamp').val()
    return true if _(timestamp).isEmpty()
    Number(timestamp) + OAUTH_EXPIRY_INTERVAL < currentTimestamp()

  currentTimestamp = ->
    currentDate = new Date()
    currentDate.getTime() / 1000

$(document).on 'page:change', ->
  digits = new App.TwitterDigits()
  digits.authenticate($('.digits-verification'))

  Digits.init
    consumerKey: $("meta[name='digits-consumer-key']").attr('content')
