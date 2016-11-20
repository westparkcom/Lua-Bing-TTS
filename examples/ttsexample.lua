BingTTS = require "bingtts"
authurl = "https://api.cognitive.microsoft.com/sts/v1.0/issueToken"
client_secret = 'YOURAPIKEYHERE'
tts_bingtts = BingTTS:new()
tts_bingtts:prepare(client_secret, "Test message, you may go away", "en-US", "female", "riff-8khz-8bit-mono-mulaw")
output = tts_bingtts:run()
createFile = assert(io.open('test.wav', 'w'))
createFile:write(output)
createFile:close()
